# Game screen - displays Hangman game
def create_game_screen(game)
  # Title with round and score
  Text.new(
    "Hangman+ - Round #{game.round}",
    x: 250,
    y: 30,
    size: 48,
    color: 'yellow'
  )

  # Score display
  Text.new(
    "Score: #{game.score}",
    x: 750,
    y: 50,
    size: 32,
    color: 'lime'
  )

  # Hangman drawing
  draw_hangman(game.wrong_count)

  # Display word
  Text.new(
    game.display_word,
    x: 200,
    y: 150,
    size: 48,
    color: 'white'
  )

  # Wrong guesses counter
  Text.new(
    "Wrong: #{game.wrong_count} / 6",
    x: 400,
    y: 250,
    size: 24,
    color: 'red'
  )

  # Create letter buttons
  letter_buttons = create_letter_buttons(game.guessed_letters)
  
  letter_buttons
end

def draw_hangman(stage)
  # Base
  Line.new(x1: 100, y1: 600, x2: 300, y2: 600, color: 'white', width: 3)
  # Pole
  Line.new(x1: 150, y1: 600, x2: 150, y2: 100, color: 'white', width: 3)
  # Top rope
  Line.new(x1: 150, y1: 100, x2: 300, y2: 100, color: 'white', width: 3)
  # Rope
  Line.new(x1: 300, y1: 100, x2: 300, y2: 150, color: 'white', width: 2)
  
  return if stage < 1
  # Head
  Circle.new(x: 300, y: 170, radius: 20, color: 'white')
  
  return if stage < 2
  # Body
  Line.new(x1: 300, y1: 190, x2: 300, y2: 280, color: 'white', width: 3)
  
  return if stage < 3
  # Left arm
  Line.new(x1: 300, y1: 210, x2: 260, y2: 230, color: 'white', width: 2)
  
  return if stage < 4
  # Right arm
  Line.new(x1: 300, y1: 210, x2: 340, y2: 230, color: 'white', width: 2)
  
  return if stage < 5
  # Left leg
  Line.new(x1: 300, y1: 280, x2: 270, y2: 320, color: 'white', width: 2)
  
  return if stage < 6
  # Right leg
  Line.new(x1: 300, y1: 280, x2: 330, y2: 320, color: 'white', width: 2)
end

def create_letter_buttons(guessed_letters)
  buttons = []
  letters = ('A'..'Z').to_a
  x_start = 50
  y_start = 450
  btn_width = 35
  btn_height = 35
  spacing = 5

  letters.each_with_index do |letter, index|
    row = index / 13
    col = index % 13
    x = x_start + (col * (btn_width + spacing))
    y = y_start + (row * (btn_height + spacing))

    color = guessed_letters.include?(letter) ? 'gray' : 'blue'
    btn = Button.new(x, y, btn_width, btn_height, letter, color)
    buttons << { button: btn, letter: letter }
  end

  buttons
end
