# Main menu screen
def create_main_menu
  buttons = []

  # Title
  Text.new(
    "Hangman+",
    x: 350,
    y: 100,
    size: 64,
    color: 'yellow'
  )

  # New Game button
  new_game_btn = Button.new(300, 250, 400, 80, "New Game", 'blue')
  buttons << { button: new_game_btn, action: :new_game }

  # Load Game button
  load_game_btn = Button.new(300, 370, 400, 80, "Load Game", 'blue')
  buttons << { button: load_game_btn, action: :load_game }

  # Quit button
  quit_btn = Button.new(300, 490, 400, 80, "Quit", 'red')
  buttons << { button: quit_btn, action: :quit }

  # Instructions
  Text.new(
    "Click a button to continue",
    x: 300,
    y: 650,
    size: 18,
    color: 'yellow'
  )

  buttons
end

# End game screen - shows after winning or losing
def create_end_game_buttons
  buttons = []

  # Next Round button
  next_btn = Button.new(200, 500, 300, 80, "Next Round", 'green')
  buttons << { button: next_btn, action: :next_round }

  # Back to Menu button
  menu_btn = Button.new(550, 500, 300, 80, "Back to Menu", 'red')
  buttons << { button: menu_btn, action: :menu }

  buttons
end
