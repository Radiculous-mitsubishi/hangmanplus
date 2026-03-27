# ── UI Skin Definitions ──────────────────────────────────────

UI_SKINS = {
  default: {
    name: "Classic",
    rarity: :common,
    cost: 0,
    description: "The timeless original UI",
    unlocked_by: :start,
    border_chars: { tl: "+", tr: "+", bl: "+", br: "+", h: "-", v: "|", t: "+", b: "+", l: "+", r: "+" },
    colors: { primary: :cyan, secondary: :white, accent: :yellow },
    effects: []
  },

  minimalist: {
    name: "Minimalist Clean",
    rarity: :common,
    cost: 500,
    description: "Ultra-clean lines, pure readability",
    unlocked_by: :purchase,
    border_chars: { tl: "─", tr: "─", bl: "─", br: "─", h: "─", v: " ", t: " ", b: " ", l: " ", r: " " },
    colors: { primary: :white, secondary: :dim, accent: :white },
    effects: [:minimal_spacing, :subtle_hierarchy]
  },

  arcade: {
    name: "Retro Arcade",
    rarity: :rare,
    cost: 1500,
    description: "Pixels, colors, and nostalgic vibes!",
    unlocked_by: :purchase,
    border_chars: { tl: "█", tr: "█", bl: "█", br: "█", h: "█", v: "█", t: "█", b: "█", l: "█", r: "█" },
    colors: { primary: :yellow, secondary: :red, accent: :cyan },
    effects: [:arcade_flicker, :arcade_pulse, :arcade_colors]
  },

  gothic: {
    name: "Dark Gothic",
    rarity: :rare,
    cost: 1200,
    description: "Ornate darkness with eerie elegance",
    unlocked_by: :purchase,
    border_chars: { tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║", t: "╦", b: "╩", l: "╠", r: "╣" },
    colors: { primary: :magenta, secondary: :red, accent: :yellow },
    effects: [:gothic_glow, :gothic_shadows, :gothic_flicker]
  },

  steampunk: {
    name: "Steampunk Industrial",
    rarity: :rare,
    cost: 1800,
    description: "Mechanical beauty with warm metallics",
    unlocked_by: :purchase,
    border_chars: { tl: "┌", tr: "┐", bl: "└", br: "┘", h: "─", v: "│", t: "┬", b: "┴", l: "├", r: "┤" },
    colors: { primary: :yellow, secondary: :white, accent: :red },
    effects: [:steampunk_gears, :steampunk_meters, :steampunk_warmth]
  },

  glass: {
    name: "Futuristic Glass",
    rarity: :ultra_rare,
    cost: 2200,
    description: "Glassmorphism with depth and refraction",
    unlocked_by: :purchase,
    border_chars: { tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "─", v: "│", t: "╦", b: "╩", l: "╠", r: "╣" },
    colors: { primary: :cyan, secondary: :white, accent: :magenta },
    effects: [:glass_shimmer, :glass_layers, :glass_refraction]
  },

  cyberpunk: {
    name: "Neon Cyberpunk",
    rarity: :ultra_rare,
    cost: 2000,
    description: "Glowing neon with electric intensity!",
    unlocked_by: :purchase,
    border_chars: { tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║", t: "╦", b: "╩", l: "╠", r: "╣" },
    colors: { primary: :cyan, secondary: :magenta, accent: :yellow },
    effects: [:neon_glow, :neon_scan, :neon_pulse, :cyberpunk_flicker]
  },

  cosmic: {
    name: "Cosmic Space",
    rarity: :legendary,
    cost: 3000,
    description: "Star fields and celestial wonders",
    unlocked_by: :purchase,
    border_chars: { tl: "✦", tr: "✦", bl: "✦", br: "✦", h: "·", v: "·", t: "✦", b: "✦", l: "✦", r: "✦" },
    colors: { primary: :cyan, secondary: :magenta, accent: :yellow },
    effects: [:cosmic_stars, :cosmic_auroras, :cosmic_float, :cosmic_glow]
  },

  enchanted: {
    name: "Enchanted Mystical",
    rarity: :mythic,
    cost: 0,
    description: "Magical mystery unlocked by collecting all Mythic cards",
    unlocked_by: :achievement,
    achievement: :all_mythic_cards,
    border_chars: { tl: "✨", tr: "✨", bl: "✨", br: "✨", h: "✧", v: "✧", t: "✨", b: "✨", l: "✨", r: "✨" },
    colors: { primary: :magenta, secondary: :cyan, accent: :yellow },
    effects: [:mystical_sparkle, :mystical_wave, :mystical_aura, :mystical_float]
  }
}

# Achievement unlock for Enchanted skin
def check_enchanted_skin_unlock(state)
  return if (state[:unlocked_skins] || []).include?(:enchanted)
  
  # Check if player owns all mythic cards
  all_mythic_collected = SKILL_CARDS.values.select { |c| c[:rarity] == :mythic }.all? do |card|
    ((state[:skill_cards] || []) + (state[:active_skills] || [])).any? { |c| c[:name] == card[:name] }
  end
  
  if all_mythic_collected
    state[:unlocked_skins] ||= []
    state[:unlocked_skins] << :enchanted
    
    # Show achievement unlock animation
    show_enchanted_unlock_animation
  end
end

def show_enchanted_unlock_animation
  clear
  3.times do |i|
    clear
    sparkle = [" ✨ ", " ★ ", " ◆ ", " ✨ "][i % 4]
    border  = Color.bold(Color.magenta("  ╔" + "═" * 52 + "╗"))
    puts "\n\n\n"
    puts border
    puts Color.bold(Color.magenta("  ║")) + "  " * 26 + Color.bold(Color.magenta("║"))
    title = "#{sparkle}  E N C H A N T E D   S K I N  #{sparkle}"
    t_pad = [(52 - title.length) / 2, 0].max
    puts Color.bold(Color.magenta("  ║")) + " " * t_pad + Color.bold(Color.cyan(title)) + " " * [52 - title.length - t_pad, 0].max + Color.bold(Color.magenta("║"))
    puts Color.bold(Color.magenta("  ║")) + "  " * 26 + Color.bold(Color.magenta("║"))
    puts Color.bold(Color.magenta("  ╚" + "═" * 52 + "╝"))
    sleep 0.3
  end
  puts
  puts Color.bold(Color.magenta("  ╔" + "═" * 52 + "╗"))
  puts Color.bold(Color.magenta("  ║")) + Color.bold(Color.cyan("  ✨  A L L   M Y T H I C   C A R D S  ✨            ")) + Color.bold(Color.magenta("║"))
  puts Color.bold(Color.magenta("  ╠" + "═" * 52 + "╣"))
  puts Color.bold(Color.magenta("  ║")) + Color.bold(Color.magenta("  You have unlocked the Enchanted Mystical skin! ")) + Color.bold(Color.magenta("║"))
  puts Color.bold(Color.magenta("  ╠" + "═" * 52 + "╣"))
  puts Color.white("  │  Sparkles, waves, and magical auras await!    │") + Color.bold(Color.magenta(" ║"))
  puts Color.dim("  │  Visit the Skin Shop to activate it.          │") + Color.bold(Color.magenta(" ║"))
  puts Color.bold(Color.magenta("  ╚" + "═" * 52 + "╝"))
  puts
  puts Color.dim("  Press any key to continue...")
  $stdin.getch
end
