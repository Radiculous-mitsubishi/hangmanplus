# ── Play one round ────────────────────────────────────────────
def play_round(category, word, state, difficulty = :easy)
  guessed       = []
  wrong_letters = []
  wrong_count   = 0
  max_wrong_ref = [BASE_MAX_WRONG + (state[:pending_extra_lives] || 0)]
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

    ch = $stdin.getch.downcase

    if ch == '+'
      require_relative '../menus/consumables'
      consumable_menu(word, guessed, state, max_wrong_ref, safety_armed)

      if word.chars.uniq.all? { |c| guessed.include?(c) }
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0])
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
      earned        = base * eff
      state[:score] += earned

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
end

# ── Round-end prompt ──────────────────────────────────────────
def round_end_prompt(state, result, word, difficulty_ref)
  puts
  if result == :win
    puts center_text(Color.bold(Color.green("You won!  The word was: #{word.upcase}")))
  else
    puts center_text(Color.bold(Color.red("Game over!  The word was: #{word.upcase}")))
  end
  puts
  puts center_text(Color.bold(Color.yellow("Score: #{state[:score]} pts")) +
                   Color.dim("  |  W:#{state[:wins]} L:#{state[:losses]}  Peak streak: #{state[:peak_streak]}x"))
  puts
  puts center_text("[Sv] Save   [S] Shop   [I] Cards   [K] Skins   [-] Dev   [Y] Play Again   [N] Quit")
  puts

  loop do
    print "  Choice: "
    ch = $stdin.getch.downcase
    
    # Check for two-character inputs (Sv)
    if ch == 's'
      next_ch = $stdin.getch.downcase rescue nil
      if next_ch == 'v'
        require_relative '../menus/saves'
        open_save_menu(state, difficulty_ref)
        puts center_text("[Sv] Save   [S] Shop   [I] Cards   [K] Skins   [-] Dev   [Y] Play Again   [N] Quit")
        next
      elsif next_ch
        # Put the second character back into processing
        ch = 's'
      else
        ch = 's'
      end
    end
    
    puts ch
    case ch
    when 's'
      require_relative '../menus/shop'
      open_shop(state)
      puts center_text("[Sv] Save   [S] Shop   [I] Cards   [K] Skins   [-] Dev   [Y] Play Again   [N] Quit")
    when 'i'
      require_relative '../menus/inventory'
      open_card_inventory(state)
      puts center_text("[Sv] Save   [S] Shop   [I] Cards   [K] Skins   [-] Dev   [Y] Play Again   [N] Quit")
    when 'k'
      require_relative '../menus/skins'
      open_skin_shop(state)
      puts center_text("[Sv] Save   [S] Shop   [I] Cards   [K] Skins   [-] Dev   [Y] Play Again   [N] Quit")
    when '-'
      require_relative '../menus/dev'
      if dev_passcode_prompt
        open_dev_menu(state, difficulty_ref)
      end
      puts center_text("[Sv] Save   [S] Shop   [I] Cards   [K] Skins   [-] Dev   [Y] Play Again   [N] Quit")
    when 'y' then return :play
    when 'n' then return :quit
    end
  end
end
