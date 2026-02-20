# hangmanplus.rb

# Existing code above...

# Implementing the consumable menu feature
class HangmanPlus
  def initialize
    @consumables = []
  end

  def start
    loop do
      display_menu
      input = gets.chomp
      if input == '+'
        display_consumable_menu
      else
        process_guess(input)
      end
    end
  end

  def display_consumable_menu
    puts "--- Consumable Menu ---"
    @consumables.each_with_index do |item, index|
      puts "#{index + 1}: #{item}"
    end
    puts "Press any key to go back to the game..."
    gets.chomp # Wait for user input to return
  end

  def process_guess(input)
    # Existing guess processing logic...
  end

  # Other existing methods...
end

# Existing code below...