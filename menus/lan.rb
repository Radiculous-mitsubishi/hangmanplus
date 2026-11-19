require_relative '../lib/lan_lobby'

# LAN connections are available only after local account sign-in.
def open_lan_menu(username)
  loop do
    clear
    draw_header("L A N  P L A Y")
      puts box_line(Color.dim("Signed in as #{username}; casual host-authoritative matches are available."))
    puts box_line(Color.dim("Use only on a trusted local network. No passwords are sent over LAN."))
    puts
    puts box_line("[H] Host a lobby")
    puts box_line("[J] Join a lobby")
    puts box_line("[B] Back")
    print "  Choice: "
    choice = $stdin.gets&.strip&.downcase

    case choice
    when 'h' then host_lan_lobby(username)
    when 'j' then join_lan_lobby(username)
    when 'b', nil then return
    else
      puts Color.red("  Choose H, J, or B.")
      sleep 0.8
    end
  end
end

def host_lan_lobby(username)
  print "  Port [#{LAN_DEFAULT_PORT}]: "
  port_input = $stdin.gets&.strip
  port = port_input.to_s.empty? ? LAN_DEFAULT_PORT : Integer(port_input, 10)
  raise ArgumentError, 'Port must be from 1024 to 65535.' unless (1024..65_535).cover?(port)

  server = LanLobbyServer.new(username, port: port)
  host_socket = nil
  begin
    host_socket = TCPSocket.new('127.0.0.1', server.port)
    lan_send_request(host_socket, type: 'host_join', token: server.host_token)
    loop do
      clear
      draw_header("L A N  L O B B Y  (H O S T)")
      puts box_line(Color.yellow("Share the address on your shared network, port #{server.port}:"))
      puts box_line(Color.dim("Try the Wi-Fi adapter first; ignore VPN/virtual adapter addresses."))
      interfaces = lan_local_ipv4_interfaces
      if interfaces.empty?
        puts box_line(Color.red("No local IPv4 adapters were detected."))
      else
        interfaces.each do |interface|
          address = Color.cyan(interface[:address])
          note = interface[:private] ? "" : Color.dim(" (not a private LAN address)")
          adapter = interface[:wireless] ? Color.green("[Wi-Fi]") : Color.dim("[other]")
          puts box_line("#{adapter} #{interface[:name]}: #{address}#{note}")
        end
      end
      puts box_line(Color.dim("Your local account is the host player; passwords stay local."))
      puts box_line(Color.dim("Match rules: one separate word per player, 30 seconds, six misses."))
      puts box_line(Color.dim("Listener: 0.0.0.0:#{server.port} (all IPv4 adapters)"))
      puts
      display_lan_players(server.players)
      puts box_line(Color.dim("TCP connection attempts seen: #{server.connection_attempts}"))
      puts
      puts box_line("[S] Start match (2+ players)  [Enter] Refresh  [Q] Close lobby")
      print "  Lobby: "
      choice = $stdin.gets&.strip&.downcase
      break if choice == 'q' || choice.nil?
      if choice == 's'
        begin
          response = lan_send_request(host_socket, type: 'start')
          run_lan_match_client(host_socket, username, response)
          break
        rescue IOError => error
          puts Color.red("  Could not start match: #{error.message}")
          sleep 1.5
        end
      end
    end
  ensure
    host_socket.close if host_socket && !host_socket.closed?
    server.stop
  end
rescue ArgumentError, IOError, SystemCallError => error
  puts Color.red("  Could not host lobby: #{error.message}")
  puts Color.dim("  Check whether another program is already using that port.")
  puts Color.dim("  Press Enter to continue...")
  $stdin.gets
end

def join_lan_lobby(username)
  print "  Host IP address: "
  address = $stdin.gets&.strip
  return if address.nil? || address.empty?

  print "  Port [#{LAN_DEFAULT_PORT}]: "
  port_input = $stdin.gets&.strip
  port = port_input.to_s.empty? ? LAN_DEFAULT_PORT : Integer(port_input, 10)
  raise ArgumentError, 'Port must be from 1 to 65535.' unless (1..65_535).cover?(port)

  socket = Timeout.timeout(5) { TCPSocket.new(address, port) }
  response = lan_send_request(socket, type: 'join', username: username)
  raise IOError, response['message'] if response['type'] == 'error'

  run_lan_match_client(socket, username, response)
rescue ArgumentError, IOError, SystemCallError, Timeout::Error => error
  puts Color.red("  Could not join lobby: #{error.message}")
  puts Color.dim(lan_connection_hint(error))
  puts Color.dim("  Press Enter to continue...")
  $stdin.gets
