# ── Dev Passcode ──────────────────────────────────────────
def dev_passcode_prompt
  clear
  puts Color.bold(Color.red("  ╔══════════════════════════════════════════════════╗"))
  puts Color.bold(Color.red("  ║          ⚠  D E V   A C C E S S  ⚠             ║"))
  puts Color.bold(Color.red("  ╚══════════════════════════════════════════════════╝"))
  puts
  puts Color.dim("  Enter passcode (Enter to confirm, Esc to cancel):")
  print "  > "

  input = ""
  loop do
    ch = $stdin.getch
    case ch
    when "\r", "\n"   # Enter — confirm
      puts
      break
    when "\e"         # Escape — cancel
      puts
      return false
    when "\u007F", "\b"  # Backspace
      unless input.empty?
        input = input[0..-2]
        print "\b \b"
      end
    else
      input += ch
      print "*"   # mask input
    end
  end

  if input == DEV_PASSCODE
    true
  else
    puts Color.red("  Incorrect passcode.")
    sleep 1
    false
  end
end

# ── Dev Menu ──────────────────────────────────────────────────
def open_dev_menu(state, difficulty_ref)
  require_relative 'inventory'
  require_relative 'slots'
  
  loop do
    clear
    puts Color.bold(Color.red("  ╔══════════════════════════════════════════════════╗"))
    puts Color.bold(Color.red("  ║          ⚠  D E V   M E N U  ⚠                 ║"))
    puts Color.bold(Color.red("  ╚══════════════════════════════════════════════════╝"))
    puts

    # Current state snapshot
    puts Color.bold(Color.white("  ── State ──────────────────────────────────────────"))
    puts "  " + Color.dim("Score:       ") + Color.bold(Color.yellow("#{state[:score]} pts"))
    puts "  " + Color.dim("Wins/Losses: ") + Color.green("#{state[:wins]}W") + Color.dim(" / ") + Color.red("#{state[:losses]}L")
    puts "  " + Color.dim("Streak:      ") + Color.cyan("#{state[:streak]}x")
    puts "  " + Color.dim("Difficulty:  ") + Color.magenta(difficulty_ref[0].to_s.upcase)
    puts "  " + Color.dim("Rounds:      ") + "#{state[:total_rounds]}"
    puts "  " + Color.dim("Cards:       ") + "#{((state[:skill_cards]||[]) + (state[:active_skills]||[])).length} collected"
    puts

    puts Color.bold(Color.white("  ── Points ─────────────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[1]")) + " Add 100 pts"
    puts "  " + Color.bold(Color.yellow("[2]")) + " Add 1000 pts"
    puts "  " + Color.bold(Color.yellow("[3]")) + " Add 10000 pts"
    puts "  " + Color.bold(Color.yellow("[4]")) + " Wipe points to 0"
    puts

    puts Color.bold(Color.white("  ── Cards & Events ─────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[5]")) + " Trigger skill card selection"
    puts "  " + Color.bold(Color.yellow("[6]")) + " Trigger slot machine"
    puts "  " + Color.bold(Color.yellow("[7]")) + " Give one random card (instant)"
    puts "  " + Color.bold(Color.yellow("[G]")) + " Give ALL cards (skips owned)"
    puts "  " + Color.bold(Color.yellow("[8]")) + " Wipe all cards"
    puts "  " + Color.bold(Color.yellow("[9]")) + " Force Gold Card ceremony"
    puts

    puts Color.bold(Color.white("  ── Difficulty ──────────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[E]")) + " Set Easy"
    puts "  " + Color.bold(Color.yellow("[M]")) + " Set Medium"
    puts "  " + Color.bold(Color.yellow("[H]")) + " Set Hard"
    puts "  " + Color.bold(Color.yellow("[X]")) + " Set Extreme"
    puts

    puts Color.bold(Color.white("  ── Progress ────────────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[W]")) + " Add 5 wins (triggers card roll if at milestone)"
    puts "  " + Color.bold(Color.yellow("[R]")) + " Reset all state"
    puts
    puts "  " + Color.bold(Color.yellow("[0]")) + " Close dev menu"
    puts

    print Color.red("  DEV> ")
    ch = $stdin.getch.downcase
    puts ch

    case ch
    when '1' then state[:score] += 100;   puts Color.green("  +100 pts"); sleep 0.6
    when '2' then state[:score] += 1000;  puts Color.green("  +1000 pts"); sleep 0.6
    when '3' then state[:score] += 10000; puts Color.green("  +10000 pts"); sleep 0.6
    when '4' then state[:score] = 0;      puts Color.red("  Points wiped"); sleep 0.6

    when '5'
      skill_card_selection_menu(state)

    when '6'
      open_slot_machine(state)

    when '7'
      _, card = roll_skill_cards(1).first
      is_dup  = already_owns?(state, card)
      apply_skill_card(state, card, stack_boost: is_dup && stackable_card?(card))
      tag = is_dup ? " (+15% boost, duplicate)" : ""
      puts Color.green("  Gave: #{card[:name]} [#{card[:rarity]}]#{tag}")
      sleep 1.2

    when 'g'
      given  = 0
      skipped = 0
      SKILL_CARDS.each_value do |card|
        if already_owns?(state, card)
          skipped += 1
        else
          apply_skill_card(state, card)
          given += 1
        end
      end
      puts Color.green("  Gave #{given} new card#{"s" if given != 1}.")
      puts Color.dim("  Skipped #{skipped} already owned.") if skipped > 0
      sleep 1.2

    when '8'
      state[:skill_cards]  = []
      state[:active_skills] = []
      state[:card_counts]  = {}
      state[:permanent_bonuses].delete(:bonus_multiplier)
      state[:permanent_bonuses].delete(:double_multiplier)
      state[:permanent_bonuses].delete(:gold_card)
      puts Color.red("  All cards wiped"); sleep 0.7

    when '9'
      award_gold_card(state)

    when 'e' then difficulty_ref[0] = :easy;    puts Color.green("  Difficulty → EASY"); sleep 0.6
    when 'm' then difficulty_ref[0] = :medium;  puts Color.green("  Difficulty → MEDIUM"); sleep 0.6
    when 'h' then difficulty_ref[0] = :hard;    puts Color.green("  Difficulty → HARD"); sleep 0.6
    when 'x' then difficulty_ref[0] = :extreme; puts Color.green("  Difficulty → EXTREME"); sleep 0.6

    when 'w'
      state[:wins] += 5
      puts Color.green("  +5 wins (total: #{state[:wins]})")
      sleep 0.5
      if state[:wins] % 5 == 0
        puts Color.cyan("  Triggering card roll...")
        sleep 0.6
        skill_card_selection_menu(state)
      end

    when 'r'
      state[:score]            = 0
      state[:wins]             = 0
      state[:losses]           = 0
      state[:streak]           = 1
      state[:peak_streak]      = 1
      state[:total_rounds]     = 0
      state[:inventory]        = {}
      state[:permanent_bonuses] = {}
      state[:temp_multiplier]  = nil
      state[:pending_extra_lives] = 0
      state[:skill_cards]      = []
      state[:active_skills]    = []
      state[:card_counts]      = {}
      difficulty_ref[0]        = :easy
      puts Color.red("  Full state reset"); sleep 0.8

    when '0' then return
    else puts Color.red("  Unknown command"); sleep 0.5
    end
  end
end
