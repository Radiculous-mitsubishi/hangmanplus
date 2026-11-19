# ── Difficulty Selection Menu ─────────────────────────────
def choose_difficulty
  loop do
    clear
    draw_header("Select Difficulty")
    draw_divider
    puts box_line(Color.bold(Color.green("EASY")) + Color.dim(" - Choose category, category shown"))
    puts box_line(Color.dim("Rounds 1-8"))
    draw_divider
    puts box_line(Color.bold(Color.yellow("MEDIUM")) + Color.dim(" - Random words, category shown"))
    puts box_line(Color.dim("Rounds 8-15"))
    draw_divider
    puts box_line(Color.bold(Color.red("HARD")) + Color.dim(" - Random words, category hidden"))
    puts box_line(Color.dim("Rounds 15-25"))
    draw_divider
    puts box_line(Color.bold(Color.magenta("EXTREME")) + Color.dim(" - Unlock after 25 rounds"))
    puts box_line(Color.dim("No category hint, word length hidden"))
    draw_divider
    puts box_line("Choose difficulty: " + Color.bold(Color.yellow("[E]Easy  [M]Medium  [H]Hard")))
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input
    case input
    when 'e' then return :easy
    when 'm' then return :medium
    when 'h' then return :hard
    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

# ── Category menu ─────────────────────────────────────────────
def choose_category(difficulty = :easy)
  keys = CATEGORIES.keys
  
  if difficulty == :easy
    loop do
      clear
      draw_header("Choose a Word Category")
      keys.each_with_index do |name, i|
        puts box_line("#{Color.bold(Color.yellow((i+1).to_s))}. #{name} #{Color.dim("(#{CATEGORIES[name].length} words)")}")
      end
      puts box_line("#{Color.bold(Color.yellow('R'))}. Random category")
      draw_footer
      print "  Choice: "

      input = $stdin.gets.strip.downcase
      puts input
      return keys.sample   if input == 'r'
      return keys[input.to_i - 1] if (1..keys.length).include?(input.to_i)
      puts Color.red("  Invalid."); sleep 0.7
    end
  else
    return keys.sample
  end
end

# ── Difficulty Transition Prompts ──────────────────────────
def advance_preset_difficulty(state, difficulty_ref)
  settings = difficulty_preset_settings(state[:difficulty_preset])
  flags = state[:difficulty_prompt_flags] ||= {}
  round_number = state[:total_rounds]

  if settings[:automatic_transitions]
    if difficulty_ref[0] == :medium && round_number >= settings[:hard_at]
      difficulty_ref[0] = :hard
    end
    if difficulty_ref[0] == :hard && round_number >= settings[:extreme_at]
      difficulty_ref[0] = :extreme
    end
    return
  end

  if difficulty_ref[0] == :easy && round_number >= settings[:medium_at] && !flags[:medium]
    flags[:medium] = true
    difficulty_ref[0] = :medium if show_medium_prompt(settings[:medium_at] - 1)
  elsif difficulty_ref[0] == :medium && round_number >= settings[:hard_at] && !flags[:hard]
    flags[:hard] = true
    difficulty_ref[0] = :hard if show_hard_prompt(settings[:hard_at] - 1)
  elsif difficulty_ref[0] == :hard && round_number >= settings[:extreme_at] && !flags[:extreme]
    flags[:extreme] = true
    if settings[:extreme_optional]
      difficulty_ref[0] = :extreme if show_extreme_prompt(settings[:extreme_at] - 1)
    else
      difficulty_ref[0] = :extreme
    end
  end
end

def show_medium_prompt(completed_rounds = 8)
  clear
  draw_header("★ DIFFICULTY UNLOCKED ★")
  draw_divider
  puts box_line(Color.bold(Color.yellow("You've completed #{completed_rounds} rounds!")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("MEDIUM DIFFICULTY UNLOCKED")))
  draw_divider
  puts box_line("Difficulty Changes:")
  puts box_line(Color.cyan("  • Categories are now RANDOM"))
  puts box_line(Color.dim("  • Category is still shown (you can adapt your strategy)"))
  puts box_line(Color.dim("  • Word selection is completely unpredictable"))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Reward Multiplier: 1.5x points")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Switch to Medium difficulty now?")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("[Y]es - Switch Now   [N]o - Continue with Easy")))
  draw_footer
  print "  Choice: "
  input = $stdin.getch.downcase
  puts input
  return input == 'y'
