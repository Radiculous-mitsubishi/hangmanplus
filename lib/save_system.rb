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
          save_name: data['save_name'] || "Save #{slot}",
          username: data['username'],
          wins: data['wins'] || 0,
          losses: data['losses'] || 0,
          rounds: data['total_rounds'] || 0,
          difficulty: data['difficulty'] || 'easy',
          preset: data['difficulty_preset'] || 'standard',
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

def save_owner_matches?(slot_info, username)
  owner = slot_info[:username].to_s
  owner.empty? || owner.casecmp?('Player') || owner.casecmp?(username.to_s)
end

# Save game state to slot
def save_game(state, difficulty_ref, slot)
  ensure_saves_dir
  existing_slot = get_save_slots[slot]
  if existing_slot[:exists] && !save_owner_matches?(existing_slot, state[:username])
    puts "Cannot overwrite another account's save."
    return false
  end
  
  save_data = {
    score: state[:score],
    save_name: state[:save_name],
    username: state[:username],
    total_points_earned: state[:total_points_earned] || 0,
    custom_word_list: state[:custom_word_list],
    difficulty_preset: state[:difficulty_preset] || DEFAULT_DIFFICULTY_PRESET,
    difficulty_prompt_flags: state[:difficulty_prompt_flags] || {},
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
def load_game(slot, username: nil)
  path = get_save_path(slot)
  
  return nil unless File.exist?(path)
  slot_info = get_save_slots[slot]
  unless slot_info[:exists] && save_owner_matches?(slot_info, username)
    puts "Cannot load another account's save."
    return nil
  end
  
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
          if sym_key == :rarity || sym_key == :type
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
    difficulty = data[:difficulty]&.to_sym || :easy
    
    state = {
      score: data[:score] || 0,
      save_name: data[:save_name] || "Save #{slot}",
      username: data[:username] || 'Player',
      total_points_earned: data[:total_points_earned] || 0,
      custom_word_list: data[:custom_word_list],
      difficulty_preset: (data[:difficulty_preset] || DEFAULT_DIFFICULTY_PRESET).to_sym,
      difficulty_prompt_flags: data[:difficulty_prompt_flags] || {},
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
      slot_spins: data[:slot_spins] || 0
    }

    # Assign pre-account saves to the first account that successfully loads them.
    state[:username] = username if slot_info[:username].to_s.empty? || slot_info[:username].casecmp?('Player')
    state[:save_name] = "Save #{slot}" if state[:save_name].to_s.empty?
    save_game(state, [difficulty], slot) if state[:username] != slot_info[:username]
    
    [state, difficulty]
  rescue => e
    puts "Error loading game: #{e.message}"
    nil
  end
end

# Delete save file
def delete_save(slot, username:)
  path = get_save_path(slot)
  slot_info = get_save_slots[slot]
  return false unless slot_info[:exists] && save_owner_matches?(slot_info, username)

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
    
    "#{slot_info[:save_name]} (#{slot_info[:username] || 'Unassigned'})  |  #{slot_info[:preset].to_s.capitalize}  |  Score: #{score}  |  W:#{wins} L:#{losses}  |  Round #{rounds}  |  #{difficulty}  |  #{time}"
  else
    "[Empty Slot]"
  end
end
