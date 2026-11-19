# Game logic and state management
class HangmanGame
  attr_accessor :word, :guessed_letters, :wrong_count, :state, :score, :round

  WORDS = ["RUBY", "PYTHON", "JAVASCRIPT", "HANGMAN", "COMPUTER", "ALGORITHM", 
           "DATABASE", "NETWORK", "GRAPHICS", "ANIMATION", "FRAMEWORK", "LIBRARY",
           "FUNCTION", "VARIABLE", "CONSTANT", "TERMINAL", "EDITOR", "COMPILER"]

  def initialize
    @score = 0
    @round = 1
    start_new_round
  end

  def start_new_round
    @word = WORDS.sample.upcase
    @guessed_letters = []
    @wrong_count = 0
    @state = :playing
  end

  def guess(letter)
    letter = letter.upcase
    return false if @guessed_letters.include?(letter)
    
    @guessed_letters << letter
    
    if !@word.include?(letter)
      @wrong_count += 1
    end
    
    check_state
    true
  end

  def check_state
    if @wrong_count >= 6
      @state = :lost
    elsif word_complete?
      @state = :won
      calculate_score
    end
  end

  def word_complete?
    @word.each_char { |char| return false unless @guessed_letters.include?(char) }
    true
  end

  def display_word
    @word.each_char.map { |char| @guessed_letters.include?(char) ? char : '_' }.join(' ')
  end

  def calculate_score
    # Score based on wrong guesses: max 100 points per round
    points = (6 - @wrong_count) * 16 + 4  # (6-0)*16+4=100, (6-6)*16+4=4
    @score += points
  end

  def next_round
    @round += 1
    start_new_round
  end
end