end

def show_hard_prompt(completed_rounds = 15)
  clear
  draw_header("★ DIFFICULTY UNLOCKED ★")
  draw_divider
  puts box_line(Color.bold(Color.red("You've completed #{completed_rounds} rounds!")))
  draw_divider
  puts box_line(Color.bold(Color.red("HARD DIFFICULTY UNLOCKED")))
  draw_divider
  puts box_line("Difficulty Changes:")
  puts box_line(Color.red("  • Categories are now HIDDEN"))
  puts box_line(Color.dim("  • You won't know what type of word you're guessing"))
  puts box_line(Color.dim("  • Word length is still shown"))
  puts box_line(Color.dim("  • Pure guessing skill is required!"))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Reward Multiplier: 2.0x points")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Switch to Hard difficulty now?")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("[Y]es - Switch Now   [N]o - Continue with Medium")))
  draw_footer
  print "  Choice: "
  input = $stdin.getch.downcase
  puts input
  return input == 'y'
end

# ── Extreme Mode Disclaimer ───────────────────────────────
def show_extreme_prompt(completed_rounds = 25)
  loop do
    clear
    draw_header("UNLOCK EXTREME MODE")
    draw_divider
    puts box_line(Color.bold(Color.magenta("You have completed #{completed_rounds} rounds!")))
    draw_divider
    puts box_line(Color.bold(Color.yellow("EXTREME MODE UNLOCKED")))
    draw_divider
    puts box_line(Color.red("WARNING: EXTREME DIFFICULTY"))
    draw_divider
    puts box_line("Difficulty Modifiers:")
    puts box_line(Color.red("  * No category hints"))
    puts box_line(Color.red("  * Word length is hidden"))
    puts box_line(Color.red("  * Completely random selection"))
    puts box_line(Color.red("  * Maximum challenge!"))
    draw_divider
    puts box_line(Color.bold(Color.yellow("Reward Multiplier: 2.5x points")))
    draw_divider
    puts box_line(Color.bold(Color.yellow("Switch to Extreme difficulty now?")))
    draw_divider
    puts box_line(Color.bold(Color.yellow("[Y]es - Switch Now   [N]o - Continue with Hard")))
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input
    return input == 'y'
  end
end

# ── Difficulty Multiplier ────────────────────────────────────
def get_difficulty_multiplier(difficulty)
  case difficulty
  when :easy
    1.0
  when :medium
    1.5
  when :hard
    2.0
  when :extreme
    2.5
  else
    1.0
  end
end

