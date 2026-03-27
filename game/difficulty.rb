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
def show_medium_prompt
  clear
  draw_header("★ DIFFICULTY INCREASED ★")
  draw_divider
  puts box_line(Color.bold(Color.yellow("You've completed 8 rounds!")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("MEDIUM DIFFICULTY UNLOCKED")))
  draw_divider
  puts box_line("Difficulty Changes:")
  puts box_line(Color.cyan("  • Categories are now RANDOM"))
  puts box_line(Color.dim("  • Category is still shown (you can adapt your strategy)"))
  puts box_line(Color.dim("  • Word selection is completely unpredictable"))
  draw_divider
  puts box_line(Color.dim("Prepare yourself for varied challenges!"))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Press Enter to continue...")))
  draw_footer
  $stdin.gets
end

def show_hard_prompt
  clear
  draw_header("★ EXTREME DIFFICULTY UNLOCKED ★")
  draw_divider
  puts box_line(Color.bold(Color.red("You've completed 15 rounds!")))
  draw_divider
  puts box_line(Color.bold(Color.red("HARD DIFFICULTY UNLOCKED")))
  draw_divider
  puts box_line("Difficulty Changes:")
  puts box_line(Color.red("  • Categories are now HIDDEN"))
  puts box_line(Color.dim("  • You won't know what type of word you're guessing"))
  puts box_line(Color.dim("  • Word length is still shown"))
  puts box_line(Color.dim("  • Pure guessing skill is required!"))
  draw_divider
  puts box_line(Color.yellow("This is a significant jump in difficulty. Stay sharp!"))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Press Enter to continue...")))
  draw_footer
  $stdin.gets
end

# ── Extreme Mode Disclaimer ───────────────────────────────
def show_extreme_prompt
  loop do
    clear
    draw_header("UNLOCK EXTREME MODE")
    draw_divider
    puts box_line(Color.bold(Color.magenta("You have completed 25 rounds!")))
    draw_divider
    puts box_line(Color.bold(Color.yellow("EXTREME MODE DISCLAIMER")))
    draw_divider
    puts box_line(Color.red("WARNING: EXTREME DIFFICULTY"))
    draw_divider
    puts box_line("Difficulty Modifiers:")
    puts box_line(Color.red("  * No category hints"))
    puts box_line(Color.red("  * Word length is hidden"))
    puts box_line(Color.red("  * Completely random selection"))
    puts box_line(Color.red("  * Maximum challenge!"))
    draw_divider
    puts box_line("Continue in HARD mode or unlock EXTREME?")
    draw_divider
    puts box_line(Color.bold(Color.yellow("[H] Hard Mode   [E] Extreme Mode")))
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input
    return :hard if input == 'h'
    return :extreme if input == 'e'
    puts Color.red("  Invalid choice!"); sleep 0.7
  end
end
