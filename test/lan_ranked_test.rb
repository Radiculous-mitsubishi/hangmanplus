require 'minitest/autorun'
require_relative '../lib/color'
require_relative '../config/constants'
require_relative '../config/items'
require_relative '../lib/lan_lobby'

class LanRankedTest < Minitest::Test
  def setup
    @server = LanLobbyServer.new('Host_1', port: 0)
    @host = TCPSocket.new('127.0.0.1', @server.port)
    lan_send_request(@host, type: 'host_join', token: @server.host_token)
    @guest = TCPSocket.new('127.0.0.1', @server.port)
    lan_send_request(@guest, type: 'join', username: 'Guest_1')
  end

  def teardown
    [@host, @guest].compact.each { |socket| socket.close unless socket.closed? }
    @server.stop
  end

  def test_two_player_rules_skip_requires_unanimous_vote
    start_response = lan_send_request(@host, type: 'start')
    assert_equal 'rules', start_response['phase']
    assert_equal 2, start_response['skip_votes_needed']

    one_vote = lan_send_request(@host, type: 'skip_vote')
    assert_equal 'rules', one_vote['phase']
    assert_equal 1, one_vote['skip_votes']

    passed = lan_send_request(@guest, type: 'skip_vote')
    assert_equal 'countdown', passed['phase']
    assert_equal true, passed['rules_skipped']
  end

  def test_three_player_rules_skip_uses_seventy_percent_quorum
    third = TCPSocket.new('127.0.0.1', @server.port)
    lan_send_request(third, type: 'join', username: 'Third_1')
    start_response = lan_send_request(@host, type: 'start')
    assert_equal 3, start_response['skip_votes_needed']

    lan_send_request(@host, type: 'skip_vote')
    one_more_vote = lan_send_request(@guest, type: 'skip_vote')
    assert_equal 'rules', one_more_vote['phase']
    assert_equal 2, one_more_vote['skip_votes']

    passed = lan_send_request(third, type: 'skip_vote')
    assert_equal 'countdown', passed['phase']
  ensure
    third&.close unless third&.closed?
  end

  def test_ranked_round_uses_one_hidden_server_word_for_all_players
    start_match
    countdown_elapsed
    host_state = lan_send_request(@host, type: 'state')
    guest_state = lan_send_request(@guest, type: 'state')

    assert_equal 'playing', host_state['phase']
    assert_equal host_state['round'], guest_state['round']
    assert_nil host_state['player']['word']
    assert_nil guest_state['player']['word']
    assert_equal host_state['player']['word_length'], guest_state['player']['word_length']
    assert_equal host_state['category'], guest_state['category']

    word = @server.instance_variable_get(:@shared_word)
    letter = word.chars.uniq.first
    first_guess = lan_send_request(@host, type: 'guess', letter: letter)
    points_after_first = first_guess.dig('player', 'score')
    duplicate_guess = lan_send_request(@host, type: 'guess', letter: letter)
    assert_equal points_after_first, duplicate_guess.dig('player', 'score')
  end

  def test_ranked_shop_awards_template_and_supports_card_lock_and_item_purchase
    start_match
    @server.instance_variable_get(:@mutex).synchronize do
      @server.send(:begin_round_locked)
      @server.instance_variable_set(:@round_number, 5)
      @server.instance_variable_set(:@phase, :round_results)
      @server.instance_variable_set(:@round_results_deadline, Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1)
      @server.instance_variable_get(:@match_players).each_value do |player|
        player[:status] = 'won'
        player[:templates] = 5
        player[:wallet] = 100
      end
    end

    shop = lan_send_request(@host, type: 'state')
    assert_equal 'shop', shop['phase']
    assert_equal 6, shop.dig('shop', 'templates')
    card = shop.dig('shop', 'offers').first
    bought_card = lan_send_request(@host, type: 'shop', action: 'buy_card', card: card['key'])
    assert_includes bought_card.dig('player', 'cards').map { |owned| owned['key'] }, card['key']

    bought_item = lan_send_request(@host, type: 'shop', action: 'buy_item', item: 'reveal_letter')
    assert_equal 1, bought_item.dig('player', 'inventory', 'reveal_letter')
    lock_candidate = bought_item.dig('shop', 'offers').find { |offer| offer['key'] != card['key'] }
    if lock_candidate
      locked = lan_send_request(@host, type: 'shop', action: 'lock_card', card: lock_candidate['key'])
      assert_equal lock_candidate['key'], locked.dig('shop', 'next_locked_card')
    end

    host_ready = lan_send_request(@host, type: 'shop', action: 'ready')
    assert_equal 'shop', host_ready['phase']
    guest_ready = lan_send_request(@guest, type: 'shop', action: 'ready')
    assert_equal 'countdown', guest_ready['phase']

    if lock_candidate
      @server.instance_variable_get(:@mutex).synchronize do
        @server.instance_variable_set(:@round_number, 10)
        @server.send(:open_shop_locked)
      end
      next_shop = lan_send_request(@host, type: 'state')
      assert_equal lock_candidate['key'], next_shop.dig('shop', 'locked_card')
      assert_includes next_shop.dig('shop', 'offers').map { |offer| offer['key'] }, lock_candidate['key']
    end
  end

  def test_final_winner_gets_only_opponents_unspent_wallet
    start_match
    @server.instance_variable_get(:@mutex).synchronize do
      players = @server.instance_variable_get(:@match_players)
      players['Host_1'].merge!(points: 100, wallet: 25, status: 'won')
      players['Guest_1'].merge!(points: 90, wallet: 12, status: 'won')
      @server.send(:finish_match_locked)
    end

    result = lan_send_request(@host, type: 'state')
    assert_equal 'finished', result['phase']
    assert_equal 'Host_1', result['winner']
    assert_equal 12, result['transferred_points']
    assert_equal 37, @server.instance_variable_get(:@match_players)['Host_1'][:wallet]
  end

  def test_bonus_point_upgrade_is_not_in_ranked_card_pool
    cards = @server.send(:ranked_skill_cards)
    refute cards.values.any? { |card| card[:type] == :item_upgrade && card[:target] == :bonus_point }
    assert cards.key?(:mythic_skill_1)
    assert cards.key?(:mythic_skill_2)
  end

  def test_full_thirty_five_round_schedule_and_six_shops
    start_match
    shops = 0

    1.upto(LAN_MATCH_ROUNDS) do |round_number|
      accelerate_deadline(:countdown_deadline)
      snapshot = lan_send_request(@host, type: 'state')
      assert_equal 'playing', snapshot['phase']
      assert_equal round_number, snapshot['round']
      assert_equal(round_number <= 15, !snapshot['category'].nil?)

      [@host, @guest].each { |socket| solve_current_word(socket) }
      accelerate_deadline(:round_results_deadline)
      snapshot = lan_send_request(@host, type: 'state')

      if (round_number % LAN_ROUNDS_PER_SHOP).zero? && round_number < LAN_MATCH_ROUNDS
        shops += 1
        assert_equal 'shop', snapshot['phase']
        assert_equal round_number / LAN_ROUNDS_PER_SHOP, snapshot.dig('shop', 'templates')
        lan_send_request(@host, type: 'shop', action: 'ready')
        snapshot = lan_send_request(@guest, type: 'shop', action: 'ready')
        assert_equal 'countdown', snapshot['phase']
      elsif round_number < LAN_MATCH_ROUNDS
        assert_equal 'countdown', snapshot['phase']
      else
        assert_equal 'finished', snapshot['phase']
        assert_nil snapshot['winner']
        assert_equal 0, snapshot['transferred_points']
      end
    end

    assert_equal 6, shops
  end

  private

  def start_match
    response = lan_send_request(@host, type: 'start')
    assert_equal 'rules', response['phase']
    lan_send_request(@host, type: 'skip_vote')
    response = lan_send_request(@guest, type: 'skip_vote')
    assert_equal 'countdown', response['phase']
  end

  def countdown_elapsed
    accelerate_deadline(:countdown_deadline)
  end

  def accelerate_deadline(field)
    @server.instance_variable_get(:@mutex).synchronize do
      variable = field.to_s.start_with?('@') ? field : "@#{field}"
      @server.instance_variable_set(variable, Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1)
    end
  end

  def solve_current_word(socket)
    snapshot = lan_send_request(socket, type: 'state')
    while snapshot['phase'] == 'playing' && snapshot.dig('player', 'status') == 'playing'
      word = @server.instance_variable_get(:@shared_word)
      letter = (word.chars.uniq - snapshot.dig('player', 'guessed')).first
      break unless letter

      snapshot = lan_send_request(socket, type: 'guess', letter: letter)
    end
    snapshot
  end
end
