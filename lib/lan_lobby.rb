require 'json'
require 'socket'
require 'timeout'

LAN_DEFAULT_PORT = 45_678
LAN_MAX_MESSAGE_BYTES = 1_024
LAN_MAX_PLAYERS = 8
LAN_USERNAME_PATTERN = /\A[a-zA-Z0-9_]{3,20}\z/

class LanLobbyServer
  def initialize(host_username, port: LAN_DEFAULT_PORT)
    @host_username = host_username
    @server = TCPServer.new('0.0.0.0', port)
    @port = @server.addr[1]
    @mutex = Mutex.new
    @players = [{ username: host_username, host: true }]
    @clients = []
    @client_threads = []
    @stopping = false
    @accept_thread = Thread.new { accept_clients }
  end

  attr_reader :port, :host_username

  def players
    @mutex.synchronize { @players.map(&:dup) }
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
    while (line = socket.gets(LAN_MAX_MESSAGE_BYTES + 1))
      if line.bytesize > LAN_MAX_MESSAGE_BYTES || !line.end_with?("\n")
        send_response(socket, type: 'error', message: 'Request is too large.')
        break
      end

      request = JSON.parse(line)
      case request['type']
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
          if @players.any? { |player| player[:username].casecmp?(player_name) }
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
        elsif result == :full
          send_response(socket, type: 'error', message: 'This prototype lobby is full (maximum 8 players).')
          player_name = nil
          next
        end
        send_lobby(socket)
      when 'list'
        send_lobby(socket) if player_name
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
      @mutex.synchronize { @players.reject! { |player| player[:username].casecmp?(player_name) } }
    end
    @mutex.synchronize { @clients.delete(socket) }
    socket.close unless socket.closed?
  end

  def send_lobby(socket)
    send_response(socket, type: 'lobby', players: players)
  end

  def send_response(socket, response = nil, **fields)
    response ||= fields
    socket.write(JSON.generate(response) + "\n")
  end
end

def lan_local_ipv4_addresses
  addresses = Socket.getifaddrs.each_with_object([]) do |interface, found|
    address = interface.addr
    found << address.ip_address if address && address.ipv4? && !address.ipv4_loopback?
  end.uniq
  addresses.empty? ? ['not detected; check this computer\'s LAN IP'] : addresses
rescue NoMethodError, SocketError
  ['not detected; check this computer\'s LAN IP']
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
