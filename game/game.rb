# ── Main ──────────────────────────────────────────────────────
def main(game_selection = nil)
  # Load from save slot if provided
  if game_selection.is_a?(Integer) || (game_selection.is_a?(Hash) && game_selection[:type] == :load)
    save_slot = game_selection.is_a?(Integer) ? game_selection : game_selection[:slot]
    username = game_selection.is_a?(Hash) ? game_selection[:username] : nil
    loaded = load_game(save_slot, username: username)
    if loaded
      state, difficulty_name = loaded
      state[:difficulty_preset] ||= DEFAULT_DIFFICULTY_PRESET
      state[:difficulty_prompt_flags] ||= {}
      difficulty_ref = [difficulty_name]
      state[:username] = username if game_selection.is_a?(Hash)
      
      clear
      draw_header("H  A  N  G  M  A  N")
      puts box_line("")
      puts box_line(Color.green("✓ Game loaded successfully!"))
      puts box_line("")
      puts box_line(Color.dim("Continuing with #{difficulty_name.upcase} difficulty..."))
      puts box_line("")
      puts box_line(Color.bold("Press any key to continue..."))
      draw_footer
      $stdin.getch
    else
      puts "Failed to load save. Starting new game instead."
      state = get_initial_state
      state[:username] = game_selection[:username] if game_selection.is_a?(Hash)
      state[:difficulty_preset] = (game_selection[:difficulty_preset] || DEFAULT_DIFFICULTY_PRESET).to_sym if game_selection.is_a?(Hash)
      difficulty_ref = [difficulty_preset_settings(state[:difficulty_preset])[:starting_difficulty]]
      show_initial_screen(state, difficulty_ref)
    end
  else
    # New game
    state = get_initial_state
    if game_selection.is_a?(Hash)
      state[:username] = game_selection[:username]
      state[:save_name] = game_selection[:save_name]
      state[:difficulty_preset] = (game_selection[:difficulty_preset] || DEFAULT_DIFFICULTY_PRESET).to_sym
      state[:custom_word_list] = game_selection[:custom_word_list] if game_selection[:type] == :custom_game
    end
    difficulty_ref = [difficulty_preset_settings(state[:difficulty_preset])[:starting_difficulty]]
    show_initial_screen(state, difficulty_ref)
  end

  require_relative 'difficulty'
  require_relative 'round'
  require_relative '../menus/inventory'
  require_relative '../lib/save_system'

  loop do
    state[:total_rounds] += 1

    advance_preset_difficulty(state, difficulty_ref)

    if state[:custom_word_list]
      category = "Custom: #{state[:custom_word_list][:name]}"
      word = state[:custom_word_list][:words].sample
    else
      category = choose_category(difficulty_ref[0])
      word = CATEGORIES[category].sample.downcase
    end
    result   = play_round(category, word, state, difficulty_ref[0], difficulty_ref)
    action   = round_end_prompt(state, result, word, difficulty_ref)
    break if action == :quit

    if result == :win && state[:wins] % 5 == 0 && state[:wins] > 0
      skill_card_selection_menu(state)
    end

    if action == :main_menu
      clear
      return :main_menu
    end
  end

  clear
  draw_header("G  A  M  E  O  V  E  R")
  puts box_line(Color.bold(Color.yellow("Final Score:  #{state[:score]} pts")))
  puts box_line(Color.dim("Wins: #{state[:wins]}   Losses: #{state[:losses]}   Peak Streak: #{state[:peak_streak]}x"))
  puts box_line(Color.dim("Skill Cards Collected: #{state[:skill_cards].length}"))
  draw_footer
  puts
  :quit
end

# ── Helper: Get Initial State ──────────────────────────────────
def get_initial_state
  {
    score:             0,
    wins:              0,
    losses:            0,
    streak:            1,
    peak_streak:       1,
    total_rounds:      0,
    inventory:         {},
    permanent_bonuses: {},
    temp_multiplier:   nil,
    pending_extra_lives: 0,
    skill_cards:       [],
    active_skills:     [],
    card_counts:       {},
    username:          'Player',
    save_name:         'New Game',
    total_points_earned: 0,
    custom_word_list: nil,
    difficulty_preset: DEFAULT_DIFFICULTY_PRESET,
    difficulty_prompt_flags: {},

    slot_spins:        0
  }
end

# ── Helper: Show Initial Screen ────────────────────────────────
def show_initial_screen(state, difficulty_ref)
  clear
  draw_header("H  A  N  G  M  A  N")
  puts box_line("")
  puts box_line(Color.dim("Guess letters to reveal the hidden word."))
  puts box_line(Color.dim("Each correct letter earns points x your streak."))
  puts box_line(Color.dim("Win 5 rounds to roll for a skill card!"))
  puts box_line(Color.dim("Spend points in the Shop on powerful upgrades."))
  preset = difficulty_preset_settings(state[:difficulty_preset])
  puts box_line(Color.dim("Preset: #{preset[:name]}#{preset[:round_timer] ? " (#{preset[:round_timer]}s per round)" : ""}"))
  puts box_line(Color.dim("Press + to use consumables during gameplay!"))
  puts box_line("")
  puts box_line(Color.bold("Press any key to start..."))
  draw_footer
  $stdin.getch
end
