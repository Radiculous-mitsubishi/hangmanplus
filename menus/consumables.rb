# ── Consumable Menu ──────────────────────────────────────────
def consumable_menu(word, guessed, state, max_wrong_ref, safety_armed)
  loop do
    clear
    draw_header("C O N S U M A B L E S")
    draw_divider

    inv = state[:inventory]

    puts box_line(Color.dim("Select a consumable to use:"))
    draw_divider

    if (inv[:reveal_letter] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('R'))}. [?] Reveal a Letter (#{inv[:reveal_letter]}x)")
    else
      puts box_line("#{Color.dim('R')}. [?] Reveal a Letter #{Color.dim('(unavailable)')}")
    end

    if (inv[:extra_life] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('E'))}. [+] Extra Life (#{inv[:extra_life]}x)")
    else
      puts box_line("#{Color.dim('E')}. [+] Extra Life #{Color.dim('(unavailable)')}")
    end

    if (inv[:double_down] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('D'))}. [x2] Double Down (#{inv[:double_down]}x)")
    else
      puts box_line("#{Color.dim('D')}. [x2] Double Down #{Color.dim('(unavailable)')}")
    end

    if (inv[:safety_net] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('S'))}. [S] Safety Net (#{inv[:safety_net]}x)")
    else
      puts box_line("#{Color.dim('S')}. [S] Safety Net #{Color.dim('(unavailable)')}")
    end

    draw_divider
    puts box_line("#{Color.bold(Color.yellow('B'))}. Back to game")
    draw_footer
    print "  Choice: "

    ch = $stdin.getch.downcase
    puts ch

    case ch
    when 'r'
      if (inv[:reveal_letter] || 0) > 0
        use_reveal_letter(word, guessed, inv)
        return
      else
        puts Color.red("  You don't have any Reveal consumables!"); sleep 1
      end

    when 'e'
      if (inv[:extra_life] || 0) > 0
        use_extra_life(state, max_wrong_ref, inv)
        return
      else
        puts Color.red("  You don't have any Extra Life consumables!"); sleep 1
      end

    when 'd'
      if (inv[:double_down] || 0) > 0
        use_double_down(state, inv)
        return
      else
        puts Color.red("  You don't have any Double Down consumables!"); sleep 1
      end

    when 's'
      if (inv[:safety_net] || 0) > 0
        use_safety_net(state, safety_armed, inv)
        return
      else
        puts Color.red("  You don't have any Safety Net consumables!"); sleep 1
      end

    when 'b'
      return

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

# ── Individual consumable functions ──────────────────────────
def use_reveal_letter(word, guessed, inv)
  hidden = word.chars.uniq.reject { |c| guessed.include?(c) }
  if hidden.empty?
    puts Color.yellow("  No hidden letters left!")
    sleep 1
    return
  end
  revealed = hidden.sample
  guessed << revealed
  inv[:reveal_letter] -= 1
  puts Color.green("  [?] Revealed: '#{revealed.upcase}'!")
  sleep 1
end

def use_extra_life(state, max_wrong_ref, inv)
  if (inv[:extra_life] || 0) > 0
    max_wrong_ref[0] += 1
    inv[:extra_life] -= 1
    puts Color.green("  [+] Extra life! You can now miss #{max_wrong_ref[0]} times.")
    sleep 1
  else
    puts Color.red("  [+] You don't have any Extra Life consumables!")
    sleep 1
  end
end

def use_double_down(state, inv)
  state[:temp_multiplier] = ((state[:temp_multiplier] || 1) * 2)
  inv[:double_down] -= 1
  puts Color.green("  [x2] Streak doubled for this round!")
  sleep 1
end

def use_safety_net(state, safety_armed, inv)
  if safety_armed[0]
    puts Color.yellow("  Safety Net is already armed!")
    sleep 1
    return
  end
  safety_armed[0] = true
  inv[:safety_net] -= 1
  puts Color.green("  [S] Safety Net armed! Your next wrong guess won't count.")
  sleep 1
end
