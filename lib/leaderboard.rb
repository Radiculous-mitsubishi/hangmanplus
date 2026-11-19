require_relative 'save_system'

LEADERBOARD_PATH = File.join(SAVES_DIR, 'leaderboard.json')

def get_local_leaderboard(limit: 10)
  ensure_saves_dir
  data = File.exist?(LEADERBOARD_PATH) ? JSON.parse(File.read(LEADERBOARD_PATH)) : { 'players' => [] }
  players = data['players'].is_a?(Array) ? data['players'] : []
  sorted_players = players.sort_by { |player| -(player['total_points'] || 0).to_i }
  limit ? sorted_players.first(limit) : sorted_players
rescue => error
  warn "Unable to read local leaderboard: #{error.message}"
  []
end

# Add earned points to the current save and persist the player's local total.
def record_points_earned(state, points)
  amount = points.to_i
  return 0 unless amount.positive?

  state[:score] = (state[:score] || 0) + amount
  state[:total_points_earned] = (state[:total_points_earned] || 0) + amount

  username = state[:username].to_s.strip
  return amount if username.empty?

  ensure_saves_dir
  data = if File.exist?(LEADERBOARD_PATH)
    JSON.parse(File.read(LEADERBOARD_PATH))
  else
    { 'players' => [] }
  end
  data['players'] = [] unless data['players'].is_a?(Array)

  player = data['players'].find do |entry|
    entry['username'].to_s.casecmp?(username)
  end
  if player
    player['username'] = username
    player['total_points'] = (player['total_points'] || 0).to_i + amount
  else
    data['players'] << { 'username' => username, 'total_points' => amount }
  end

  File.write(LEADERBOARD_PATH, JSON.pretty_generate(data))
  amount
rescue => error
  warn "Unable to update local leaderboard: #{error.message}"
  amount
end

def get_lifetime_points(username)
  normalized_username = username.to_s.strip
  return 0 if normalized_username.empty?

  player = get_local_leaderboard(limit: nil).find do |entry|
    entry['username'].to_s.casecmp?(normalized_username)
  end
  player ? (player['total_points'] || 0).to_i : 0
end