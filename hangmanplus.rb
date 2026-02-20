class Hangman
  attr_accessor :word, :attempts, :max_attempts, :streak, :extra_life, :consumable_keys

  def initialize(word)
    @word = word
    @attempts = []
    @max_attempts = 6
    @streak = 0
    @extra_life = false
    @consumable_keys = [] # This will keep track of consumable keys
  end

  def guess(letter)
    return if @attempts.include?(letter) || !letter.match?(/[a-zA-Z]/)
    @attempts << letter
    check_if_used_consumable(letter)
  end

  def check_if_used_consumable(letter)
    # If user guesses a consumable key, track it
    consumable_keys << letter if ['@', '#', '$', '%', '&'].include?(letter)
  end

  def display
    display_word = @word.chars.map { |char| @attempts.include?(char) ? char : '_' }.join(' ')
    puts display_word
    puts "Attempts: #{@attempts.join(', ')}"
    puts "Streak: #{@streak}"
    puts "Extra Life: #{@extra_life ? 'Active' : 'Inactive'}"
    puts "Consumable Keys Used: #{@consumable_keys.join(', ')}"
  end

  def check_game_over
    if won?
      @streak += 1
      puts "You won!\n"
    elsif lost?
      puts "You lost!\n"
    end
  end

  def won?
    (@word.chars - @attempts).empty?
  end

  def lost?
    @attempts.length >= @max_attempts
  end
end

# Example Usage:
# game = Hangman.new('example')
# game.guess('e')
# game.display
# game.check_game_over