# ── Shop ──────────────────────────────────────────────────────
# Calculate scaled cost based on current level and player credits
def calculate_item_cost(base_cost, item, state)
  # Determine current level/quantity owned
  if item[:type] == :permanent
    level = state[:permanent_bonuses][item[:id]] || 0
    # Permanent upgrades: cost increases by 50% per level
    scaled_cost = (base_cost * (1 + level * 0.5)).round
  else
    qty = state[:inventory][item[:id]] || 0
    # Consumables: cost increases by 20% per item owned
    scaled_cost = (base_cost * (1 + qty * 0.2)).round
  end
  
  # Wealth scaling: if player has lots of credits, items get more expensive
  # For every 500 points over 1000, increase cost by 5%
  if state[:score] > 1000
    wealth_multiplier = 1 + ((state[:score] - 1000) / 500) * 0.05
    scaled_cost = (scaled_cost * wealth_multiplier).round
  end
  
  scaled_cost
end

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
      
      # Calculate scaled cost
      scaled_cost = calculate_item_cost(item[:cost], item, state)
      can_afford = state[:score] >= scaled_cost
      cost_str   = can_afford ? Color.green("#{scaled_cost}pts") : Color.red("#{scaled_cost}pts")
      puts "  #{Color.bold(Color.yellow((i+1).to_s))}. [#{item[:emoji]}] #{Color.bold(item[:name])} #{cost_str} #{owned}"
      puts "     #{Color.dim(item[:description])}"
    end

    puts ""
    draw_divider
    slotcost = slot_spin_cost(state)
    slotafford = state[:score] >= slotcost
    puts "  #{Color.bold(Color.yellow('L'))}. [~] Slot Machine  #{slotafford ? Color.green("#{slotcost}pts/spin") : Color.red("#{slotcost}pts/spin")}  #{Color.dim("(33% chance: Skill Card)")}"
    draw_divider
    puts "  #{Color.bold(Color.yellow('X'))}. Leave shop"
    puts ""
    print "  Buy (1-#{SHOP_ITEMS.length}), [L]Slots, or X: "

    input = $stdin.getch.strip.downcase
    puts input
    break if input == 'x'

    if input == 'l'
      open_slot_machine(state)
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

    if state[:score] < calculate_item_cost(item[:cost], item, state)
      puts Color.red("  Not enough points!"); sleep 1; next
    end

    scaled_cost = calculate_item_cost(item[:cost], item, state)
    state[:score] -= scaled_cost
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
