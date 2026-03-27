# ── Skill Card Rolling System ────────────────────────────────
def roll_skill_cards(num_rolls = 3)
  # Define rarity weights
  rarities = []
  100.times do |i|
    case i
    when 0..49 then rarities << :common
    when 50..74 then rarities << :rare
    when 75..89 then rarities << :ultra_rare
    when 90..98 then rarities << :legendary
    when 99 then rarities << :mythic
    end
  end

  cards = []
  num_rolls.times do
    rarity = rarities.sample
    card_keys = SKILL_CARDS.select { |_, v| v[:rarity] == rarity }.keys
    card_key = card_keys.sample
    cards << [card_key, SKILL_CARDS[card_key]]
  end
  cards
end

def skill_card_selection_menu(state)
  reroll_count     = 0
  base_reroll_cost = 20
  cards            = nil
  should_reroll    = true  # Start with true to roll cards on first iteration

  loop do
    # Check for Gold Card condition first
    if owns_all_cards?(state) && !(state[:active_skills] || []).any? { |c| c[:rarity] == :gold }
      award_gold_card(state)
      return
    end

    # Only roll cards when a reroll is successfully triggered
    if should_reroll
      cards = roll_skill_cards(3)
      should_reroll = false
    end

    # Annotate each card with its duplicate status
    card_status = cards.map do |(key, card)|
      if already_owns?(state, card)
        status = stackable_card?(card) ? :stack : :reject
      else
        status = :new
      end
      [key, card, status]
    end

    clear
    draw_header("S K I L L  C A R D  R O L L")
    puts Color.dim("  " + "─" * 56)
    puts "  " + Color.bold(Color.yellow("You've won 5 rounds! Choose a skill card:"))
    draw_divider

    card_status.each_with_index do |(key, card, status), idx|
      rarity_label = rarity_name_colored(card[:rarity])
      status_tag = case status
        when :new    then ""
        when :stack  then Color.bold(Color.green(" [+15% BOOST]"))
        when :reject then Color.bold(Color.red(" [OWNED — auto-reroll if picked]"))
        end
      puts "  #{Color.bold(Color.yellow((idx+1).to_s))}. #{rarity_label} - #{Color.bold(card[:name])}#{status_tag}"
      puts "     #{Color.dim(card[:description])}"
    end

    puts ""
    draw_divider
    if reroll_count == 0
      puts "  #{Color.bold(Color.yellow('R'))}. Reroll cards #{Color.dim('(FREE - 1 per card select)')}"
    else
      reroll_cost = (base_reroll_cost * ((1.075) ** reroll_count)).round
      can_afford  = state[:score] >= reroll_cost
      cost_color  = can_afford ? Color.green("#{reroll_cost}pts") : Color.red("#{reroll_cost}pts")
      puts "  #{Color.bold(Color.yellow('R'))}. Reroll cards #{cost_color}"
    end
    puts "  #{Color.bold(Color.yellow('S'))}. Skip (no reward)"
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input

    case input
    when '1', '2', '3'
      idx         = input.to_i - 1
      key, card, status = card_status[idx]

      case status
      when :new
        apply_skill_card(state, card)
        puts Color.green("\n  ✓ Card acquired: #{card[:name]}!")

      when :stack
        apply_skill_card(state, card, stack_boost: true)
        puts Color.bold(Color.green("\n  ✦ Duplicate! #{card[:name]} boosted +15%!"))

      when :reject
        # Auto-reroll this slot until we get something non-rejected
        puts Color.yellow("\n  Already owned and non-stackable — rerolling...")
        sleep 0.6
        replacement_card = nil
        15.times do
          _, rc = roll_skill_cards(1).first
          next if already_owns?(state, rc) && !stackable_card?(rc)
          replacement_card = rc
          break
        end
        if replacement_card
          is_dup = already_owns?(state, replacement_card)
          apply_skill_card(state, replacement_card, stack_boost: is_dup && stackable_card?(replacement_card))
          tag = is_dup ? Color.bold(Color.green(" (+15% boost)")) : ""
          puts Color.cyan("  → Got: #{rarity_name_colored(replacement_card[:rarity])} #{replacement_card[:name]}#{tag}")
        else
          puts Color.dim("  → No alternatives found. Skipping.")
        end
      end

      sleep 1.5

      # Check Gold Card after every acquisition
      if owns_all_cards?(state) && !(state[:active_skills] || []).any? { |c| c[:rarity] == :gold }
        sleep 0.5
        award_gold_card(state)
      end
      return

    when 'r'
      if reroll_count == 0
        reroll_count += 1
        should_reroll = true
        puts Color.cyan("  [FREE] Rerolling cards..."); sleep 0.8
      else
        reroll_cost = (base_reroll_cost * ((1.075) ** reroll_count)).round
        if state[:score] < reroll_cost
          puts Color.red("  Not enough points! Need #{reroll_cost}pts, have #{state[:score]}pts"); sleep 1
        else
          state[:score] -= reroll_cost
          reroll_count  += 1
          should_reroll = true
          puts Color.green("  [-#{reroll_cost}pts] Rerolling cards..."); sleep 0.8
        end
      end

    when 's'
      puts Color.yellow("\n  Skipped reward."); sleep 1; return

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

