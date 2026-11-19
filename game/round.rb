# ── Play one round ────────────────────────────────────────────
def register_round_timeout(state)
  state[:losses] += 1
  state[:streak] = 1
  state[:peak_streak] = [state[:peak_streak] || 1, 1].max
  :timeout
end

def play_round(category, word, state, difficulty = :easy, difficulty_ref = nil)
  preset_settings = difficulty_preset_settings(state[:difficulty_preset])
  timer_seconds = preset_settings[:round_timer]
  state[:round_deadline] = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timer_seconds if timer_seconds
  guessed       = []
  wrong_letters = []
  wrong_count   = 0
  max_wrong_ref = [preset_settings[:max_wrong] + (state[:pending_extra_lives] || 0)]
  state[:pending_extra_lives] = 0
  safety_armed  = [false]
  safety_used   = [false]

  # Omniscience: pre-reveal first and last letter of the word
  if (state[:active_skills] || []).any? { |c| c[:effect] && c[:effect][:see_word_hint] }
    guessed |= [word[0], word[-1]].compact.uniq
  end

  temp_mult            = state[:temp_multiplier] || 1
  state[:temp_multiplier] = nil

  loop do
    draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)

    ch = if state[:round_deadline]
      remaining = state[:round_deadline] - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      remaining.positive? ? $stdin.getch(min: 0, time: [remaining, 1.0].min, intr: true) : nil
    else
      $stdin.getch
    end

    if ch.nil?
      if state[:round_deadline] && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= state[:round_deadline]
        return register_round_timeout(state)
      end
      next
    end
    return register_round_timeout(state) if state[:round_deadline] && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= state[:round_deadline]
    ch = ch.downcase

    if ch == '-'
      require_relative '../menus/dev'
      if dev_passcode_prompt
        difficulty_ref ||= [difficulty]
        open_dev_menu(state, difficulty_ref)
        difficulty = difficulty_ref[0]
      end
      next
    end

    if ch == '+'
      require_relative '../menus/consumables'
      consumable_menu(word, guessed, state, max_wrong_ref, safety_armed)

      return register_round_timeout(state) if state[:round_deadline] && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= state[:round_deadline]

      if word.chars.uniq.all? { |c| guessed.include?(c) }
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)
        state[:wins] += 1
        state[:peak_streak] = [state[:streak], state[:peak_streak] || 1].max
        return :win
      end
      next
    end

    next unless ch.match?(/[a-z]/)
    letter = ch

    if guessed.include?(letter) || wrong_letters.include?(letter)
      puts "\n  " + Color.yellow("Already guessed '#{letter}'!"); sleep 0.7; next
    end

    if word.include?(letter)
      guessed << letter

      base          = 1 + (state[:permanent_bonuses][:bonus_point] || 0)
      eff           = state[:streak] * temp_mult
      difficulty_mult = get_difficulty_multiplier(difficulty)
      earned        = (base * eff * difficulty_mult).round
      record_points_earned(state, earned)

      streak_chain = (1..state[:streak]).map { |n| Color.bold(Color.yellow("#{n}x")) }.join(Color.dim(" → "))
      next_mult    = (state[:streak] + 1) * temp_mult

      puts "\n  " + Color.green("+#{earned} pts") +
           Color.dim("  [") + streak_chain + Color.dim("]") +
           Color.dim("  Next correct: ") + Color.bold(Color.cyan("#{next_mult}x"))

      state[:streak] += 1
      sleep 0.6

      if word.chars.uniq.all? { |c| guessed.include?(c) }
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)
        state[:wins] += 1
        state[:peak_streak] = [state[:streak], state[:peak_streak] || 1].max
        return :win
      end

    else
      if safety_armed[0] && !safety_used[0]
        safety_used[0] = true
        wrong_letters << letter
        puts "\n  " + Color.yellow("[S] Safety Net absorbed '#{letter.upcase}'! (still #{max_wrong_ref[0] - wrong_count} lives)")
        sleep 0.9
        next
      end

      wrong_letters << letter
      wrong_count   += 1

      if state[:streak] > 1
        puts "\n  " + Color.red("Streak broken!") + Color.dim("  (was #{state[:streak]}x → back to 1x)")
        sleep 0.7
      end
      state[:streak] = 1

      if wrong_count >= max_wrong_ref[0]
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)
        state[:losses] += 1
        state[:peak_streak] = [state[:peak_streak] || 1, 1].max
        return :lose
      end
    end
  end
