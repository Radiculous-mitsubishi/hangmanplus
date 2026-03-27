# ── UI Effects System ────────────────────────────────────────

# Apply skin effects to text
def apply_skin_effect(text, effect, frame = 0, skin = nil)
  case effect
  # Arcade Effects
  when :arcade_flicker
    flicker = frame % 3 == 0 ? text : Color.dim(text)
    flicker
  when :arcade_pulse
    intensity = ((frame % 6) / 3).round
    intensity == 0 ? Color.bold(text) : text
  when :arcade_colors
    colors = [:red, :yellow, :cyan]
    color = colors[frame % colors.length]
    Color.send(color, text)

  # Neon Effects
  when :neon_glow
    # Simulate glow by adding spaces and repeated text
    "✦ #{Color.bold(Color.cyan(text))} ✦"
  when :neon_scan
    # Horizontal scanning line effect
    if (frame % 4).zero?
      Color.bold(Color.cyan(text))
    else
      Color.dim(text)
    end
  when :neon_pulse
    # Pulsing brightness
    pulse = (Math.sin(frame * 0.3) + 1) / 2 # 0-1
    if pulse > 0.66
      Color.bold(Color.magenta(text))
    elsif pulse > 0.33
      Color.bold(Color.cyan(text))
    else
      Color.bold(Color.red(text))
    end

  # Cyberpunk Effects
  when :cyberpunk_flicker
    if frame % 7 < 2
      Color.bold(Color.yellow(text)) + Color.red(" ▓")
    else
      Color.bold(Color.cyan(text))
    end

  # Mystical Effects
  when :mystical_sparkle
    sparkles = ["✨", "★", "◆", "✧"]
    sparkle = sparkles[frame % sparkles.length]
    "#{sparkle} #{Color.bold(Color.magenta(text))} #{sparkle}"
  when :mystical_wave
    # Wave-like text (simulate with underline effect)
    wave_chars = ["▔", "▁", "▔", "▁"]
    wave = wave_chars[frame % wave_chars.length]
    "#{text}#{Color.magenta(wave)}"
  when :mystical_aura
    # Glowing aura effect
    auras = [" ○", "◎ ", "◐ "]
    aura = auras[frame % auras.length]
    "#{Color.bold(Color.magenta(aura))} #{Color.cyan(text)}"
  when :mystical_float
    # Floating effect (vertical offset simulation)
    if (frame / 4) % 2 == 0
      " #{text}"
    else
      text
    end

  # Glass Effects
  when :glass_shimmer
    if (frame % 6) < 2
      Color.bold(Color.cyan(text))
    elsif (frame % 6) < 4
      Color.bold(Color.white(text))
    else
      Color.cyan(text)
    end
  when :glass_layers
    # Simulate depth with spacing
    "  #{text}  "
  when :glass_refraction
    # Color shifting effect
    if (frame % 4).zero?
      Color.cyan(text)
    elsif (frame % 4) == 2
      Color.magenta(text)
    else
      Color.white(text)
    end

  # Gothic Effects
  when :gothic_glow
    Color.bold(Color.red(text))
  when :gothic_shadows
    if frame % 4 < 2
      Color.bold(Color.magenta(text))
    else
      Color.dim(Color.red(text))
    end
  when :gothic_flicker
    if (frame % 3).zero?
      Color.bold(Color.red(text))
    else
      text
    end

  # Steampunk Effects
  when :steampunk_gears
    gears = ["⚙", "⚡", "⚙"]
    gear = gears[frame % gears.length]
    "#{gear} #{Color.bold(Color.yellow(text))}"
  when :steampunk_meters
    # Gauge-like visualization
    levels = ["▁", "▃", "▄", "▅", "▆", "▇"]
    level = levels[frame % levels.length]
    "#{level} #{text}"
  when :steampunk_warmth
    # Warm color palette
    Color.bold(Color.yellow(text))

  # Cosmic Effects
  when :cosmic_stars
    stars = ["·", "✦", "★", "◆"]
    star = stars[frame % stars.length]
    "#{star} #{text} #{star}"
  when :cosmic_auroras
    # Aurora color shifting
    colors = [:cyan, :magenta, :yellow, :cyan]
    color = colors[(frame / 2) % colors.length]
    Color.bold(Color.send(color, text))
  when :cosmic_float
    # Floating animation
    if (frame / 3) % 2 == 0
      " #{text}"
    else
      "  #{text}"
    end
  when :cosmic_glow
    if frame % 4 < 2
      Color.bold(text)
    else
      text
    end

  # Minimal Effects
  when :minimal_spacing
    "  #{text}"

  else
    text
  end
end

# Apply multiple effects stacked
def apply_skin_effects(text, effects, frame = 0, skin = nil)
  result = text
  effects.each do |effect|
    result = apply_skin_effect(result, effect, frame, skin)
  end
  result
end

# Animated border drawing
def draw_skin_border(skin_cfg, frame, top = true)
  if skin_cfg.nil?
    skin_cfg = UI_SKINS[:default]
  end

  chars = skin_cfg[:border_chars]
  c = skin_cfg[:colors][:primary]
  
  w = BOX_WIDTH - 2
  
  # Build the border based on effects
  effects = skin_cfg[:effects] || []
  
  if top
    left = chars[:tl]
    right = chars[:tr]
    line_char = chars[:h]
  else
    left = chars[:bl]
    right = chars[:br]
    line_char = chars[:h]
  end
  
  # Apply neon scan effect to border
  if effects.include?(:neon_scan)
    if (frame % 4).zero?
      line_char = "═"
    else
      line_char = "─"
    end
  end
  
  border_line = left + (line_char * w) + right
  Color.send(c, border_line)
end

# Get current skin configuration
def get_active_skin(state)
  active_skin_id = state[:active_skin] || :default
  UI_SKINS[active_skin_id] || UI_SKINS[:default]
end

# Check if skin is unlocked
def skin_unlocked?(state, skin_id)
  return true if skin_id == :default
  return true if (state[:unlocked_skins] || []).include?(skin_id)
  false
end