# ── Skill Card Helpers ───────────────────────────────────────
def stackable_card?(card)
  return true if card[:type] == :item_upgrade && STACKABLE_TARGETS.include?(card[:target])
  return true if card[:type] == :unique_skill && card[:effect].keys.any? { |k| STACKABLE_UNIQUE_EFFECTS.include?(k) }
  false
end

def already_owns?(state, card)
  all = (state[:skill_cards] || []) + (state[:active_skills] || [])
  all.any? { |c| c[:name] == card[:name] }
end

def owns_all_cards?(state)
  all_names = SKILL_CARDS.values.map { |c| c[:name] }.to_set
  owned     = ((state[:skill_cards] || []) + (state[:active_skills] || [])).map { |c| c[:name] }.to_set
  all_names.subset?(owned)
end

def apply_skill_card(state, card, stack_boost: false)
  boost = stack_boost ? 1.15 : 1.0

  # Always track copy count — increment if already owned, set to 1 if new
  state[:card_counts] ||= {}
  state[:card_counts][card[:name]] = (state[:card_counts][card[:name]] || 0) + 1

  if card[:type] == :item_upgrade
    state[:skill_cards] ||= []
    # Only add to collection list if first copy
    state[:skill_cards] << card if state[:card_counts][card[:name]] == 1

    case card[:target]
    when :bonus_point
      state[:permanent_bonuses][:bonus_multiplier] =
        (state[:permanent_bonuses][:bonus_multiplier] || 1.0) * (card[:effect][:bonus_multiplier] * boost)
      state[:permanent_bonuses][:bonus_point_no_cap] = true if card[:effect][:no_cap]
    when :double_down
      current = state[:permanent_bonuses][:double_multiplier] || card[:effect][:multiplier_boost]
      state[:permanent_bonuses][:double_multiplier] = (current * boost).round(2)
    when :reveal_letter
      state[:inventory][:reveal_letter] = (state[:inventory][:reveal_letter] || 0) + card[:effect][:usage_bonus]
    when :safety_net
      state[:permanent_bonuses][:safety_durability] = card[:effect][:durability]
    when :extra_life
      state[:permanent_bonuses][:extra_life_grant] = card[:effect][:life_grant]
    end

  elsif card[:type] == :unique_skill
    state[:active_skills] ||= []
    # Only add to collection list if first copy
    state[:active_skills] << card if state[:card_counts][card[:name]] == 1

    if stack_boost
      existing = state[:active_skills].find { |c| c[:name] == card[:name] }
      if existing
        card[:effect].each do |k, v|
          existing[:effect][k] = (v * boost).round(3) if v.is_a?(Numeric)
        end
      end
    end

  elsif card[:rarity] == :gold
    state[:active_skills] ||= []
    state[:active_skills] << card unless state[:active_skills].any? { |c| c[:rarity] == :gold }
    state[:permanent_bonuses][:gold_card] = true
  end
