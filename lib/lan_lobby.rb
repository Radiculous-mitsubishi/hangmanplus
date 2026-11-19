require 'json'
require 'openssl'
require 'socket'
require 'timeout'
require 'ipaddr'
require 'securerandom'

LAN_DEFAULT_PORT = 45_678
LAN_MAX_MESSAGE_BYTES = 1_024
LAN_MAX_PLAYERS = 8
LAN_USERNAME_PATTERN = /\A[a-zA-Z0-9_]{3,20}\z/

class LanLobbyServer
  def initialize(host_username, port: LAN_DEFAULT_PORT)
    @host_username = host_username
    @host_token = SecureRandom.hex(24)
    @server = TCPServer.new('0.0.0.0', port)
    @port = @server.addr[1]
    @mutex = Mutex.new
    @players = [{ username: host_username, host: true }]
    @clients = []
    @client_threads = []
    @connection_attempts = 0
    @host_connected = false
    @phase = :lobby
    @match_players = {}
    @match_deadline = nil
    @stopping = false
    @accept_thread = Thread.new { accept_clients }
  end

  attr_reader :port, :host_username, :host_token

  def connection_attempts
    @mutex.synchronize { @connection_attempts }
  end

  def players
    @mutex.synchronize { @players.map(&:dup) }
  end

  def phase
    @mutex.synchronize { update_match_locked; @phase }
  end

  def stop
    @mutex.synchronize { @stopping = true }
    @server.close unless @server.closed?
    clients = @mutex.synchronize { @clients.dup }
    clients.each { |client| client.close unless client.closed? }
    @accept_thread.join(1)
    @client_threads.each { |thread| thread.join(0.2) }
  rescue IOError, SystemCallError
    nil
  end

  private

  def accept_clients
    loop do
      client = @server.accept
      accepted = @mutex.synchronize do
        @connection_attempts += 1
        if @clients.length >= LAN_MAX_PLAYERS * 2
          false
        else
          @clients << client
          true
        end
      end
      unless accepted
        client.close
        next
      end
      thread = Thread.new(client) { |socket| handle_client(socket) }
      @client_threads << thread
    end
  rescue IOError, Errno::EBADF
    raise unless @mutex.synchronize { @stopping }
  end

  def handle_client(socket)
    player_name = nil
    host_client = false
    while (line = socket.gets(LAN_MAX_MESSAGE_BYTES + 1))
      if line.bytesize > LAN_MAX_MESSAGE_BYTES || !line.end_with?("\n")
        send_response(socket, type: 'error', message: 'Request is too large.')
        break
      end

      request = JSON.parse(line)
      case request['type']
      when 'host_join'
        token = request['token'].to_s
        valid_token = token.bytesize == @host_token.bytesize &&
                      OpenSSL.fixed_length_secure_compare(token, @host_token)
        unless valid_token && socket.peeraddr[3] == '127.0.0.1'
          send_response(socket, type: 'error', message: 'Host control authentication failed.')
          break
        end
        joined = @mutex.synchronize do
          next false if @host_connected

          @host_connected = true
          true
        end
        unless joined
          send_response(socket, type: 'error', message: 'Host is already connected to the lobby.')
          break
        end
        player_name = @host_username
        host_client = true
        send_lobby(socket)
      when 'join'
        unless player_name.nil?
          send_response(socket, type: 'error', message: 'Already joined this lobby.')
          next
        end
        player_name = request['username'].to_s
        unless player_name.match?(LAN_USERNAME_PATTERN)
          send_response(socket, type: 'error', message: 'Invalid username.')
          player_name = nil
          next
        end
        result = @mutex.synchronize do
          if @phase != :lobby
            :started
          elsif @players.any? { |player| player[:username].casecmp?(player_name) }
            :duplicate
          elsif @players.length >= LAN_MAX_PLAYERS
            :full
          else
            @players << { username: player_name, host: false }
            :joined
          end
        end
        if result == :duplicate
          send_response(socket, type: 'error', message: 'That username is already in this lobby.')
          player_name = nil
          next
        elsif result == :started
          send_response(socket, type: 'error', message: 'The match has already started; join the next lobby.')
          player_name = nil
          next
        elsif result == :full
          send_response(socket, type: 'error', message: 'This prototype lobby is full (maximum 8 players).')
          player_name = nil
          next
        end
        send_lobby(socket)
      when 'list'
        send_lobby(socket) if player_name
      when 'start'
        if host_client
          started, message = @mutex.synchronize { start_match_locked }
          if started
            send_response(socket, match_snapshot_locked(player_name))
          else
            send_response(socket, type: 'error', message: message)
          end
        else
          send_response(socket, type: 'error', message: 'Only the host can start a match.')
        end
      when 'state'
        if player_name
          response = @mutex.synchronize do
            update_match_locked
            @phase == :lobby ? lobby_snapshot_locked : match_snapshot_locked(player_name)
          end
          send_response(socket, **response)
        end
      when 'guess'
        if player_name
          response = @mutex.synchronize { submit_guess_locked(player_name, request['letter']) }
          send_response(socket, **response)
        end
      when 'leave'
        send_response(socket, type: 'left')
        break
      else
        send_response(socket, type: 'error', message: 'Unknown request.')
      end
    end
  rescue JSON::ParserError
    send_response(socket, type: 'error', message: 'Invalid request.') rescue nil
  rescue IOError, SystemCallError
    nil
  ensure
    if player_name
      @mutex.synchronize do
        if host_client
          @host_connected = false
        else
          @players.reject! { |player| player[:username].casecmp?(player_name) }
          if @phase == :lobby
            @match_players.delete(player_name)
          elsif @match_players[player_name] && @match_players[player_name][:status] == 'playing'
            @match_players[player_name][:status] = 'left'
          end
        end
        update_match_locked
      end
    end
    @mutex.synchronize { @clients.delete(socket) }
    socket.close unless socket.closed?
  end

  def send_lobby(socket)
    snapshot = @mutex.synchronize { lobby_snapshot_locked }
    send_response(socket, **snapshot)
  end

  def lobby_snapshot_locked
    { type: 'lobby', phase: @phase.to_s, players: @players.map(&:dup) }
  end

  def start_match_locked
    return [false, 'A match is already in progress.'] unless @phase == :lobby
    return [false, 'At least two players must join before starting.'] if @players.length < 2

    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @match_deadline = now + 30
    @match_players = @players.each_with_object({}) do |player, match|
      match[player[:username]] = {
        word: CATEGORIES.values.flatten.sample.downcase,
        guessed: [],
        wrong: 0,
        score: 0,
        status: 'playing'
      }
    end
    @phase = :playing
    [true, nil]
  end

  def submit_guess_locked(username, raw_letter)
    update_match_locked
    return { type: 'error', message: 'No match is currently in progress.' } unless @phase == :playing

    player = @match_players[username]
    return { type: 'error', message: 'Player is not part of this match.' } unless player
    return match_snapshot_locked(username) unless player[:status] == 'playing'

    letter = raw_letter.to_s.downcase
    return { type: 'error', message: 'Guess must be one letter from A to Z.' } unless letter.match?(/\A[a-z]\z/)
    return match_snapshot_locked(username) if player[:guessed].include?(letter)

    player[:guessed] << letter
    if player[:word].include?(letter)
      player[:score] += 1
      if player[:word].chars.uniq.all? { |char| player[:guessed].include?(char) }
        player[:status] = 'won'
      end
    else
      player[:wrong] += 1
      player[:status] = 'out' if player[:wrong] >= BASE_MAX_WRONG
    end
    update_match_locked
    match_snapshot_locked(username)
  end

  def update_match_locked
    return unless @phase == :playing

    if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= @match_deadline
      @match_players.each_value { |player| player[:status] = 'time' if player[:status] == 'playing' }
    end
    @phase = :finished if @match_players.values.all? { |player| player[:status] != 'playing' }
  end

  def match_snapshot_locked(username)
    update_match_locked
    own = @match_players[username]
    return { type: 'error', message: 'No match state is available for this player.' } unless own

    standings = @match_players.map do |name, player|
      { username: name, score: player[:score], status: player[:status] }
    end.sort_by { |player| [-player[:score], player[:username].downcase] }
    {
      type: 'match_state',
      phase: @phase.to_s,
      seconds_left: [(@match_deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)).ceil, 0].max,
      player: {
        word: own[:word], guessed: own[:guessed].dup, wrong: own[:wrong],
        score: own[:score], status: own[:status]
      },
      standings: standings
    }
  end

  def send_response(socket, response = nil, **fields)
    response ||= fields
    socket.write(JSON.generate(response) + "\n")
  end