# ── Difficulty Switcher Menu ──────────────────────────────
def open_difficulty_menu(state, difficulty_ref)
  loop do
    require_relative '../lib/color'
    require_relative '../lib/display'
    
    system('clear') || system('cls')
    
    puts ""
    draw_header("S E L E C T  D I F F I C U L T Y")
    puts ""
    
    settings = difficulty_preset_settings(state[:difficulty_preset])
    hardcore = state[:difficulty_preset] == :hardcore
    easy_unlocked = !hardcore
    medium_unlocked = state[:total_rounds] >= settings[:medium_at] || settings[:starting_difficulty] == :medium
    hard_unlocked = state[:total_rounds] >= settings[:hard_at]
    extreme_unlocked = state[:total_rounds] >= settings[:extreme_at]
    minimum_difficulty = if hardcore && state[:total_rounds] >= settings[:extreme_at]
      :extreme
    elsif hardcore && state[:total_rounds] >= settings[:hard_at]
      :hard
    elsif hardcore
      :medium
    else
      :easy
    end
    
    # Display difficulties
    current_marker = Color.green("▶")
    locked_marker = Color.dim("⊗")
    unlocked_marker = Color.yellow("○")
    
    easy_display = easy_unlocked ? (difficulty_ref[0] == :easy ? current_marker : unlocked_marker) : locked_marker
    easy_display += " #{Color.bold(Color.green('EASY'))}" + (easy_unlocked ? Color.dim(" - Base rewards") : Color.dim(" - Unavailable in Hardcore"))
    puts box_line(easy_display)
    
    if medium_unlocked
      medium_display = difficulty_ref[0] == :medium ? current_marker : unlocked_marker
      medium_display += " #{Color.bold(Color.yellow('MEDIUM'))}" + Color.dim(" - unlocks at round #{settings[:medium_at]}")
    else
      medium_display = locked_marker + " #{Color.dim('MEDIUM')}" + Color.dim(" (Unlock at round #{settings[:medium_at]})")
    end
    puts box_line(medium_display)
    
    if hard_unlocked
      hard_display = difficulty_ref[0] == :hard ? current_marker : unlocked_marker
      hard_display += " #{Color.bold(Color.red('HARD'))}" + Color.dim(" - unlocks at round #{settings[:hard_at]}")
    else
      hard_display = locked_marker + " #{Color.dim('HARD')}" + Color.dim(" (Unlock at round #{settings[:hard_at]})")
    end
    puts box_line(hard_display)
    
    if extreme_unlocked
      extreme_display = difficulty_ref[0] == :extreme ? current_marker : unlocked_marker
      extreme_display += " #{Color.bold(Color.magenta('EXTREME'))}" + Color.dim(settings[:extreme_optional] ? " - optional at round #{settings[:extreme_at]}" : " - enforced at round #{settings[:extreme_at]}")
    else
      extreme_display = locked_marker + " #{Color.dim('EXTREME')}" + Color.dim(" (Unlock at round #{settings[:extreme_at]})")
    end
    puts box_line(extreme_display)
    
    puts ""
    puts box_line("Choose difficulty: " + (easy_unlocked ? Color.bold(Color.yellow("[E]asy")) : Color.dim("[E]asy")) +
            (medium_unlocked && %i[easy medium].include?(minimum_difficulty) ? " #{Color.bold(Color.yellow('[M]edium'))}" : Color.dim(" [M]edium")) +
            (hard_unlocked && minimum_difficulty != :extreme ? " #{Color.bold(Color.yellow('[H]ard'))}" : Color.dim(" [H]ard")) +
                  (extreme_unlocked ? " #{Color.bold(Color.yellow('[X]treme'))}" : Color.dim(" [X]treme")) +
                  " or [B]ack")
    print "> "
    $stdout.flush
    input = gets.chomp.downcase
    
    case input
    when 'e'
      if easy_unlocked && minimum_difficulty == :easy
        difficulty_ref[0] = :easy
        puts Color.green("  Switched to Easy difficulty!")
        sleep 1
        break
      else
        puts Color.red("  Easy is unavailable with this preset.")
        sleep 1
      end
    when 'm'
      if medium_unlocked && %i[easy medium].include?(minimum_difficulty)
        difficulty_ref[0] = :medium
        puts Color.green("  Switched to Medium difficulty!")
        sleep 1
        break
      else
        puts Color.red("  Medium is unavailable at this stage of the preset.")
        sleep 1
      end
    when 'h'
      if hard_unlocked && minimum_difficulty != :extreme
        difficulty_ref[0] = :hard
        puts Color.green("  Switched to Hard difficulty!")
        sleep 1
        break
      else
        puts Color.red("  Hard is unavailable at this stage of the preset.")
        sleep 1
      end
    when 'x'
      if extreme_unlocked
        difficulty_ref[0] = :extreme
        puts Color.green("  Switched to Extreme difficulty!")
        sleep 1
        break
      else
        puts Color.red("  Extreme is not unlocked yet for this preset.")
        sleep 1
      end
    when 'b'
      break
    else
      puts Color.red("  Invalid choice.")
      sleep 0.7
    end
  end
end