end

def award_gold_card(state)
  apply_skill_card(state, GOLD_CARD)
  clear
  # Dramatic full-screen reveal
  6.times do |i|
    clear
    sparkle = [" ✦ ", " ★ ", " ◆ ", " ★ ", " ✦ ", " · "][i % 6]
    border  = Color.bold(Color.yellow("  ╔" + "═" * 52 + "╗"))
    puts "\n\n\n"
    puts border
    puts Color.bold(Color.yellow("  ║")) + "  " * 26 + Color.bold(Color.yellow("║"))
    title = "#{sparkle}  T H E   G O L D   C A R D  #{sparkle}"
    t_pad = [(52 - title.length) / 2, 0].max
    puts Color.bold(Color.yellow("  ║")) + " " * t_pad + Color.bold(Color.white(title)) + " " * [52 - title.length - t_pad, 0].max + Color.bold(Color.yellow("║"))
    puts Color.bold(Color.yellow("  ║")) + "  " * 26 + Color.bold(Color.yellow("║"))
    puts Color.bold(Color.yellow("  ╚" + "═" * 52 + "╝"))
    sleep 0.25
  end
  puts
  puts Color.bold(Color.yellow("  ╔" + "═" * 52 + "╗"))
  puts Color.bold(Color.yellow("  ║")) + Color.bold(Color.white("  ✦  T H E   G O L D   C A R D  ✦               ")) + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ╠" + "═" * 52 + "╣"))
  puts Color.bold(Color.yellow("  ║")) + Color.bold(Color.yellow("  You have collected every skill card!          ")) + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ╠" + "═" * 52 + "╣"))
  puts Color.bold(Color.yellow("  ║")) + Color.white("  All point gains are permanently doubled.       ") + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ║")) + Color.dim("  This bonus stacks with all other effects.      ") + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ╚" + "═" * 52 + "╝"))
  puts
  puts Color.dim("  Press any key to continue...")
  $stdin.getch
end

# ══════════════════════════════════════════════════════════════
#  C A R D   I N V E N T O R Y   S Y S T E M
# ══════════════════════════════════════════════════════════════

def card_color(rarity, text)
  cfg = RARITY_CFG[rarity] || RARITY_CFG[:common]
  Color.send(cfg[:color], text)
end

def word_wrap(text, width)
  lines = []; cur = ""
  text.split.each do |w|
    test = cur.empty? ? w : "#{cur} #{w}"
    if test.length <= width then cur = test
    else lines << cur; cur = w end
  end
  lines << cur unless cur.empty?
  lines
end

def card_border(cfg, frame, top)
  c  = cfg[:color]
  tl = top ? cfg[:tl] : cfg[:bl]
  tr = top ? cfg[:tr] : cfg[:br]
  h  = cfg[:h]
  w  = CARD_W + 2
  inner = case cfg[:anim]
  when :ripple  then (0...w).map { |i| ((i + frame * 2) % (w * 2)) < w / 2 ? "~" : h }.join
  when :shine   then pos = (frame * 3) % w; (0...w).map { |i| (i - pos).abs <= 1 ? "=" : h }.join
  when :glimmer then (0...w).map { rand < 0.12 ? "*" : h }.join
  else h * w
  end
  bold = cfg[:bold_border] || (cfg[:anim] == :pulse && frame.even?)
  s = tl + inner + tr
  bold ? Color.bold(Color.send(c, s)) : Color.send(c, s)
end

def card_row(cfg, content_ansi, content_len, _frame)
  c   = cfg[:color]
  v   = cfg[:v]
  w   = CARD_W + 2
  pad = [w - content_len, 0].max
  lp  = pad / 2; rp = pad - lp
  Color.bold(Color.send(c, v)) + " " * lp + content_ansi + " " * rp + Color.bold(Color.send(c, v))
end

def card_sep(cfg)
  c = cfg[:color]
  Color.bold(Color.send(c, cfg[:lt] + cfg[:h] * (CARD_W + 2) + cfg[:rt]))
end

