# ── Skin Shop & Selection ─────────────────────────────────────

def open_skin_shop(state)
  require_relative '../lib/effects'
  
  loop do
    clear
    draw_header("S K I N  S H O P")
    puts "  " + Color.dim("Your points: ") + Color.bold(Color.yellow("#{state[:score]} pts"))
    puts "  " + Color.dim("Wins: ") + Color.cyan("#{state[:wins]}")
    draw_divider

    frame = 0
    active_skin_id = state[:active_skin] || :default

    UI_SKINS.each_with_index do |(skin_id, skin_cfg), idx|
      unlocked = skin_unlocked?(state, skin_id)
      label = Color.bold(Color.yellow((idx + 1).to_s))

      # Status indicator
      if skin_id == active_skin_id
        status = Color.bold(Color.green("✓ ACTIVE"))
      elsif !unlocked
        if skin_cfg[:unlocked_by] == :achievement
          status = Color.bold(Color.red("🔒 LOCKED - #{skin_cfg[:achievement].to_s.upcase.gsub('_', ' ')}"))
        else
          status = Color.dim("Cost: #{skin_cfg[:cost]} pts")
        end
      else
        status = Color.dim("[Owned]")
      end

      rarity = case skin_cfg[:rarity]
        when :common then Color.white("●")
        when :rare then Color.cyan("●")
        when :ultra_rare then Color.magenta("●")
        when :legendary then Color.yellow("●")
        when :mythic then Color.red("●")
      end

      puts "  #{label}. #{rarity} #{Color.bold(skin_cfg[:name])} #{status}"
      puts "     #{Color.dim(skin_cfg[:description])}"
    end

    puts ""
    draw_divider
    puts "  " + Color.bold(Color.yellow("Select skin:")) + Color.dim(" [1-8], [P]review, or [X] Back")
    puts ""
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input

    case input
    when '1'..'8'
      idx = input.to_i - 1
      skin_ids = UI_SKINS.keys
      skin_id = skin_ids[idx]
      skin_cfg = UI_SKINS[skin_id]

      if !skin_unlocked?(state, skin_id)
        if skin_cfg[:unlocked_by] == :achievement
          puts Color.red("  Not unlocked yet! Collect all #{skin_cfg[:achievement].to_s.upcase.gsub('_', ' ')}"); sleep 1
        else
          if state[:score] >= skin_cfg[:cost]
            # Purchase the skin
            state[:score] -= skin_cfg[:cost]
            state[:unlocked_skins] ||= []
            state[:unlocked_skins] << skin_id
            state[:active_skin] = skin_id
            puts Color.green("  ✓ Purchased and activated: #{skin_cfg[:name]}!"); sleep 1
          else
            puts Color.red("  Not enough points! Need #{skin_cfg[:cost]}pts, have #{state[:score]}pts"); sleep 1
          end
        end
      else
        # Already unlocked, just activate
        state[:active_skin] = skin_id
        puts Color.green("  ✓ Activated: #{skin_cfg[:name]}!"); sleep 1
      end

    when 'p'
      # Preview mode
      preview_skin(state)

    when 'x'
      break

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

def preview_skin(state)
  clear
  draw_header("S K I N   P R E V I E W")
  puts box_line(Color.yellow("This is a preview of various skins"))
  draw_divider

  # Show a few skins side by side
  preview_texts = [
    "Welcome to",
    "Hangman!",
    "Select Skin"
  ]

  frame = 0
  20.times do
    clear
    draw_header("S K I N   P R E V I E W")
    draw_divider

    skin_ids = UI_SKINS.keys
    rows = []
    
    preview_texts.each_with_index do |text, text_idx|
      row = "  "
      (0...3).each do |col_idx|
        skin_id = skin_ids[(col_idx * 3 + text_idx) % skin_ids.length]
        skin_cfg = UI_SKINS[skin_id]
        
        if skin_unlocked?(state, skin_id)
          c = skin_cfg[:colors][:primary]
          styled = Color.send(c, text)
          row += "  #{styled}  "
        else
          row += "  #{Color.dim("[LOCKED]")}  "
        end
      end
      rows << row
    end

    puts Color.dim("Arcade")
    puts rows[0]
    puts Color.dim("Gothic")
    puts rows[1]
    puts Color.dim("Cyberpunk")
    puts rows[2]

    draw_divider
    puts box_line(Color.dim("Press any key to return..."))
    draw_footer

    sleep 0.3
    
    if IO.select([$stdin], nil, nil, 0) != nil
      $stdin.getch
      break
    end
    
    frame += 1
  end
end