end

def lan_local_ipv4_interfaces
  Socket.getifaddrs.each_with_object([]) do |interface, found|
    address = interface.addr
    next unless address && address.ipv4? && !address.ipv4_loopback?

    ip = address.ip_address
    ip_address = IPAddr.new(ip)
    next if ip.start_with?('169.254.')

    wireless = interface.name.match?(/wireless|wi-?fi|wlan|802\.11/i)
    found << { name: interface.name, address: ip, private: ip_address.private?, wireless: wireless }
  end.uniq { |interface| [interface[:name], interface[:address]] }
    .sort_by { |interface| [interface[:wireless] ? 0 : 1, interface[:name], interface[:address]] }
rescue NoMethodError, SocketError
  []
end

def lan_local_ipv4_addresses
  addresses = lan_local_ipv4_interfaces.map { |interface| interface[:address] }
  addresses.empty? ? ['not detected; check this computer\'s LAN IP'] : addresses
end

def lan_send_request(socket, request = nil, **fields)
  request ||= fields
  socket.write(JSON.generate(request) + "\n")
  line = socket.gets(LAN_MAX_MESSAGE_BYTES + 1)
  raise IOError, 'The host disconnected.' unless line
  raise IOError, 'Invalid response from the host.' if line.bytesize > LAN_MAX_MESSAGE_BYTES || !line.end_with?("\n")

  response = JSON.parse(line)
  raise IOError, response['message'] if response['type'] == 'error'

  response
end
