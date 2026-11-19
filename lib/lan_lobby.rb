require 'json'
require 'openssl'
require 'socket'
require 'timeout'
require 'ipaddr'
require 'securerandom'

LAN_DEFAULT_PORT = 45_678
LAN_MAX_MESSAGE_BYTES = 16_384
LAN_MAX_PLAYERS = 8
LAN_USERNAME_PATTERN = /\A[a-zA-Z0-9_]{3,20}\z/
LAN_RULES_SECONDS = 30
LAN_COUNTDOWN_SECONDS = 5
LAN_ROUNDS_PER_SHOP = 5
LAN_MATCH_ROUNDS = 35
LAN_ROUND_SECONDS = 30
LAN_MAX_MISSES = 6
LAN_CARD_TEMPLATE_COSTS = {
  common: 1,
  rare: 2,
  ultra_rare: 3,
  legendary: 4,
  mythic: 5
}.freeze

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
    @round_number = 0
    @shared_word = nil
    @shared_category = nil
    @skip_votes = {}
    @round_results_deadline = nil
    @countdown_deadline = nil
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
            response = @mutex.synchronize { match_snapshot_locked(player_name) }
            send_response(socket, response)
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
          send_response(socket, response)
        end
      when 'guess'
        if player_name
          response = @mutex.synchronize { submit_guess_locked(player_name, request['letter']) }
          send_response(socket, response)
        end
      when 'skip_vote'
        response = @mutex.synchronize { vote_to_skip_rules_locked(player_name) }
        send_response(socket, response)
      when 'shop'
        response = @mutex.synchronize { handle_shop_action_locked(player_name, request) }
        send_response(socket, response)
      when 'use_item'
        response = @mutex.synchronize { use_match_item_locked(player_name, request['item']) }
        send_response(socket, response)
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
          @skip_votes.delete(player_name)
          if @phase == :lobby
            @match_players.delete(player_name)
          elsif @match_players[player_name]
            @match_players[player_name][:status] = 'left'
            @match_players[player_name][:shop_ready] = true
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
    @rules_deadline = now + LAN_RULES_SECONDS
    @skip_votes = {}
    @match_players = {}
    @players.each do |player|
      @match_players[player[:username]] = {
        points: 0,
        wallet: 0,
        templates: 0,
        cards: [],
        locked_card: nil,
        offers: [],
        inventory: {},
        shop_ready: false,
        status: 'waiting'
      }
    end
    @phase = :rules
    [true, nil]
  end

  def vote_to_skip_rules_locked(username)
    update_match_locked
    return { type: 'error', message: 'Rules voting is not currently open.' } unless @phase == :rules
    return { type: 'error', message: 'Player is not part of this match.' } unless @match_players.key?(username)

    @skip_votes[username] = true
    update_match_locked
    match_snapshot_locked(username)
  end

  def submit_guess_locked(username, raw_letter)
    update_match_locked
    player = @match_players[username]
    return { type: 'error', message: 'Player is not part of this match.' } unless player
    return match_snapshot_locked(username) unless @phase == :playing && player[:status] == 'playing'

    letter = raw_letter.to_s.downcase
    return { type: 'error', message: 'Guess must be one letter from A to Z.' } unless letter.match?(/\A[a-z]\z/)
    return match_snapshot_locked(username) if player[:guessed].include?(letter)

    if player[:auto_win_ready]
      player[:auto_win_ready] = false
      @shared_word.chars.uniq.each do |char|
        next if player[:guessed].include?(char)

        player[:guessed] << char
        award_ranked_correct_letter_locked(player)
      end
      complete_ranked_win_locked(player)
      update_match_locked
      return match_snapshot_locked(username)
    end

    player[:guessed] << letter
    if @shared_word.include?(letter)
      award_ranked_correct_letter_locked(player)
      if @shared_word.chars.uniq.all? { |char| player[:guessed].include?(char) }
        complete_ranked_win_locked(player)
      end
    else
      player[:wrong] += 1
      if player[:safety_charges].to_i > 0
        player[:safety_charges] -= 1
        player[:wrong] -= 1
      else
        player[:streak] = 1
        if player[:wrong] >= (player[:max_misses] || LAN_MAX_MISSES)
          revive_round = player[:last_revive_round]
          if card_effect?(player, :resurrection) && (revive_round.nil? || revive_round <= @round_number - 10)
            player[:last_revive_round] = @round_number
            player[:wrong] = 0
          else
            player[:status] = 'out'
          end
        end
      end
    end
    update_match_locked
    match_snapshot_locked(username)
  end

  def update_match_locked
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    case @phase
    when :rules
      needed_votes = skip_votes_needed
      if @skip_votes.length >= needed_votes || now >= @rules_deadline
        @rules_skipped = @skip_votes.length >= needed_votes
        begin_countdown_locked
      end
    when :countdown
      begin_round_locked if now >= @countdown_deadline
    when :playing
      if now >= @match_deadline
        @match_players.each_value { |player| player[:status] = 'time' if player[:status] == 'playing' }
      end
      finish_round_locked if @match_players.values.all? { |player| player[:status] != 'playing' }
    when :round_results
      if now >= @round_results_deadline
        if @round_number >= LAN_MATCH_ROUNDS
          finish_match_locked
        elsif (@round_number % LAN_ROUNDS_PER_SHOP).zero?
          open_shop_locked
        else
          begin_countdown_locked
        end
      end
    when :shop
      if @match_players.values.all? { |player| player[:shop_ready] || player[:status] == 'left' }
        begin_countdown_locked
      end
    end
  end

  def match_snapshot_locked(username)
    update_match_locked
    own = @match_players[username]
    return { type: 'error', message: 'No match state is available for this player.' } unless own

    snapshot = {
      type: 'match_state',
      phase: @phase.to_s,
      round: @round_number,
      total_rounds: LAN_MATCH_ROUNDS,
      rules_seconds: @phase == :rules ? [(@rules_deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)).ceil, 0].max : nil,
      skip_votes: @skip_votes.length,
      skip_votes_needed: skip_votes_needed,
      rules_skipped: @rules_skipped || false,
      countdown_seconds: @countdown_deadline ? [(@countdown_deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)).ceil, 0].max : nil,
      standings: ranked_standings_locked,
      player: nil,
      shop: nil
    }

    if %i[playing round_results].include?(@phase)
      snapshot[:category] = @round_number <= 15 ? @shared_category : nil
      snapshot[:seconds_left] = [(@match_deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)).ceil, 0].max
      snapshot[:player] = public_player_state(own, expose_word: own[:status] != 'playing')
    elsif @phase == :shop
      snapshot[:player] = public_player_state(own, expose_word: false)
      snapshot[:shop] = {
        templates: own[:templates], wallet: own[:wallet], offers: own[:offers].map { |key| shop_card_summary(key) },
        locked_card: own[:locked_offer], next_locked_card: own[:locked_card],
        ready: own[:shop_ready], items: shop_items
      }
    elsif @phase == :finished
      snapshot[:winner] = @winner
      snapshot[:transferred_points] = @transferred_points || 0
    end
    snapshot
  end

  def skip_votes_needed
    active_players = @match_players.values.count { |player| player[:status] != 'left' }
    return 0 if active_players.zero?
    active_players <= 2 ? active_players : (active_players * 0.7).ceil
  end

  def begin_countdown_locked
    @phase = :countdown
    @countdown_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + LAN_COUNTDOWN_SECONDS
  end

  def begin_round_locked
    @round_number += 1
    @shared_category = CATEGORIES.keys.sample
    @shared_word = CATEGORIES[@shared_category].sample.downcase
    @match_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + LAN_ROUND_SECONDS
    @match_players.each_value do |player|
      next if player[:status] == 'left'

      player[:guessed] = []
      player[:wrong] = 0
      player[:streak] = [card_effect_value(player, :auto_streak_start).to_i, 1].max
      max_streak = card_effect_value(player, :max_streak).to_i
      player[:streak] = [player[:streak], max_streak].min if max_streak.positive?
      player[:round_multiplier] = 1
      player[:round_points] = 0
      player[:max_misses] = LAN_MAX_MISSES
      player[:safety_charges] = 0
      player[:status] = 'playing'
      auto_win_chance = card_effect_value(player, :auto_win_chance).to_f
      player[:auto_win_ready] = auto_win_chance.positive? && rand < auto_win_chance
      if card_effect?(player, :see_word_hint)
        player[:guessed] |= [@shared_word[0], @shared_word[-1]].compact.uniq
        player[:status] = 'won' if (@shared_word.chars.uniq - player[:guessed]).empty?
      end
      free_reveals = card_effect_value(player, :usage_bonus).to_i
      player[:free_reveals] = free_reveals
    end
    @phase = :playing
  end

  def finish_round_locked
    @phase = :round_results
    @round_results_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
  end

  def open_shop_locked
    eligible = ranked_skill_cards
    @match_players.each_value do |player|
      next if player[:status] == 'left'

      player[:templates] += 1
      locked = player[:locked_card]
      locked = nil if locked && player[:cards].include?(locked)
      available = eligible.keys.map(&:to_s) - player[:cards] - [locked]
      offers = available.sample(3)
      player[:offers] = ([locked] + offers).compact.uniq
      player[:locked_offer] = locked
      player[:locked_card] = nil
      player[:shop_ready] = false
    end
    @phase = :shop
  end

  def handle_shop_action_locked(username, request)
    update_match_locked
    return { type: 'error', message: 'The shop is not currently open.' } unless @phase == :shop
    player = @match_players[username]
    return { type: 'error', message: 'Player is not part of this match.' } unless player
    return { type: 'error', message: 'You are already ready for the next round.' } if player[:shop_ready] && request['action'] != 'ready'

    case request['action']
    when 'buy_item'
      item = shop_items.find { |entry| entry[:id] == request['item'].to_s }
      return { type: 'error', message: 'That item is not available in ranked mode.' } unless item
      return { type: 'error', message: 'Not enough match points.' } if player[:wallet] < item[:cost]

      player[:wallet] -= item[:cost]
      player[:inventory][item[:id]] = player[:inventory].fetch(item[:id], 0) + 1
    when 'buy_card'
      key = request['card'].to_s
      card = ranked_skill_cards[key.to_sym]
      return { type: 'error', message: 'That card is not in this shop offer.' } unless card && player[:offers].include?(key)
      return { type: 'error', message: 'You already own that card.' } if player[:cards].include?(key)
      cost = LAN_CARD_TEMPLATE_COSTS.fetch(card[:rarity], 99)
      return { type: 'error', message: 'Not enough skill templates.' } if player[:templates] < cost

      player[:templates] -= cost
      player[:cards] << key
    when 'lock_card'
      key = request['card'].to_s
      return { type: 'error', message: 'That card is not in this shop offer.' } unless player[:offers].include?(key)
      return { type: 'error', message: 'Owned cards cannot be locked for another offer.' } if player[:cards].include?(key)

      player[:locked_card] = key
    when 'unlock_card'
      player[:locked_card] = nil
    when 'ready'
      player[:shop_ready] = true
    else
      return { type: 'error', message: 'Unknown shop action.' }
    end
    update_match_locked
    match_snapshot_locked(username)
  end

  def use_match_item_locked(username, item_id)
    update_match_locked
    player = @match_players[username]
    return { type: 'error', message: 'Player is not part of this match.' } unless player
    return match_snapshot_locked(username) unless @phase == :playing && player[:status] == 'playing'

    item_id = item_id.to_s
    count = player[:inventory].fetch(item_id, 0)
    count += player[:free_reveals].to_i if item_id == 'reveal_letter'
    return { type: 'error', message: 'You do not have that item.' } unless count.positive?

    case item_id
    when 'reveal_letter'
      hidden = @shared_word.chars.uniq - player[:guessed]
      return { type: 'error', message: 'No hidden letters remain.' } if hidden.empty?
      player[:guessed] << hidden.sample
      if player[:free_reveals].to_i.positive?
        player[:free_reveals] -= 1
      else
        player[:inventory][item_id] -= 1
      end
      player[:status] = 'won' if (@shared_word.chars.uniq - player[:guessed]).empty?
    when 'extra_life'
      player[:max_misses] += card_effect_value(player, :life_grant).to_i.nonzero? || 1
      player[:inventory][item_id] -= 1
    when 'double_down'
      multiplier = card_effect_value(player, :multiplier_boost) || 2
      player[:round_multiplier] *= multiplier
      player[:inventory][item_id] -= 1
    when 'safety_net'
      durability = card_effect_value(player, :durability).to_i
      player[:safety_charges] += durability.positive? ? durability : 1
      player[:inventory][item_id] -= 1
    else
      return { type: 'error', message: 'Unknown item.' }
    end
    update_match_locked
    match_snapshot_locked(username)
  end

  def ranked_skill_cards
    supported_effects = %i[
      usage_bonus durability multiplier_boost life_grant auto_streak_start
      streak_per_correct perfect_bonus see_word_hint resurrection max_streak
      perfect_guarantee auto_win_chance
    ]
    SKILL_CARDS.select do |_key, card|
      next false if card[:type] == :item_upgrade && card[:target] == :bonus_point

      card[:effect].keys.any? { |effect| supported_effects.include?(effect) }
    end
  end

  def shop_items
    SHOP_ITEMS.select { |item| item[:type] == :consumable }.map do |item|
      { id: item[:id].to_s, name: item[:name], description: item[:description], cost: item[:cost] }
    end
  end

  def shop_card_summary(key)
    card = ranked_skill_cards[key.to_sym]
    { key: key, name: card[:name], rarity: card[:rarity].to_s, description: card[:description], cost: LAN_CARD_TEMPLATE_COSTS.fetch(card[:rarity], 99) }
  end

  def card_effects(player)
    player[:cards].each_with_object([]) do |key, effects|
      card = ranked_skill_cards[key.to_sym]
      effects << card[:effect] if card && card[:effect]
    end
  end

  def card_effect?(player, effect)
    card_effects(player).any? { |effects| effects[effect] }
  end

  def card_effect_value(player, effect)
    card_effects(player).map { |effects| effects[effect] }.compact.max
  end

  def award_ranked_correct_letter_locked(player)
    streak = player[:streak] || 1
    increment = (streak * (player[:round_multiplier] || 1)).round
    increment *= 2 if card_effect?(player, :perfect_guarantee)
    player[:points] += increment
    player[:wallet] += increment
    player[:round_points] += increment
    player[:streak] += [card_effect_value(player, :streak_per_correct).to_i, 1].max
    max_streak = card_effect_value(player, :max_streak).to_i
    player[:streak] = [player[:streak], max_streak].min if max_streak.positive?
  end

  def complete_ranked_win_locked(player)
    if player[:wrong].zero?
      bonus = card_effect_value(player, :perfect_bonus).to_f
      bonus_points = (player[:round_points] * bonus).round
      player[:points] += bonus_points
      player[:wallet] += bonus_points
      player[:round_points] += bonus_points
    end
    player[:status] = 'won'
  end

  def ranked_standings_locked
    @match_players.map do |name, player|
      { username: name, points: player[:points], wallet: player[:wallet], status: player[:status] }
    end.sort_by { |player| [-player[:points], player[:username].downcase] }
  end

  def public_player_state(player, expose_word:)
    {
      word: expose_word ? @shared_word : nil,
      word_length: @shared_word.to_s.length,
      display: @shared_word.to_s.chars.map { |char| player[:guessed].include?(char) ? char : '_' }.join(' '),
      guessed: player[:guessed].dup,
      wrong: player[:wrong],
      max_misses: player[:max_misses] || LAN_MAX_MISSES,
      score: player[:points], wallet: player[:wallet], templates: player[:templates],
      cards: player[:cards].map { |key| shop_card_summary(key) },
      inventory: player[:inventory].dup, free_reveals: player[:free_reveals].to_i,
      status: player[:status], shop_ready: player[:shop_ready]
    }
  end

  def finish_match_locked
    standings = ranked_standings_locked
    eligible = standings.reject { |player| player[:status] == 'left' }
    top_points = eligible.first && eligible.first[:points]
    tied = eligible.count { |player| player[:points] == top_points } > 1
    @winner = tied ? nil : (eligible.first && eligible.first[:username])
    winner = @match_players[@winner]
    @transferred_points = if winner
      @match_players.sum do |name, player|
        next 0 if name == @winner

        transfer = player[:wallet]
        player[:wallet] = 0
        transfer
      end
    else
      0
    end
    winner[:wallet] += @transferred_points if winner
    @phase = :finished
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
