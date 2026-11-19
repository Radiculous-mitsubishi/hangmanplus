require_relative '../lib/lan_lobby'

# LAN connections are available only after local account sign-in.
def open_lan_menu(username)
  loop do
    clear
    draw_header("L A N  P L A Y")
    puts box_line(Color.dim("Signed in as #{username}; ranked-style LAN matches are available."))
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
    return if response == :leave
    response ||= lan_send_request(socket, type: 'state')
    case response['phase']
    when 'lobby'
      clear
      draw_header("L A N  R A N K E D  L O B B Y")
      puts box_line(Color.dim("Connected as #{username}; waiting for the host to start."))
      display_lan_players(response['players'] || [])
      puts box_line("Press Q to leave; lobby refreshes automatically.")
      if $stdin.getch(min: 0, time: 0.5, intr: true)&.downcase == 'q'
        lan_send_request(socket, type: 'leave') rescue nil
        return :leave
      end
      response = nil
    when 'rules'
      response = run_ranked_rules_screen(socket, response)
    when 'countdown'
      response = run_ranked_countdown_screen(socket, response)
    when 'playing'
      response = run_ranked_round_screen(socket, response)
    when 'round_results'
      response = run_ranked_round_results_screen(socket, response)
    when 'shop'
      response = run_ranked_shop_screen(socket, response)
    when 'finished'
      run_ranked_final_results(response)
      return
    else
      response = lan_send_request(socket, type: 'state')
    end
  end
end

def run_ranked_rules_screen(socket, snapshot)
  loop do
    clear
    draw_header("R A N K E D  R U L E S")
    puts box_line(Color.bold(Color.yellow("Read the rules before the match begins.")))
    puts box_line("35 rounds; one shared word and category for everyone each round.")
    puts box_line("30 seconds per round; six misses. Category is hidden after round 15.")
    puts box_line("After rounds 5, 10, 15, 20, 25 and 30: shop for items and skill cards.")
    puts box_line("Each shop grants one skill template. Items cost points; cards cost templates.")
    puts box_line("Final winner is the player with most earned points; winner receives other players' unspent shop points.")
    puts box_line("Skip votes: #{snapshot['skip_votes']}/#{snapshot['skip_votes_needed']} required; #{snapshot['rules_seconds']} seconds remain.")
    puts box_line("Press V to vote to skip rules, or wait for the 30-second timer.")
    puts Color.dim("  This is a local casual match; host-run scores are not globally verified.")

    key = $stdin.getch(min: 0, time: 0.5, intr: true)&.downcase
    if key == 'q'
      lan_send_request(socket, type: 'leave') rescue nil
      return :leave
    elsif key == 'v'
      snapshot = lan_send_request(socket, type: 'skip_vote')
    else
      snapshot = lan_send_request(socket, type: 'state')
    end
    return snapshot unless snapshot['phase'] == 'rules'
  end
end

def run_ranked_countdown_screen(socket, snapshot)
  while snapshot['phase'] == 'countdown'
    clear
    draw_header("G E T  R E A D Y")
    puts box_line(Color.bold(Color.yellow("Round #{snapshot['round'].to_i + 1} begins in #{snapshot['countdown_seconds']}...")))
    snapshot = lan_send_request(socket, type: 'state')
    sleep 0.2
  end
  snapshot
end

def run_ranked_round_screen(socket, snapshot)
  loop do
    draw_ranked_match_screen(snapshot)
    player = snapshot.fetch('player')
    key = $stdin.getch(min: 0, time: 0.4, intr: true)&.downcase
    if key == 'q'
      lan_send_request(socket, type: 'leave') rescue nil
      return :leave
    elsif key == '+' && player['status'] == 'playing'
      snapshot = prompt_ranked_item_use(socket, player)
    elsif key && key.match?(/\A[a-z]\z/) && player['status'] == 'playing'
      snapshot = lan_send_request(socket, type: 'guess', letter: key)
    else
      snapshot = lan_send_request(socket, type: 'state')
    end
    return snapshot unless snapshot['phase'] == 'playing'
  end
