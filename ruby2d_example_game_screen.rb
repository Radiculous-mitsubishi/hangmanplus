# Game Screen - Main Gameplay in Ruby2D

class GameScreen < Screen
  LETTER_BUTTON_WIDTH = 30
  LETTER_BUTTON_HEIGHT = 30
  BUTTON_SPACING = 35
  
  def initialize(game_manager, category:, word:, difficulty:)
    super(game_manager)
    @category = category
    @word = word
    @difficulty = difficulty
    @guessed_letters = []
    @wrong_letters = []
    @wrong_count = 0
    @max_wrong = 6
    
    # Reuse game logic from terminal version
    @game_logic_state = {
      streak: @game.state[:streak],
      score: @game.state[:score]
    }
    
    setup_ui
  end
  
  def setup_ui
    # Header showing difficulty and category
    @difficulty_text = Text.new(
      "Difficulty: #{@difficulty.to_s.upcase}",
      x: 20,
      y: 20,
      size: 18,
      color: difficulty_color(@difficulty),
      z: 10
    )
    
    @category_text = Text.new(
      "Category: #{@category}",
      x: 20,
      y: 50,
      size: 16,
      color: 'lightblue',
      z: 10
    )
    
    # Draw the hangman gallows
    draw_gallows
    
    # Word display
    draw_word_display
    
    # Wrong letters display
    @wrong_letters_text = Text.new(
      "",
      x: 550,
      y: 250,
      size: 14,
      color: 'red',
      z: 10
    )
    
    # Letter buttons (A-Z)
    setup_letter_buttons
    
    # Stats display
    draw_stats
    
    # Menu button
    pause_btn = Button.new(
      x: 900,
      y: 20,
      width: 100,
      height: 40,
      text: "Menu",
      callback: -> { @game.change_screen(PauseScreen, self) }
    )
    add_button(pause_btn)
  end
  
  def draw_gallows
    # Draw ASCII-style hangman using Ruby2D shapes
    # Gallows structure
    Line.new(x1: 400, y1: 320, x2: 400, y2: 150, color: 'gold', width: 3, z: 5)  # Post
    Line.new(x1: 400, y1: 150, x2: 500, y2: 150, color: 'gold', width: 3, z: 5)  # Top beam
    Line.new(x1: 500, y1: 150, x2: 500, y2: 170, color: 'gold', width: 2, z: 5)  # Rope
    
    # Draw hangman based on wrong count
    wrong_count = @wrong_letters.length
    
    if wrong_count >= 1
      # Head
      Circle.new(x: 500, y: 180, radius: 12, color: 'white', z: 5)
    end
    
    if wrong_count >= 2
      # Body
      Line.new(x1: 500, y1: 195, x2: 500, y2: 240, color: 'white', width: 2, z: 5)
    end
    
    if wrong_count >= 3
      # Left arm
      Line.new(x1: 500, y1: 210, x2: 475, y2: 225, color: 'white', width: 2, z: 5)
    end
    
    if wrong_count >= 4
      # Right arm
      Line.new(x1: 500, y1: 210, x2: 525, y2: 225, color: 'white', width: 2, z: 5)
    end
    
    if wrong_count >= 5
      # Left leg
      Line.new(x1: 500, y1: 240, x2: 480, y2: 270, color: 'white', width: 2, z: 5)
    end
    
    if wrong_count >= 6
      # Right leg (death)
      Line.new(x1: 500, y1: 240, x2: 520, y2: 270, color: 'red', width: 2, z: 5)
      # Eyes (X)
      Text.new("X", x: 495, y: 175, size: 12, color: 'red', z: 6)
      Text.new("X", x: 503, y: 175, size: 12, color: 'red', z: 6)
    end
  end
  
  def draw_word_display
    display = @word.chars.map do |letter|
      if @guessed_letters.include?(letter)
        letter.upcase
      else
        "_"
      end
    end.join(" ")
    
    @word_text = Text.new(
      display,
      x: 600,
      y: 200,
      size: 32,
      color: 'yellow',
      z: 10
    )
  end
  
  def setup_letter_buttons
    letters = ('A'..'Z').to_a
    letters.each_with_index do |letter, idx|
      row = idx / 7
      col = idx % 7
      x = 200 + (col * BUTTON_SPACING)
      y = 350 + (row * BUTTON_SPACING)
      
      btn = Button.new(
        x: x,
        y: y,
        width: LETTER_BUTTON_WIDTH,
        height: LETTER_BUTTON_HEIGHT,
        text: letter,
        callback: -> { guess_letter(letter) },
        color: letter_button_color(letter)
      )
      add_button(btn)
    end
  end
  
  def draw_stats
    stats_text = "Score: #{@game.state[:score]} pts  |  Streak: #{@game_logic_state[:streak]}x"
    @stats_text = Text.new(
      stats_text,
      x: 200,
      y: 750,
      size: 16,
      color: 'lightgreen',
      z: 10
    )
  end
  
  def guess_letter(letter)
    return if @guessed_letters.include?(letter) || @wrong_letters.include?(letter)
    
    letter_lower = letter.downcase
    
    if @word.include?(letter_lower)
      @guessed_letters << letter_lower
      # Award points (using scaled difficulty multiplier)
      points = calculate_points
      @game.state[:score] += points
    else
      @wrong_letters << letter
      @wrong_count += 1
    end
    
    check_win_loss
    setup_ui  # Refresh UI
  end
  
  def calculate_points
    # Reuse logic from terminal version
    base = 1 + (@game.state[:permanent_bonuses][:bonus_point] || 0)
    eff = @game_logic_state[:streak]
    difficulty_mult = get_difficulty_multiplier(@difficulty)
    (base * eff * difficulty_mult).round
  end
  
  def check_win_loss
    if @word.chars.all? { |c| @guessed_letters.include?(c) }
      # Won!
      @game.state[:wins] += 1
      @game.state[:streak] += 1
      @game.change_screen(RoundWinScreen, self)
    elsif @wrong_count >= @max_wrong
      # Lost!
      @game.state[:losses] += 1
      @game.state[:streak] = 1
      @game.change_screen(RoundLossScreen, self)
    end
  end
  
  def render(window)
    # Draw background
    Square.new(x: 0, y: 0, size: 2000, color: 'navy', z: 0)
    
    # Draw UI
    draw_gallows
    draw_word_display
    
    super
  end
  
  def update
    # Handle animations
  end
  
  def handle_key_down(key)
    if key.match?(/^[a-z]$/i)
      guess_letter(key.upcase)
    elsif key == 'escape'
      @game.change_screen(PauseScreen, self)
    end
  end
  
  private
  
  def difficulty_color(difficulty)
    case difficulty
    when :easy then 'green'
    when :medium then 'yellow'
    when :hard then 'orange'
    when :extreme then 'red'
    else 'white'
    end
  end
  
  def letter_button_color(letter)
    if @guessed_letters.include?(letter.downcase)
      'darkgreen'
    elsif @wrong_letters.include?(letter)
      'darkred'
    else
      'steelblue'
    end
  end
  
  def get_difficulty_multiplier(difficulty)
    case difficulty
    when :easy then 1.0
    when :medium then 1.5
    when :hard then 2.0
    when :extreme then 2.5
    else 1.0
    end
  end
end