ensure
  state[:round_deadline] = nil
end

# ── Round-end prompt ──────────────────────────────────────────
def round_end_prompt(state, result, word, difficulty_ref)
  puts
  if result == :win
    puts center_text(Color.bold(Color.green("You won!  The word was: #{word.upcase}")))
  elsif result == :timeout
    puts center_text(Color.bold(Color.red("Time ran out!  The word was: #{word.upcase}")))
  else
    puts center_text(Color.bold(Color.red("Game over!  The word was: #{word.upcase}")))
  end
  puts
  puts center_text(Color.bold(Color.yellow("Score: #{state[:score]} pts")) +
                   Color.dim("  |  W:#{state[:wins]} L:#{state[:losses]}  Peak streak: #{state[:peak_streak]}x"))
  puts
  puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
  puts

  loop do
    print "  Choice: "
    ch = $stdin.getch.downcase
    
    if ch == 'p'
      require_relative '../menus/saves'
      open_save_menu(state, difficulty_ref)
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
      next
    end
    
    if ch == 'd'
      require_relative '../game/difficulty'
      open_difficulty_menu(state, difficulty_ref)
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
      next
    end
    
    puts ch
    case ch
    when 's'
      require_relative '../menus/shop'
      open_shop(state)
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
    when 'i'
      require_relative '../menus/inventory'
      open_card_inventory(state)
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")

    when '-'
      require_relative '../menus/dev'
      if dev_passcode_prompt
        open_dev_menu(state, difficulty_ref)
      end
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
    when 'y' then return :play
    when 'm'
      action = return_to_main_menu_prompt(state, difficulty_ref)
      return :main_menu if action == :main_menu
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
    when 'n'
      print "  Type QUIT and press Enter to exit: "
      confirmation = $stdin.gets
      if confirmation&.strip&.casecmp("QUIT")&.zero?
        return :quit
      end
      puts Color.yellow("  Quit cancelled.")
      puts center_text("[P] Save   [S] Shop   [I] Cards   [D] Difficulty   [-] Dev   [Y] Play Again   [M] Main Menu   [N] Quit")
    end
  end
end

def return_to_main_menu_prompt(state, difficulty_ref)
  loop do
    puts
    puts "  Return to the main menu? [S] Save first  [N] Don't save  [C] Cancel"
    print "  Choice: "
    choice = $stdin.gets&.strip&.downcase

    case choice
    when 'n'
      return :main_menu
    when 'c'
      return :cancel
    when 's'
      slots = get_save_slots
      clear
      draw_header("S A V E  B E F O R E  M A I N  M E N U")
      (1..MAX_SAVE_SLOTS).each do |slot|
        slot_info = slots[slot]
        if slot_info[:exists] && !save_available_for_user?(slot_info, state[:username])
          puts "  #{Color.dim("[#{slot}] [Owned by #{slot_info[:username]}]")}"
        else
          puts "  [#{slot}] #{format_save_info(slot_info)}"
        end
      end
      puts "  [C] Cancel and return to the game"
      print "  Save to slot: "
      slot_choice = $stdin.gets&.strip&.downcase

      return :cancel if slot_choice == 'c'
      unless slot_choice&.match?(/\A[1-#{MAX_SAVE_SLOTS}]\z/)
        puts Color.red("  Invalid save slot.")
        next
      end

      slot = slot_choice.to_i
      slot_info = slots[slot]
      if slot_info[:exists] && !save_available_for_user?(slot_info, state[:username])
        puts Color.red("  You cannot overwrite another account's save.")
        next
      end

      if save_game(state, difficulty_ref, slot)
        puts Color.green("  Game saved to slot #{slot}. Returning to the main menu...")
        return :main_menu
      end

      puts Color.red("  Save failed. You can try again or cancel.")
    else
      puts Color.red("  Choose S, N, or C.")
    end
  end
end