def render_card_lines(card, index_label: nil, frame: 0, copies: 1)
  r   = card[:rarity]
  cfg = RARITY_CFG[r] || RARITY_CFG[:common]
  c   = cfg[:color]

  name      = card[:name].length > CARD_W ? card[:name][0, CARD_W - 3] + "..." : card[:name]
  icon      = cfg[:icon] * cfg[:stars]
  rname     = cfg[:label]
  type_str  = card[:type] == :unique_skill ? "◆ UNIQUE" : "▲ UPGRADE"
  dl        = word_wrap(card[:description], CARD_W)
  d1        = dl[0] || ""; d2 = dl[1] || ""

  ls = []
  ls << card_border(cfg, frame, true)
  ls << card_row(cfg, Color.bold(Color.send(c, name)), name.length, frame)
  ls << card_sep(cfg)
  ls << card_row(cfg, Color.bold(icon), icon.length, frame)
  ls << card_sep(cfg)
  ls << card_row(cfg, rarity_name_colored(r), rname.length, frame)
  ls << card_row(cfg, Color.dim(type_str), type_str.length, frame)
  ls << card_sep(cfg)
  ls << card_row(cfg, Color.dim(d1), d1.length, frame)
  ls << card_row(cfg, Color.dim(d2), d2.length, frame)
  ls << card_border(cfg, frame, false)

  # Badge: index label + copy count if >1
  copy_tag  = copies > 1 ? Color.bold(Color.green(" x#{copies}")) : ""
  copy_plain = copies > 1 ? " x#{copies}" : ""
  badge      = index_label ? Color.bold(Color.yellow("[ #{index_label} ]")) + copy_tag : ""
  badge_len  = index_label ? "[ #{index_label} ]".length + copy_plain.length : 0
  bpad       = [(CARD_W + 4 - badge_len) / 2, 0].max
  ls << " " * bpad + badge
  ls
end

# ── Detail view (flicker-free) ────────────────────────────────
def card_detail_view(card, copies: 1)
  r   = card[:rarity]
  cfg = RARITY_CFG[r] || RARITY_CFG[:common]
  c   = cfg[:color]
  w   = 44   # total inner span (border to border, excluding the │ chars themselves)
  cw  = w - 2  # usable content width (w minus 1 space padding each side)

  type_str  = card[:type] == :unique_skill ? "◆  UNIQUE SKILL" : "▲  ITEM UPGRADE"
  desc_ls   = word_wrap(card[:description], cw)
  copies_str = copies > 1 ? "Copies: #{copies}  (+#{copies - 1} boost#{"s" if copies > 2})" : "Copies: 1"
  copies_col = copies > 1 ? Color.bold(Color.green(copies_str)) : Color.dim(copies_str)

  make_border = lambda do |top, f|
    tl = top ? cfg[:tl] : cfg[:bl]; tr = top ? cfg[:tr] : cfg[:br]; h = cfg[:h]
    inner = case cfg[:anim]
    when :ripple  then (0...w).map { |i| ((i + f * 2) % (w * 2)) < w / 2 ? "~" : h }.join
    when :shine   then pos = (f * 3) % w; (0...w).map { |i| (i - pos).abs <= 1 ? "=" : h }.join
    when :glimmer then (0...w).map { rand < 0.10 ? "*" : h }.join
    else h * w
    end
    Color.bold(Color.send(c, tl + inner + tr))
  end

  make_row = lambda do |txt, tlen|
    pad = [w - tlen, 0].max; lp = pad / 2; rp = pad - lp
    Color.bold(Color.send(c, cfg[:v])) + " " * lp + txt + " " * rp + Color.bold(Color.send(c, cfg[:v]))
  end

  sep = Color.bold(Color.send(c, cfg[:lt] + cfg[:h] * w + cfg[:rt]))

  build = lambda do |f|
    icon_strip = cfg[:icon] * cfg[:stars]   # e.g. "✦✦✦✦" for legendary
    ls = [""]
    ls << "  " + make_border.call(true, f)
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_row.call(Color.bold(Color.send(c, card[:name])), card[:name].length)
    ls << "  " + make_row.call("", 0)
    ls << "  " + sep
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_row.call(Color.bold(icon_strip), icon_strip.length)
    ls << "  " + make_row.call("", 0)
    ls << "  " + sep
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_row.call(rarity_name_colored(r), cfg[:label].length)
    ls << "  " + make_row.call(Color.dim(type_str), type_str.length)
    ls << "  " + make_row.call(copies_col, copies_str.length)
    ls << "  " + make_row.call("", 0)
    ls << "  " + sep
    ls << "  " + make_row.call("", 0)
    desc_ls.each { |dl| ls << "  " + make_row.call(Color.white(dl), dl.length) }
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_border.call(false, f)
    ls << ""
    ls << Color.dim("  Press any key to go back...")
    ls
  end

  clear
  lines = build.call(0)
  top_idx = 1
  bot_idx = lines.length - 3
  lines.each { |l| puts l }
  $stdout.flush

  frame = 1
  loop do
    ready = IO.select([$stdin], nil, nil, 0.20)
    if ready; $stdin.getch; return; end
    new_lines = build.call(frame)
    total = lines.length
    [top_idx, bot_idx].each do |idx|
      up = total - idx
      print "\e[#{up}A\e[1G#{new_lines[idx]}\e[0K\e[#{up}B\e[1G"
    end
    $stdout.flush
    frame += 1
  end
