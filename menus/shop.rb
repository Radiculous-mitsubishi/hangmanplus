# ── Shop ──────────────────────────────────────────────────────
def open_shop(state)
  require_relative 'slots'
  
  loop do
    clear
    draw_header("S H O P")
    puts "  " + Color.dim("Your points: ") + Color.bold(Color.yellow("#{state[:score]} pts"))
    draw_divider

    SHOP_ITEMS.each_with_index do |item, i|
      if item[:type] == :permanent
        level      = state[:permanent_bonuses][item[:id]] || 0
        no_cap     = item[:id] == :bonus_point && state[:permanent_bonuses][:bonus_point_no_cap]
        at_max     = !no_cap && item[:max] && level >= item[:max]
        owned      = if at_max
          Color.dim("[MAX]")
        elsif no_cap
          Color.bold(Color.yellow("[Lv.#{level} ∞]"))
        else
          Color.dim("[Lv.#{level}]")
        end
      else
        qty   = state[:inventory][item[:id]] || 0
        owned = qty > 0 ? Color.cyan("[x#{qty}]") : ""
      end
      can_afford = state[:score] >= item[:cost]
      cost_str   = can_afford ? Color.green("#{item[:cost]}pts") : Color.red("#{item[:cost]}pts")
      puts "  #{Color.bold(Color.yellow((i+1).to_s))}. [#{item[:emoji]}] #{Color.bold(item[:name])} #{cost_str} #{owned}"
      puts "     #{Color.dim(item[:description])}"
    end

    puts ""
    draw_divider
    slotcost = slot_spin_cost(state)
    slotafford = state[:score] >= slotcost
    puts "  #{Color.bold(Color.yellow('L'))}. [~] Slot Machine  #{slotafford ? Color.green("#{slotcost}pts/spin") : Color.red("#{slotcost}pts/spin")}  #{Color.dim("(33% chance: Skill Card)")}"
    puts "  #{Color.bold(Color.yellow('K'))}. [✨] UI Skins Shop  #{Color.dim("(Customize your interface)")}"
    draw_divider
    puts "  #{Color.bold(Color.yellow('X'))}. Leave shop"
    puts ""
    print "  Buy (1-#{SHOP_ITEMS.length}), [L]Slots, [K]Skins, or X: "

    input = $stdin.getch.strip.downcase
    puts input
    break if input == 'x'

    if input == 'l'
      open_slot_machine(state)
      next
    end

    if input == 'k'
      require_relative 'skins'
      open_skin_shop(state)
      next
    end

    idx = input.to_i - 1
    next unless (0...SHOP_ITEMS.length).include?(idx)
    item = SHOP_ITEMS[idx]

    if item[:type] == :permanent
      level  = state[:permanent_bonuses][item[:id]] || 0
      no_cap = item[:id] == :bonus_point && state[:permanent_bonuses][:bonus_point_no_cap]
      if !no_cap && item[:max] && level >= item[:max]
        puts Color.red("  Already at max level!"); sleep 1; next
      end
    end

    if state[:score] < item[:cost]
      puts Color.red("  Not enough points!"); sleep 1; next
    end

    state[:score] -= item[:cost]
    if item[:type] == :permanent
      state[:permanent_bonuses][item[:id]] ||= 0
      state[:permanent_bonuses][item[:id]] += 1
      puts Color.green("  [#{item[:emoji]}] #{item[:name]} upgraded to level #{state[:permanent_bonuses][item[:id]]}!")
    else
      state[:inventory][item[:id]] ||= 0
      state[:inventory][item[:id]] += 1
      puts Color.green("  [#{item[:emoji]}] #{item[:name]} purchased!")
    end
    sleep 1
  end
end
