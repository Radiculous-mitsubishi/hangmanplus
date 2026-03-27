# ── Save System ──────────────────────────────────────────────

require 'json'
require 'fileutils'

SAVES_DIR = File.join(File.dirname(__FILE__), '..', 'saves')
MAX_SAVE_SLOTS = 4

# Ensure saves directory exists
def ensure_saves_dir
  FileUtils.mkdir_p(SAVES_DIR) unless Dir.exist?(SAVES_DIR)
end

# Get path to save file
def get_save_path(slot)
  ensure_saves_dir
  File.join(SAVES_DIR, "save_#{slot}.json")
end

# Get all save slots info
def get_save_slots
  ensure_saves_dir
  slots = {}
  
  (1..MAX_SAVE_SLOTS).each do |slot|
    path = get_save_path(slot)
    if File.exist?(path)
      begin
        data = JSON.parse(File.read(path))
        slots[slot] = {
          exists: true,
          score: data['score'] || 0,
          wins: data['wins'] || 0,
          losses: data['losses'] || 0,
          rounds: data['total_rounds'] || 0,
          difficulty: data['difficulty'] || 'easy',
          timestamp: File.mtime(path)
        }
      rescue
        slots[slot] = { exists: false }
      end
    else
      slots[slot] = { exists: false }
    end
  end
  
  slots
end

# Save game state to slot
def save_game(state, difficulty_ref, slot)
  ensure_saves_dir
  
  save_data = {
    score: state[:score],
    wins: state[:wins],
    losses: state[:losses],
    streak: state[:streak],
    peak_streak: state[:peak_streak],
    total_rounds: state[:total_rounds],
    inventory: state[:inventory],
    permanent_bonuses: state[:permanent_bonuses],
    temp_multiplier: state[:temp_multiplier],
    pending_extra_lives: state[:pending_extra_lives],
    skill_cards: state[:skill_cards],
    active_skills: state[:active_skills],
    card_counts: state[:card_counts],
    active_skin: state[:active_skin],
    unlocked_skins: state[:unlocked_skins],
    slot_spins: state[:slot_spins],
    difficulty: difficulty_ref[0],
    saved_at: Time.now.to_s
  }
  
  path = get_save_path(slot)
  File.write(path, JSON.pretty_generate(save_data))
  true
rescue => e
  puts "Error saving game: #{e.message}"
  false
end

# Load game state from slot
def load_game(slot)
  path = get_save_path(slot)
  
  return nil unless File.exist?(path)
  
  begin
    data = JSON.parse(File.read(path))
    
    # Helper function to recursively convert string keys to symbol keys
    # Also converts rarity and type fields to symbols
    strings_to_symbols = lambda do |obj|
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), acc|
          sym_key = k.is_a?(String) ? k.to_sym : k
          # Convert rarity and type values to symbols
          if sym_key == :rarity || sym_key == :type || sym_key == :active_skin
            acc[sym_key] = v.is_a?(String) ? v.to_sym : v
          else
            acc[sym_key] = strings_to_symbols.call(v)
          end
        end
      when Array
        obj.map { |item| strings_to_symbols.call(item) }
      else
        obj
      end
    end
    
    # Convert loaded data to use symbol keys
    data = strings_to_symbols.call(data)
    
    state = {
      score: data[:score] || 0,
      wins: data[:wins] || 0,
      losses: data[:losses] || 0,
      streak: data[:streak] || 1,
      peak_streak: data[:peak_streak] || 1,
      total_rounds: data[:total_rounds] || 0,
      inventory: data[:inventory] || {},
      permanent_bonuses: data[:permanent_bonuses] || {},
      temp_multiplier: data[:temp_multiplier],
      pending_extra_lives: data[:pending_extra_lives] || 0,
      skill_cards: data[:skill_cards] || [],
      active_skills: data[:active_skills] || [],
      card_counts: data[:card_counts] || {},
      active_skin: (data[:active_skin] || :default).to_sym,
      unlocked_skins: (data[:unlocked_skins] || [:default]).map { |s| s.is_a?(String) ? s.to_sym : s },
      slot_spins: data[:slot_spins] || 0
    }
    
    difficulty = data[:difficulty]&.to_sym || :easy
    
    [state, difficulty]
  rescue => e
    puts "Error loading game: #{e.message}"
    nil
  end
end

# Delete save file
def delete_save(slot)
  path = get_save_path(slot)
  File.delete(path) if File.exist?(path)
  true
rescue
  false
end

# Format save slot display
def format_save_info(slot_info)
  if slot_info[:exists]
    score = slot_info[:score]
    wins = slot_info[:wins]
    losses = slot_info[:losses]
    rounds = slot_info[:rounds]
    difficulty = slot_info[:difficulty].upcase
    time = slot_info[:timestamp].strftime('%m/%d %H:%M')
    
    "Score: #{score}  |  W:#{wins} L:#{losses}  |  Round #{rounds}  |  #{difficulty}  |  #{time}"
  else
    "[Empty Slot]"
  end
end