end

# ── Inventory screen ──────────────────────────────────────────
def open_card_inventory(state)
  # Deduplicate — one entry per unique card name
  raw = (state[:skill_cards] || []) + (state[:active_skills] || [])
  seen = {}
  all_cards = raw.select { |cd| seen[cd[:name]] ? false : (seen[cd[:name]] = true) }
  counts = state[:card_counts] || {}

  if all_cards.empty?
    clear
    draw_header("C A R D   I N V E N T O R Y")
    puts box_line(""); puts box_line(Color.dim("You have no skill cards yet."))
    puts box_line(Color.dim("Win 5 rounds or try the Slot Machine!"))
    puts box_line(""); puts box_line(Color.dim("Press any key to go back...")); draw_footer
    $stdin.getch; return
  end

  sort_mode     = :rarity
  filter_rarity = nil
  page          = 0
  per_page      = 3
  frame         = 0
  full_redraw   = true
  ctrl_h        = 5   # number of lines in the controls block

  ctrl_lines = lambda do
    ls = ["", Color.dim("  " + "─" * 56)]
    nav = [
      Color.bold(Color.yellow("[A]")) + Color.dim(" Prev"),
      Color.bold(Color.yellow("[D]")) + Color.dim(" Next"),
      Color.bold(Color.yellow("[1-3]")) + Color.dim(" Inspect"),
      Color.bold(Color.yellow("[S]")) + Color.dim(" Sort"),
      Color.bold(Color.yellow("[F]")) + Color.dim(" Filter"),
      Color.bold(Color.yellow("[X]")) + Color.dim(" Back"),
    ]
    ls << "  " + nav.join("   ")
    ls << Color.dim("  " + "─" * 56)
    ls << "  Input: "
    ls
  end

  loop do
    sorted = all_cards.sort_by { |cd|
      sort_mode == :rarity ? [RARITY_ORDER.index(cd[:rarity]) || 0, cd[:name]] : [cd[:name]]
    }.reverse
    filtered = filter_rarity ? sorted.select { |cd| cd[:rarity] == filter_rarity } : sorted
    pages    = [(filtered.length / per_page.to_f).ceil, 1].max
    page     = [[page, 0].max, pages - 1].min
    slice    = filtered[page * per_page, per_page] || []

    labeled = slice.each_with_index.map { |cd, i| [cd, (i + 1).to_s] }
    while labeled.length < 3; labeled << nil; end
    cols   = labeled.map { |e| e ? render_card_lines(e[0], index_label: e[1], frame: frame, copies: counts.fetch(e[0][:name], 1)) : Array.new(12, " " * (CARD_W + 4)) }
    max_h  = cols.map(&:length).max
    cols.each { |col| col << "" while col.length < max_h }
    card_rows = max_h.times.map { |i| cols.map { |col| col[i] }.join("    ") }

    if full_redraw
      clear
      # Header
      sparkles = ["✦", "★", "◆", "·"]
      sp_l = sparkles[frame % sparkles.length]; sp_r = sparkles[(frame + 2) % sparkles.length]
      inner_w = 52
      title   = "#{sp_l}  C A R D   C O L L E C T I O N  #{sp_r}"
      t_pad   = [(inner_w - title.length) / 2, 0].max
      t_right = [inner_w - title.length - t_pad, 0].max
      puts Color.bold(Color.yellow("  ╔" + "═" * inner_w + "╗"))
      puts Color.bold(Color.yellow("  ║")) + " " * t_pad + Color.bold(Color.white(title)) + " " * t_right + Color.bold(Color.yellow("║"))
      puts Color.bold(Color.yellow("  ╚" + "═" * inner_w + "╝"))
      puts ""
      rarity_counts = RARITY_ORDER.map { |r| n = all_cards.count { |cd| cd[:rarity] == r }; n > 0 ? card_color(r, "#{rarity_abbrev(r)}:#{n}") : Color.dim("#{rarity_abbrev(r)}:0") }.join(Color.dim("  "))
      puts "  " + Color.dim("Collection: ") + Color.bold(Color.yellow("#{all_cards.length} cards")) + Color.dim("   ") + rarity_counts
      puts "  " + Color.dim("Page #{page + 1}/#{pages}   Sort: ") + Color.bold(Color.cyan(sort_mode.to_s.upcase)) +
           Color.dim("   Filter: ") + (filter_rarity ? card_color(filter_rarity, filter_rarity.to_s.upcase.gsub("_", " ")) : Color.dim("ALL"))
      puts ""
      # Cards
      card_rows.each { |l| puts l }
      # Controls
      ctrl_lines.call.each { |l| puts l }
      $stdout.flush
      full_redraw = false
    end

    ready = IO.select([$stdin], nil, nil, 0.25)
    if ready
      ch = $stdin.getch.downcase
      case ch
      when 'x' then return
      when 'a' then page = (page - 1) % pages; full_redraw = true; frame = 0
      when 'd' then page = (page + 1) % pages; full_redraw = true; frame = 0
      when '1', '2', '3'
        cd = slice[ch.to_i - 1]
        if cd
          card_detail_view(cd, copies: counts.fetch(cd[:name], 1))
          full_redraw = true; frame = 0
        end
      when 's' then sort_mode = sort_mode == :rarity ? :name : :rarity; full_redraw = true; frame = 0
      when 'f' then filter_rarity = cycle_filter(filter_rarity); full_redraw = true; frame = 0
      end
      next
    end

    frame += 1
    next if slice.all? { |cd| cd.nil? || RARITY_CFG.dig(cd[:rarity], :anim) == :none }

    # Re-render cards in-place
    new_cols  = labeled.map { |e| e ? render_card_lines(e[0], index_label: e[1], frame: frame, copies: counts.fetch(e[0][:name], 1)) : Array.new(12, " " * (CARD_W + 4)) }
    new_cols.each { |col| col << "" while col.length < max_h }
    new_card_rows = max_h.times.map { |i| new_cols.map { |col| col[i] }.join("    ") }

    ctrl_h = ctrl_lines.call.length
    total_up = ctrl_h + max_h
    print "\e[#{total_up}A"
    new_card_rows.each { |l| print "\e[1G#{l}\e[0K\n" }
    ctrl_lines.call.each { |l| print "\e[1G#{l}\e[0K\n" }
    $stdout.flush
  end
end

def rarity_abbrev(r)
  case r
  when :common     then "C"
  when :rare       then "R"
  when :ultra_rare then "UR"
  when :legendary  then "L"
  when :mythic     then "M"
  when :gold       then "G"
  else "?"
  end
end

def cycle_filter(current)
  order = [nil] + RARITY_ORDER
  idx   = order.index(current) || 0
  order[(idx + 1) % order.length]
end