end

def draw_ranked_match_screen(snapshot)
  player = snapshot.fetch('player')
  clear
  draw_header("R A N K E D  R O U N D  #{snapshot['round']}/#{snapshot['total_rounds']}")
  puts box_line("Time: #{Color.bold(Color.yellow("#{snapshot['seconds_left']}s"))}  Points: #{Color.cyan(player['score'])}  Shop wallet: #{player['wallet']}")
  puts box_line("Category: #{snapshot['category'] || Color.dim('[Hidden]')}")
  puts box_line("Misses: #{player['wrong']}/#{player['max_misses']}  Status: #{player['status']}")
  shown = player['display'].to_s.split.map { |char| char == '_' ? Color.dim(' _ ') : Color.bold(Color.green(" #{char.upcase} ")) }.join
  puts box_line(shown)
  puts box_line("Guessed: #{(player['guessed'] || []).map(&:upcase).join(' ')}")
  puts box_line("Items [ + ]: #{format_ranked_inventory(player['inventory'], player['free_reveals'])}")
  puts
  display_ranked_standings(snapshot['standings'] || [])
  puts
  if player['status'] == 'playing'
    print "  Guess a letter ( + items, Q leave ): "
  else
    puts box_line(Color.yellow("Round complete; waiting for the other players... Q leaves."))
  end
end

def run_ranked_round_results_screen(socket, snapshot)
  while snapshot['phase'] == 'round_results'
    clear
    draw_header("R O U N D  #{snapshot['round']}  R E S U L T S")
    player = snapshot['player']
    puts box_line("Your answer: #{Color.bold(Color.green(player['word'].to_s.upcase))}  |  Status: #{player['status']}")
    puts box_line("Points: #{player['score']}  |  Shop wallet: #{player['wallet']}")
    display_ranked_standings(snapshot['standings'] || [])
    puts box_line("Next round/shop begins shortly. Q leaves the match.")
    if $stdin.getch(min: 0, time: 0.5, intr: true)&.downcase == 'q'
      lan_send_request(socket, type: 'leave') rescue nil
      return :leave
    end
    snapshot = lan_send_request(socket, type: 'state')
  end
  snapshot
end

def run_ranked_shop_screen(socket, snapshot)
  loop do
    player = snapshot.fetch('player')
    shop = snapshot.fetch('shop')
    clear
    draw_header("R A N K E D  S H O P  —  A F T E R  R O U N D  #{snapshot['round']}")
    puts box_line("Skill templates: #{Color.magenta(shop['templates'])}  |  Match points available: #{Color.yellow(shop['wallet'])}")
    puts Color.bold(Color.white("  Skill cards (buy with templates):"))
    shop['offers'].each_with_index do |card, index|
      locked = shop['locked_card'] == card['key'] ? Color.cyan(' [LOCKED THIS SHOP]') : ''
      owned = player['cards'].any? { |owned_card| owned_card['key'] == card['key'] } ? Color.dim(' [OWNED]') : ''
      puts box_line("[#{index + 1}] #{card['name']} (#{card['rarity']}, #{card['cost']} templates)#{locked}#{owned}")
      puts box_line("    #{Color.dim(card['description'])}")
    end
    puts Color.bold(Color.white("  Items (buy with points):"))
    shop['items'].each_with_index do |item, index|
      puts box_line("[I#{index + 1}] #{item['name']} — #{item['cost']} pts")
    end
    queued_lock = shop['next_locked_card'] || 'none'
    puts box_line("Next-shop lock: #{queued_lock}  |  [L#] set lock  [U] clear lock  [R] ready  [Q] leave")
    if shop['ready']
      puts box_line(Color.yellow("You're ready; waiting for the rest of the lobby..."))
      key = $stdin.getch(min: 0, time: 0.5, intr: true)&.downcase
      if key == 'q'
        lan_send_request(socket, type: 'leave') rescue nil
        return :leave
      end
      snapshot = lan_send_request(socket, type: 'state')
      return snapshot unless snapshot['phase'] == 'shop'
      next
    end

    print "  Shop action: "
    action = $stdin.gets&.strip&.downcase
    if action.nil? || action == 'q'
      lan_send_request(socket, type: 'leave') rescue nil
      return :leave
    end
    if action.match?(/\A[1-9]\d*\z/)
      card = shop['offers'][action.to_i - 1]
      snapshot = card ? lan_send_request(socket, type: 'shop', action: 'buy_card', card: card['key']) : snapshot
    elsif action.match?(/\Ai\d+\z/)
      item = shop['items'][action[1..-1].to_i - 1]
      snapshot = item ? lan_send_request(socket, type: 'shop', action: 'buy_item', item: item['id']) : snapshot
    elsif action.match?(/\Al\d+\z/)
      card = shop['offers'][action[1..-1].to_i - 1]
      snapshot = card ? lan_send_request(socket, type: 'shop', action: 'lock_card', card: card['key']) : snapshot
    elsif action == 'u'
      snapshot = lan_send_request(socket, type: 'shop', action: 'unlock_card')
    elsif action == 'r'
      snapshot = lan_send_request(socket, type: 'shop', action: 'ready')
    end
    return snapshot unless snapshot['phase'] == 'shop'
  end
end

def prompt_ranked_item_use(socket, player)
  inventory = player['inventory'] || {}
  items = [
    ['1', 'reveal_letter', 'Reveal a Letter'],
    ['2', 'extra_life', 'Extra Life'],
    ['3', 'double_down', 'Double Down'],
    ['4', 'safety_net', 'Safety Net']
  ].select do |_key, id, _label|
    inventory.fetch(id, 0).to_i.positive? || (id == 'reveal_letter' && player['free_reveals'].to_i.positive?)
  end
  return lan_send_request(socket, type: 'state') if items.empty?

  puts "\n  Items: #{items.map { |key, id, label| "[#{key}] #{label} x#{inventory[id]}" }.join('  ')}"
  print "  Use item (or Enter to cancel): "
  choice = $stdin.gets&.strip
  selected = items.find { |key, _id, _label| key == choice }
  selected ? lan_send_request(socket, type: 'use_item', item: selected[1]) : lan_send_request(socket, type: 'state')
end

def run_ranked_final_results(snapshot)
  clear
  draw_header("R A N K E D  M A T C H  F I N A L")
  if snapshot['winner']
    puts box_line(Color.bold(Color.yellow("Winner: #{snapshot['winner']}")))
    puts box_line("Transferred #{snapshot['transferred_points']} unspent points into the winner's match wallet.")
  else
    puts box_line(Color.bold(Color.yellow("The match ended in a tie; no point transfer.")))
  end
  display_ranked_standings(snapshot['standings'] || [])
  puts box_line(Color.dim("Ranked results are session-only in this LAN prototype."))
  puts box_line("Press any key to return to the lobby")
  $stdin.getch
end

def format_ranked_inventory(inventory, free_reveals = 0)
  labels = { 'reveal_letter' => 'Reveal', 'extra_life' => 'Extra Life', 'double_down' => 'Double Down', 'safety_net' => 'Safety Net' }
  parts = labels.map do |id, label|
    count = inventory.fetch(id, 0).to_i
    "#{label} x#{count}" if count.positive?
  end.compact
  free_reveals = free_reveals.to_i
  parts << "Keen Eye Reveal x#{free_reveals}" if free_reveals.positive?
  parts.empty? ? 'none' : parts.join(', ')
end

def display_ranked_standings(standings)
  puts Color.bold(Color.white("  Standings:"))
  standings.each_with_index do |player, index|
    points = player['points'] || player['score'] || 0
    puts box_line("#{index + 1}. #{player['username']} — #{points} pts [#{player['status']}]")
  end
end

alias display_lan_standings display_ranked_standings

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
