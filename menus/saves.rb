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
      if slot_info[:exists] && !save_available_for_user?(slot_info, state[:username])
        puts "  #{Color.dim("[#{slot}] [Owned by #{slot_info[:username]}]")}"
      else
        exists_marker = slot_info[:exists] ? "●" : "○"
        marker_color = slot_info[:exists] ? Color.green(exists_marker) : Color.dim(exists_marker)
        puts "  #{marker_color} [#{slot}] #{format_save_info(slot_info)}"
      end
    end
    
    puts ""
    puts box_line("Enter slot number (1-4) to #{Color.bold('SAVE')}, [D]elete, or [B]ack")
    print "> "
    $stdout.flush
    input = gets.chomp.downcase
    
    case input
    when '1', '2', '3', '4'
      slot = input.to_i
      slot_info = slots[slot]
      if slot_info[:exists] && !save_available_for_user?(slot_info, state[:username])
        puts Color.red("  You cannot overwrite another account's save.")
        sleep 1.5
        next
      end

      require_relative '../lib/color'
      puts "  #{Color.yellow('Saving')}... "
      
      if save_game(state, difficulty_ref, slot)
        puts "  #{Color.green('✓')} Game saved to slot #{slot}!"
        sleep 1.5
      else
        puts "  #{Color.red('✗')} Failed to save game."
        sleep 1.5
      end
      
    when 'd'
      choose_delete_slot(state[:username])
      
    when 'b'
      break
    else
      puts box_line("#{Color.red('Invalid choice. Please try again.')}")
      sleep 1
    end
  end
end

def prompt_new_game_profile(username)
  save_name = prompt_profile_value("Name for this save")
  preset = choose_difficulty_preset
  { username: username, save_name: save_name, difficulty_preset: preset }
end

def choose_difficulty_preset
  loop do
    clear
    draw_header("C H O O S E  A  P R E S E T")
    DIFFICULTY_PRESETS.each_with_index do |(key, preset), index|
      puts box_line("[#{index + 1}] #{Color.bold(preset[:name])}")
      puts box_line("    #{Color.dim(preset[:description])}")
    end
    puts box_line("Enter a preset number from 1 to 4.")
    print "  Preset: "
    choice = $stdin.gets&.strip
    return DIFFICULTY_PRESETS.keys[choice.to_i - 1] if choice && choice.match?(/\A[1-4]\z/)

    puts Color.red("  Choose a preset from 1 to 4.")
    sleep 0.8
  end
end

def prompt_custom_word_list(username)
  require_relative '../lib/custom_word_lists'
  system('clear') || system('cls')
  draw_header("L O A D  C U S T O M  W O R D  L I S T")
  puts box_line(Color.dim("Choose a local TXT or CSV file; the path can be absolute or relative."))
  puts box_line(Color.dim("Use one word per line or comma-separated words; letters only."))
  puts box_line(Color.dim("This file and game data stay on this device."))
  puts
  print "  File path: "
  path = $stdin.gets&.strip
  return nil if path.nil? || path.empty?

  word_list = load_custom_word_list(path)
  puts Color.green("  Loaded #{word_list[:words].length} unique words from #{word_list[:name]}.")
  save_name = prompt_profile_value("Name for this save")
  preset = choose_difficulty_preset
  { type: :custom_game, username: username, save_name: save_name, custom_word_list: word_list, difficulty_preset: preset }
rescue ArgumentError => error
  puts Color.red("  #{error.message}")
  sleep 2
  nil
end

def prompt_profile_value(label)
  loop do
    print "  #{label}: "
    value = $stdin.gets&.strip
    return value unless value.nil? || value.empty?

    puts Color.red("  Please enter a name.")
  end
end

def read_password_prompt(label)
  print "  #{label}: "
  password = if $stdin.tty? && $stdin.respond_to?(:noecho)
    $stdin.noecho { $stdin.gets }
  else
    $stdin.gets
  end
  puts if $stdin.tty?
  password&.chomp
end

def create_account_from_menu
  require_relative '../lib/accounts'
  system('clear') || system('cls')
  draw_header("C R E A T E  L O C A L  A C C O U N T")
  puts box_line(Color.dim("Accounts and game data stay on this device; nothing is sent online."))
  puts
  username = prompt_profile_value("Username (3-20 letters, numbers, or underscores)")
  password = read_password_prompt("Password (minimum 8 characters)")
  confirmation = read_password_prompt("Confirm password")

  if password != confirmation
    puts Color.red("  Passwords do not match.")
    sleep 1.5
    return nil
  end

  success, result = create_local_account(username, password)
  if success
    puts Color.green("  Account created. Signed in as #{result}.")
    sleep 1
    result
  else
    puts Color.red("  #{result}")
    sleep 1.5
    nil
  end
end

def sign_in_from_menu
  require_relative '../lib/accounts'
  system('clear') || system('cls')
  draw_header("S I G N  I N")
  puts box_line(Color.dim("Your account and game data are stored locally on this device."))
  puts
  username = prompt_profile_value("Username")
  password = read_password_prompt("Password")
  authenticated_username = authenticate_local_account(username, password)

  if authenticated_username
    puts Color.green("  Signed in as #{authenticated_username}.")
    sleep 0.8
    authenticated_username
  else
    puts Color.red("  Username or password is incorrect.")
    sleep 1.5
    nil
  end
end

def save_available_for_user?(slot_info, username)
  save_owner_matches?(slot_info, username)
end

def open_lan_play_from_menu(current_username)
  unless current_username
    puts Color.yellow("  Sign in or create an account to join LAN play.")
    print "  [S] Sign in  [A] Create account  [B] Back: "
    auth_choice = $stdin.gets&.strip&.downcase
    current_username = sign_in_from_menu if auth_choice == 's'
    current_username = create_account_from_menu if auth_choice == 'a'
    return nil unless current_username
  end

  require_relative 'lan'
  open_lan_menu(current_username)
  current_username
end

def choose_load_slot(username)
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
    if slot_info[:exists] && save_available_for_user?(slot_info, username)
      label = slot_info[:username].to_s.empty? || slot_info[:username].casecmp?('Player') ? "#{format_save_info(slot_info)} [unassigned]" : format_save_info(slot_info)
      puts "  [#{slot}] #{label}"
    elsif slot_info[:exists]
      puts "  #{Color.dim("[#{slot}] [Owned by #{slot_info[:username]}]")}"
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
    
    if slot_info[:exists] && save_available_for_user?(slot_info, username)
      return slot
    elsif slot_info[:exists]
      puts box_line(Color.red("That save belongs to another account."))
      sleep 1
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

def choose_delete_slot(username)
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
    if slot_info[:exists] && save_available_for_user?(slot_info, username)
      puts "  [#{slot}] #{format_save_info(slot_info)}"
    elsif slot_info[:exists]
      puts "  #{Color.dim("[#{slot}] [Owned by #{slot_info[:username]}]")}"
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
    
    if slot_info[:exists] && save_available_for_user?(slot_info, username)
      puts box_line("#{Color.yellow('Are you SURE? Enter')} #{Color.bold('DELETE')} #{Color.yellow('to confirm')}")
      print "> "
      $stdout.flush
      confirm = gets.chomp.downcase
      
      if confirm == 'delete'
        delete_save(slot, username: username)
        puts box_line("#{Color.green('✓')} Save file deleted.")
        sleep 1
      else
        puts box_line("#{Color.dim('Deletion cancelled.')}")
        sleep 1
      end
    elsif slot_info[:exists]
      puts box_line(Color.red("That save belongs to another account."))
      sleep 1
    else
      puts box_line("#{Color.red('That slot is empty.')}")
      sleep 1
    end
  elsif input != 'c'
    puts box_line("#{Color.red('Invalid choice.')}")
    sleep 1
  end
end

def main_menu_with_load(current_username = nil)
  require_relative '../lib/color'
  require_relative '../lib/display'
  require_relative '../lib/save_system'
  
  loop do
    system('clear') || system('cls')
    
    puts ""
    draw_header("H A N G M A N  P L U S")
    puts box_line(Color.dim("Sign-in, accounts, saves, and leaderboard data stay on this device."))
    puts ""
    
    slots = get_save_slots
    has_saves = slots.any? do |_, info|
      info[:exists] && save_available_for_user?(info, current_username)
    end

    if current_username
      puts box_line(Color.green("Signed in as #{current_username}"))
      puts box_line("[N]ew Game")
      puts box_line(has_saves ? Color.bold("[L]oad Game") : Color.dim("[L]oad Game  (No saves for this account)"))
      puts box_line("[W] Play custom word list")
      puts box_line("[R] LAN Play")
      puts box_line("[O] Sign out")
    else
      puts box_line("[S]ign in")
      puts box_line("[A] Create account")
      puts box_line("[R] LAN Play (sign-in required)")
      puts box_line(Color.dim("Sign in or create an account to start/load a game"))
    end
    
    puts box_line("[C]redits")
    puts box_line("[B] Leaderboard")
    puts box_line("[Q]uit")
    puts ""
    print "> "
    $stdout.flush
    input = gets.chomp.downcase
    
    case input
    when 'n'
      if current_username
        profile = prompt_new_game_profile(current_username)
        return { type: :new_game, username: current_username, save_name: profile[:save_name], difficulty_preset: profile[:difficulty_preset] }
      end
      puts Color.yellow("  Sign in or create an account first.")
      sleep 1
    when 'l'
      if !current_username
        puts Color.yellow("  Sign in before loading a save.")
        sleep 1
      elsif has_saves
        chosen_slot = choose_load_slot(current_username)
        return { type: :load, slot: chosen_slot, username: current_username } if chosen_slot
      else
        puts box_line("#{Color.red('No saves found for this account.')}")
        sleep 1.5
      end
    when 'w'
      if current_username
        selection = prompt_custom_word_list(current_username)
        return selection if selection
      else
        puts Color.yellow("  Sign in or create an account first.")
        sleep 1
      end
    when 'r'
      current_username = open_lan_play_from_menu(current_username) || current_username
    when 's'
      current_username = sign_in_from_menu unless current_username
    when 'a'
      current_username = create_account_from_menu unless current_username
    when 'o'
      if current_username
        puts Color.yellow("  Signed out from #{current_username}.")
        current_username = nil
      end
    when 'c'
      show_credits
    when 'b'
      require_relative 'leaderboard'
      open_leaderboard_screen
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
