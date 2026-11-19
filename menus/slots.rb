# ── Slot Machine ─────────────────────────────────────────────
def spin_reel
  pool = SLOT_SYMBOLS.flat_map { |s| [s] * s[:weight] }
  pool.sample
end

def slot_spin_cost(state)
  spins = state[:slot_spins] || 0
  (10 * (1.10 ** spins)).ceil
end

def animate_slots(final_reels)
  # Build frame timings: fast at first, then slow down as reels "stop"
  # Total ~2.5 seconds across 14 frames
  timings = [0.08, 0.08, 0.08, 0.08, 0.10, 0.10, 0.12, 0.14, 0.16, 0.18, 0.22, 0.26, 0.30, 0.35]

  timings.each_with_index do |delay, frame|
    # In the last 3 frames, lock reels one by one left to right
    r1 = frame >= timings.length - 3 ? final_reels[0] : SLOT_SYMBOLS.sample
    r2 = frame >= timings.length - 2 ? final_reels[1] : SLOT_SYMBOLS.sample
    r3 = frame >= timings.length - 1 ? final_reels[2] : SLOT_SYMBOLS.sample

    label = frame >= timings.length - 1 ? "" : Color.dim("  spinning...")
    puts "  " + Color.cyan("| ") + [r1, r2, r3].map { |r| r[:display] }.join(Color.dim(" | ")) + Color.cyan(" |") + label
    sleep delay
    print "\e[1A\e[2K"
  end

  # Final locked result
  puts "  " + Color.cyan("| ") + final_reels.map { |r| r[:display] }.join(Color.dim(" | ")) + Color.cyan(" |")
end

def open_slot_machine(state)
  require_relative 'inventory'
  
  loop do
    clear
    draw_header("S L O T  M A C H I N E")
    spins_done = state[:slot_spins] || 0
    cost       = slot_spin_cost(state)
    next_cost  = (10 * (1.10 ** (spins_done + 1))).ceil

    puts box_line(Color.dim("Your points: ") + Color.bold(Color.yellow("#{state[:score]} pts")))
    puts box_line(Color.dim("Spins taken:  ") + Color.cyan("#{spins_done}"))
    draw_divider
    puts box_line(Color.bold(" [ ? ] [ ? ] [ ? ] "))
    draw_divider
    puts box_line("Match 3 symbols to win a " + Color.bold(Color.magenta("Skill Card")) + "!")
    puts box_line(Color.dim("  Win chance: ") + Color.green("33%") + Color.dim("  |  Nothing: ") + Color.red("67%"))
    draw_divider

    can_afford = state[:score] >= cost
    cost_str   = can_afford ? Color.green("#{cost} pts") : Color.red("#{cost} pts (too poor)")
    puts box_line("#{Color.bold(Color.yellow('[S]'))} Spin!  Cost: #{cost_str}")
    puts box_line(Color.dim("    Next spin will cost: #{next_cost} pts"))
    draw_divider
    puts box_line("#{Color.bold(Color.yellow('[X]'))} Leave")
    draw_footer
    print "  Choice: "

    ch = $stdin.getch.downcase
    puts ch

    case ch
    when 'x'
      break

    when 's'
      unless state[:score] >= cost
        puts Color.red("  Not enough points!"); sleep 1; next
      end

      state[:score]      -= cost
      state[:slot_spins]  = spins_done + 1

      # Determine outcome: 33% win (3-of-a-kind), 67% lose
      win = rand < 0.33

      if win
        # Pick one symbol, fill all 3 reels with it
        sym     = SLOT_SYMBOLS.sample
        reels   = [sym, sym, sym]
      else
        # Guarantee NO three-of-a-kind by always making reel 3 differ
        r1 = spin_reel
        r2 = spin_reel
        # Keep rerolling r3 until it doesn't complete a triple
        r3 = spin_reel
        r3 = spin_reel while r3[:name] == r1[:name] && r3[:name] == r2[:name]
        reels = [r1, r2, r3]
      end

      clear
      draw_header("S L O T  M A C H I N E")
      puts box_line(Color.dim("Spinning..."))
      draw_divider
      puts ""   # blank line for animation space
      animate_slots(reels)
      puts ""
      draw_divider

      if win
        sym_display = reels[0][:display].strip
        puts box_line(Color.bold(Color.green("★ THREE #{sym_display}s! YOU WIN! ★")))
        puts box_line(Color.bold(Color.magenta("You earned a Skill Card!")))
        draw_footer
        sleep 1.5

        # Award one skill card using existing rarity roll — handle duplicates
        awarded = roll_skill_cards(1, reels[0][:weight]).first
        key, card = awarded

        if already_owns?(state, card)
          if stackable_card?(card)
            apply_skill_card(state, card, stack_boost: true)
            clear
            draw_header("★ SKILL CARD AWARDED ★")
            draw_divider
            puts box_line(rarity_name_colored(card[:rarity]) + " — " + Color.bold(card[:name]))
            puts box_line("  " + Color.dim(card[:description]))
            draw_divider
            puts box_line(Color.bold(Color.yellow("You already own this! Stats boosted +15%")))
            draw_divider
            puts box_line(Color.dim("Press any key to continue..."))
            draw_footer
            $stdin.getch
          else
            # Non-stackable duplicate — reroll until something useful
            10.times do
              awarded = roll_skill_cards(1, reels[0][:weight]).first
              key, card = awarded
              break unless already_owns?(state, card) && !stackable_card?(card)
            end
            apply_skill_card(state, card, stack_boost: already_owns?(state, card) && stackable_card?(card))
            clear
            draw_header("★ SKILL CARD AWARDED ★")
            draw_divider
            puts box_line(Color.dim("(Duplicate rerolled)"))
            puts box_line(rarity_name_colored(card[:rarity]) + " — " + Color.bold(card[:name]))
            puts box_line("  " + Color.dim(card[:description]))
            draw_divider
            puts box_line(Color.dim("Press any key to continue..."))
            draw_footer
            $stdin.getch
          end
        else
          apply_skill_card(state, card)
          clear
          draw_header("★ SKILL CARD AWARDED ★")
          draw_divider
          puts box_line(rarity_name_colored(card[:rarity]) + " — " + Color.bold(card[:name]))
          puts box_line("  " + Color.dim(card[:description]))
          draw_divider
          puts box_line(Color.dim("Press any key to continue..."))
          draw_footer
          $stdin.getch
        end

        # Check for Gold Card
        if owns_all_cards?(state) && !(state[:active_skills] || []).any? { |c| c[:rarity] == :gold }
          sleep 0.5
          award_gold_card(state)
        end
      else
        names = reels.map { |r| r[:display] }.join(Color.dim("  "))
        puts box_line(Color.red("No match.") + Color.dim("  #{names}"))
        puts box_line(Color.dim("Better luck next time!"))
        draw_footer
        sleep 1.2
      end

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end
