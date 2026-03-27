# ── Save Game Menu ───────────────────────────────────────────

require_relative '../lib/save_system'
require_relative '../lib/color'
require_relative '../lib/display'

def open_save_menu(state, difficulty_ref)
  loop do
    require_relative '../lib/color'
    require_relative '../lib/display'
    require_relative '../lib/save_system'
    
    system('clear') || system('cls')
    
    puts ""
    draw_header("S A V E  G A M E")
    puts ""
    
    slots = get_save_slots
    
    (1..MAX_SAVE_SLOTS).each do |slot|
      slot_info = slots[slot]
      exists_marker = slot_info[:exists] ? "●" : "○"
      marker_color = slot_info[:exists] ? Color.green(exists_marker) : Color.dim(exists_marker)
      
      puts "  #{marker_color} [#{slot}] #{format_save_info(slot_info)}"
    end
    
    puts ""
    puts box_line("Enter slot number (1-4) to #{Color.bold('SAVE')}, [L]oad, [D]elete, or [B]ack")
    print "> "
    $stdout.flush
    input = gets.chomp.downcase
    
    case input
    when '1', '2', '3', '4'
      slot = input.to_i
      require_relative '../lib/color'
      puts "  #{Color.yellow('Saving')}... "
      
      if save_game(state, difficulty_ref, slot)
        puts "  #{Color.green('✓')} Game saved to slot #{slot}!"
        sleep 1.5
      else
        puts "  #{Color.red('✗')} Failed to save game."
        sleep 1.5
      end
      
    when 'l'
      choose_load_slot
      
    when 'd'
      choose_delete_slot
      
    when 'b'
      break
    else
      puts box_line("#{Color.red('Invalid choice. Please try again.')}")
      sleep 1
    end
  end
end

def choose_load_slot
  require_relative '../lib/color'
  require_relative '../lib/display'
  require_relative '../lib/save_system'
  
  system('clear') || system('cls')
  
  puts ""
  draw_header("L O A D  G A M E")
  puts ""
  
  slots = get_save_slots
  
  (1..MAX_SAVE_SLOTS).each do |slot|
    slot_info = slots[slot]
    if slot_info[:exists]
      puts "  [#{slot}] #{format_save_info(slot_info)}"
    else
      puts "  #{Color.dim("[#{slot}] [Empty Slot]")}"
    end
  end
  
  puts ""
  puts box_line("Enter slot number to load, or [C]ancel")
  print "> "
  $stdout.flush
  input = gets.chomp.downcase
  
  if input.to_i.between?(1, MAX_SAVE_SLOTS)
    slot = input.to_i
    slot_info = slots[slot]
    
    if slot_info[:exists]
      return slot
    else
      puts box_line("#{Color.red('That slot is empty.')}")
      sleep 1
    end
  elsif input != 'c'
    puts box_line("#{Color.red('Invalid choice.')}")
    sleep 1
  end
  
  nil
end

def choose_delete_slot
  require_relative '../lib/color'
  require_relative '../lib/display'
  require_relative '../lib/save_system'
  
  system('clear') || system('cls')
  
  puts ""
  draw_header("D E L E T E  S A V E")
  puts ""
  
  slots = get_save_slots
  
  (1..MAX_SAVE_SLOTS).each do |slot|
    slot_info = slots[slot]
    if slot_info[:exists]
      puts "  [#{slot}] #{format_save_info(slot_info)}"
    else
      puts "  #{Color.dim("[#{slot}] [Empty Slot]")}"
    end
  end
  
  puts ""
  puts box_line("Enter slot number to DELETE, or [C]ancel #{Color.red('(Cannot be undone!)')}")
  print "> "
  $stdout.flush
  input = gets.chomp.downcase
  
  if input.to_i.between?(1, MAX_SAVE_SLOTS)
    slot = input.to_i
    slot_info = slots[slot]
    
    if slot_info[:exists]
      puts box_line("#{Color.yellow('Are you SURE? Enter')} #{Color.bold('DELETE')} #{Color.yellow('to confirm')}")
      print "> "
      $stdout.flush
      confirm = gets.chomp.downcase
      
      if confirm == 'delete'
        delete_save(slot)
        puts box_line("#{Color.green('✓')} Save file deleted.")
        sleep 1
      else
        puts box_line("#{Color.dim('Deletion cancelled.')}")
        sleep 1
      end
    else
      puts box_line("#{Color.red('That slot is empty.')}")
      sleep 1
    end
  elsif input != 'c'
    puts box_line("#{Color.red('Invalid choice.')}")
    sleep 1
  end
end

def main_menu_with_load
  require_relative '../lib/color'
  require_relative '../lib/display'
  require_relative '../lib/save_system'
  
  loop do
    system('clear') || system('cls')
    
    puts ""
    draw_header("H A N G M A N  P L U S")
    puts ""
    
    slots = get_save_slots
    has_saves = slots.any? { |_, info| info[:exists] }
    
    puts box_line("[N]ew Game")
    
    if has_saves
      puts box_line(Color.bold("[L]oad Game"))
    else
      puts box_line(Color.dim("[L]oad Game  (No saves)"))
    end
    
    puts box_line("[C]redits")
    puts box_line("[Q]uit")
    puts ""
    print "> "
    $stdout.flush
    input = gets.chomp.downcase
    
    case input
    when 'n'
      return nil
    when 'l'
      if has_saves
        chosen_slot = choose_load_slot
        return chosen_slot if chosen_slot
      else
        puts box_line("#{Color.red('No save files found.')}")
        sleep 1.5
      end
    when 'c'
      show_credits
    when 'q'
      puts "\n#{Color.dim('Thanks for playing!')}\n"
      exit(0)
    else
      puts box_line("#{Color.red('Invalid choice. Please try again.')}")
      sleep 1
    end
  end
end

def show_credits
  require_relative '../lib/color'
  require_relative '../lib/display'
  
  loop do
    system('clear') || system('cls')
    
    puts ""
    draw_header("C R E D I T S")
    puts ""
    puts ""
    draw_divider
    puts "  " + Color.bold(Color.yellow("HANGMAN PLUS"))
    puts "  " + Color.dim("Terminal Edition")
    puts ""
    puts "  " + Color.bold(Color.cyan("DEVELOPMENT"))
    puts "  " + Color.bold("Lead Developer")
    puts "  " + Color.cyan("Radiculous_Mitsubishi")
    puts ""
    puts "  " + Color.bold(Color.cyan("CONTRIBUTORS"))
    puts "  " + Color.bold("Gameplay Assistants")
    puts "    • Miton Rounds"
    puts "    • Alpha male Zacharias"
    puts "    • Kenny Ta"
    puts "    • Isabella Ericsson"
    puts ""
    puts "  " + Color.bold("UI Contributions")
    puts "    • Milton Rounds"
    puts ""
    puts "  " + Color.bold("Quality Assurance")
    puts "    • Alfred Åsevi"
    puts "    • Marceli"
    puts ""
    puts "  " + Color.dim("Made with ■ in Ruby")
    draw_divider
    puts ""
    puts "  " + Color.bold("Press any key to return...")
    
    $stdin.getch
    break
  end
end