ensure
  if socket && !socket.closed?
    lan_send_request(socket, type: 'leave') rescue nil
    socket.close
  end
end

def run_lan_match_client(socket, username, initial_response = nil)
  response = initial_response

  loop do
    response ||= lan_send_request(socket, type: 'state')
    if response['type'] == 'match_state'
      run_lan_match_screen(socket, response)
      return
    end

    clear
    draw_header("L A N  L O B B Y")
    puts box_line(Color.dim("Connected as #{username}. Waiting for the host to start."))
    puts box_line(Color.dim("Match rules: one separate word per player, 30 seconds, six misses."))
    puts
    display_lan_players(response['players'] || [])
    puts
    puts box_line("Press Q to leave; lobby refreshes automatically.")
    choice = $stdin.getch(min: 0, time: 0.75, intr: true)&.downcase
    return if choice == 'q'
    response = nil
  end
end

def run_lan_match_screen(socket, snapshot)
  loop do
    if snapshot['phase'] == 'finished'
      clear
      draw_header("L A N  M A T C H  R E S U L T S")
      puts box_line(Color.bold(Color.yellow("Final standings")))
      display_lan_standings(snapshot['standings'] || [])
      puts
      puts box_line("Press any key to return to the lobby")
      $stdin.getch
      return
    end

    draw_lan_match_screen(snapshot)
    key = $stdin.getch(min: 0, time: 0.5, intr: true)&.downcase
    if key == 'q'
      lan_send_request(socket, type: 'leave') rescue nil
      return
    elsif key && key.match?(/\A[a-z]\z/) && snapshot.dig('player', 'status') == 'playing'
      snapshot = lan_send_request(socket, type: 'guess', letter: key)
    else
      snapshot = lan_send_request(socket, type: 'state')
    end
  end
end

def draw_lan_match_screen(snapshot)
  player = snapshot.fetch('player')
  word = player.fetch('word')
  guessed = player.fetch('guessed')
  status = player.fetch('status')
  clear
  draw_header("L A N  C A S U A L  M A T C H")
    puts box_line(Color.dim("Casual one-round race: each player gets a separate word; host validates guesses and scores."))
  puts box_line("Time left: #{Color.bold(Color.yellow("#{snapshot['seconds_left']}s"))}  Score: #{Color.cyan(player['score'])}")
  puts box_line("Misses: #{player['wrong']}/#{BASE_MAX_WRONG}  Status: #{player['status']}")
  masked = word.chars.map { |char| guessed.include?(char) ? Color.bold(Color.green(" #{char.upcase} ")) : Color.dim(" _ ") }.join
  puts box_line(masked)
  puts box_line("Guessed: #{(guessed || []).map(&:upcase).join(' ')}")
  puts
  display_lan_standings(snapshot['standings'] || [])
  puts
  if status == 'playing'
    print "  Guess a letter (Q to leave): "
  else
    puts box_line(Color.yellow("Your round is complete; waiting for the others... Press Q to leave."))
  end
end

def display_lan_standings(standings)
  puts Color.bold(Color.white("  Standings:"))
  standings.each_with_index do |player, index|
    puts box_line("#{index + 1}. #{player['username']} — #{player['score']} pts [#{player['status']}]")
  end
end

def lan_connection_hint(error)
  case error
  when Errno::ECONNREFUSED
    "  The host was reachable but nothing accepted that port. Confirm Host is still in the lobby and the port matches."
  when Errno::ETIMEDOUT, Timeout::Error
    "  No reply arrived. Check the Wi-Fi/Ethernet address, same subnet, guest Wi-Fi/AP isolation, and firewall profiles."
  when Errno::EHOSTUNREACH, Errno::ENETUNREACH
    "  The host network is unreachable. Confirm both devices are on the same non-guest LAN/VLAN."
  when SocketError
    "  The address could not be resolved. Enter the host's numeric local IPv4 address, not its public IP."
  else
    "  Verify the host address and port, same subnet, guest Wi-Fi/AP isolation, and firewall profiles."
  end
end

def display_lan_players(players)
  if players.empty?
    puts box_line(Color.dim("No players are currently connected."))
    return
  end

  puts Color.bold(Color.white("  Players (#{players.length}):"))
  players.each_with_index do |player, index|
    role = player['host'] || player[:host] ? Color.yellow(" [HOST]") : ""
    name = player['username'] || player[:username]
    puts box_line("#{index + 1}. #{Color.bold(name.to_s)}#{role}")
  end
end
