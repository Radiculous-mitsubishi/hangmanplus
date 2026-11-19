# ── Utilities ────────────────────────────────────────────────
def clear = print("\e[2J\e[H")

BOX_WIDTH = 60

def strip_color(s)
  s.gsub(/\e\[[0-9;]*m/, '')
end

def box_line(content)
  inner_len = strip_color(content).length
  padding   = [BOX_WIDTH - 4 - inner_len, 0].max
  Color.cyan("  |") + " #{content}#{' ' * padding} " + Color.cyan("|")
end

def draw_header(title)
  inner_w = 52
  sparkles = ["✦", "★", "◆"]
  sp_l = sparkles.sample
  sp_r = sparkles.sample
  
  # Build the middle line with proper padding to match border width
  # Total content area is 52 characters
  left_pad = [(inner_w - title.length) / 2, 0].max
  right_pad = inner_w - title.length - left_pad
  
  puts Color.bold(Color.cyan("  ╔" + "═" * inner_w + "╗"))
  puts Color.bold(Color.cyan("  ║")) + " " * left_pad + Color.bold(Color.white(title)) + " " * right_pad + Color.bold(Color.cyan("║"))
  puts Color.bold(Color.cyan("  ╚" + "═" * inner_w + "╝"))
end

def draw_divider
  puts Color.cyan("  " + "─" * 56)
end

def draw_footer
  puts Color.cyan("  " + "─" * 56)
end

def center_text(text, width = BOX_WIDTH)
  stripped = strip_color(text)
  pad = [(width - stripped.length) / 2, 0].max
  " " * pad + text
end

def rarity_color(rarity)
  case rarity
  when :common then Color.white("●")
  when :rare then Color.cyan("●")
  when :ultra_rare then Color.magenta("●")
  when :legendary then Color.yellow("●")
  when :mythic then Color.red("●")
  when :gold   then Color.bold(Color.yellow("✦"))
  else "●"
  end
end

def rarity_name_colored(rarity)
  case rarity
  when :common then Color.white("COMMON")
  when :rare then Color.cyan("RARE")
  when :ultra_rare then Color.magenta("ULTRA RARE")
  when :legendary then Color.yellow("LEGENDARY")
  when :mythic then Color.red("MYTHIC")
  when :gold    then Color.bold(Color.yellow("✦ GOLD ✦"))
  else "UNKNOWN"
  end
end

# ── HUD ──────────────────────────────────────────────────────
def draw_hud(state)
  bonus = state[:permanent_bonuses][:bonus_point] || 0
  base  = 1 + bonus
  mult  = state[:streak]
  tmult = state[:temp_multiplier] || 1
  eff   = mult * tmult

  score_str  = Color.bold(Color.yellow("#{state[:score]} pts"))
  streak_str = eff > 1 ? Color.bold(Color.cyan("#{eff}x STREAK!")) : Color.dim("1x")
  base_str   = Color.dim("next correct = +#{base * eff}pts")
  inv_str    = inventory_summary(state[:inventory])
  wins_str   = Color.dim("W:#{state[:wins]}/5")
  lifetime_points = get_lifetime_points(state[:username])
  preset = difficulty_preset_settings(state[:difficulty_preset])

  preset_label = Color.dim("Mode: ") + Color.bold(Color.magenta(preset[:name]))
  puts box_line(Color.dim("Score: ") + score_str + "   " + streak_str + "  " + base_str + "  " + wins_str + "   " + preset_label)
  puts box_line(Color.dim("Lifetime points: ") + Color.bold(Color.cyan("#{lifetime_points} pts")))
  if state[:round_deadline]
    seconds_left = [(state[:round_deadline] - Process.clock_gettime(Process::CLOCK_MONOTONIC)).ceil, 0].max
    timer_color = seconds_left <= 10 ? Color.red("#{seconds_left}s") : Color.yellow("#{seconds_left}s")
    puts box_line(Color.bold(Color.red("TIME LEFT: ")) + timer_color)
  end
  unless inv_str.empty?
    puts box_line(Color.dim("Inventory: ") + Color.cyan(inv_str))
  end
  draw_divider
end

def inventory_summary(inv)
  labels = { reveal_letter: "[?]Reveal", extra_life: "[+]Life", double_down: "[x2]Double", safety_net: "[]Shield" }
  parts  = []
  labels.each do |id, label|
    qty = inv[id] || 0
    parts << "#{label}x#{qty}" if qty > 0
  end
  parts.join("  ")
end

# ── Hangman art ───────────────────────────────────────────────
def draw_hangman(wrong_count, max_wrong)
  art_color = wrong_count <= max_wrong / 3 ? :green : (wrong_count <= max_wrong * 2 / 3 ? :yellow : :red)
  # Extra-life upgrades can allow more misses than there are art stages.
  stage = [[wrong_count, 0].max, HANGMAN.length - 1].min
  HANGMAN[stage].each_line do |line|
    puts box_line(Color.send(art_color, line.rstrip))
  end
end

# ── Main game screen ──────────────────────────────────────────
def draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong, difficulty = :easy)
  clear
  draw_header("H  A  N  G  M  A  N")
  draw_hud(state)
  draw_hangman(wrong_count, max_wrong)
  draw_divider

  difficulty_colors = { easy: Color.green("EASY"), medium: Color.yellow("MEDIUM"), hard: Color.red("HARD"), extreme: Color.magenta("EXTREME") }
  diff_display = difficulty_colors[difficulty] || "UNKNOWN"
  round_display = Color.dim("Round: ") + Color.bold(Color.cyan("#{state[:total_rounds]}"))
  puts box_line(diff_display + Color.dim(" | ") + round_display)

  if difficulty == :easy || difficulty == :medium
    puts box_line(Color.dim("Category: ") + Color.bold(Color.magenta(category)))
  elsif difficulty == :hard
    puts box_line(Color.dim("Category: ") + Color.dim("[Hidden]"))
  else
    puts box_line(Color.dim("Category: ") + Color.red("[Hidden]") + Color.dim(" | Length: ") + Color.red("[Hidden]"))
  end

  if difficulty == :extreme
    display = word.chars.map { |c|
      guessed.include?(c) ? Color.bold(Color.green(" #{c} ")) : Color.red("[?]")
    }.join
  else
    display = word.chars.map { |c|
      guessed.include?(c) ? Color.bold(Color.green(" #{c} ")) : Color.dim(" _ ")
    }.join
  end
  puts box_line(display)

  if wrong_letters.empty?
    puts box_line(Color.dim("No wrong guesses yet"))
  else
    puts box_line(Color.dim("Wrong: ") + wrong_letters.sort.map { |l| Color.red(l.upcase) }.join("  "))
  end

  remaining = max_wrong - wrong_count
  hearts = (Color.green("<3 ") * remaining).rstrip
  skulls = (Color.red("X ") * wrong_count).rstrip
  puts box_line(hearts + (wrong_count > 0 ? "  " + skulls : ""))

  draw_divider
  puts box_line(Color.dim("Press ") + Color.bold(Color.yellow("+")) + Color.dim(" to open consumables menu"))
  draw_footer
  print "  Guess a letter: "
end
