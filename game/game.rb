# ── Main ──────────────────────────────────────────────────────
def main(save_slot = nil)
  # Load from save slot if provided
  if save_slot
    loaded = load_game(save_slot)
    if loaded
      state, difficulty_name = loaded
      difficulty_ref = [difficulty_name]
      
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
      difficulty_ref = [:easy]
      show_initial_screen(state, difficulty_ref)
    end
  else
    # New game
    state = get_initial_state
    difficulty_ref = [:easy]
    show_initial_screen(state, difficulty_ref)
  end

  require_relative 'difficulty'
  require_relative 'round'
  require_relative '../menus/inventory'
  require_relative '../lib/save_system'

  loop do
    state[:total_rounds] += 1

    if state[:total_rounds] == 9 && difficulty_ref[0] == :easy
      show_medium_prompt
      difficulty_ref[0] = :medium
    elsif state[:total_rounds] == 16 && difficulty_ref[0] == :medium
      show_hard_prompt
      difficulty_ref[0] = :hard
    elsif state[:total_rounds] == 26 && difficulty_ref[0] == :hard
      difficulty_ref[0] = show_extreme_prompt
    end

    category = choose_category(difficulty_ref[0])
    word     = CATEGORIES[category].sample.downcase
    result   = play_round(category, word, state, difficulty_ref[0])
    action   = round_end_prompt(state, result, word, difficulty_ref)
    break if action == :quit

    if state[:wins] % 5 == 0 && state[:wins] > 0
      skill_card_selection_menu(state)
      # Check if player unlocked the Enchanted Mystical skin
      check_enchanted_skin_unlock(state)
    end
  end

  clear
  draw_header("G  A  M  E  O  V  E  R")
  puts box_line(Color.bold(Color.yellow("Final Score:  #{state[:score]} pts")))
  puts box_line(Color.dim("Wins: #{state[:wins]}   Losses: #{state[:losses]}   Peak Streak: #{state[:peak_streak]}x"))
  puts box_line(Color.dim("Skill Cards Collected: #{state[:skill_cards].length}"))
  draw_footer
  puts
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
    active_skin:       :default,
    unlocked_skins:    [:default],
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
  puts box_line(Color.dim("Press + to use consumables during gameplay!"))
  puts box_line("")
  puts box_line(Color.bold("Press any key to start..."))
  draw_footer
  $stdin.getch
end
