# Main Menu Screen - Example Ruby2D Screen

class MainMenu < Screen
  def initialize(game_manager)
    super(game_manager)
    @background_color = 'navy'
    setup_ui
  end
  
  def setup_ui
    # Title
    @title = Text.new(
      "HANGMAN+",
      x: 350,
      y: 80,
      size: 72,
      color: 'gold',
      z: 10
    )
    add_text(@title)
    
    # Subtitle
    @subtitle = Text.new(
      "Ruby Terminal Edition",
      x: 380,
      y: 170,
      size: 20,
      color: 'lightblue',
      z: 10
    )
    add_text(@subtitle)
    
    # Divider line
    Line.new(x1: 200, y1: 220, x2: 824, y2: 220, color: 'gold', width: 2, z: 5)
    
    # New Game Button
    new_game_btn = Button.new(
      x: 312,
      y: 300,
      width: 200,
      height: 50,
      text: "New Game",
      callback: -> { @game.change_screen(DifficultyScreen) }
    )
    add_button(new_game_btn)
    
    # Load Game Button
    load_game_btn = Button.new(
      x: 512,
      y: 300,
      width: 200,
      height: 50,
      text: "Load Game",
      callback: -> { @game.change_screen(LoadGameScreen) }
    )
    add_button(load_game_btn)
    
    # Continue Button (if game exists)
    if has_last_save?
      continue_btn = Button.new(
        x: 412,
        y: 380,
        width: 200,
        height: 50,
        text: "Continue",
        callback: -> { load_last_game }
      )
      add_button(continue_btn)
    end
    
    # Options Button
    options_btn = Button.new(
      x: 312,
      y: 460,
      width: 200,
      height: 50,
      text: "Options",
      callback: -> { @game.change_screen(OptionsScreen) }
    )
    add_button(options_btn)
    
    # Quit Button
    quit_btn = Button.new(
      x: 512,
      y: 460,
      width: 200,
      height: 50,
      text: "Quit",
      callback: -> { exit }
    )
    add_button(quit_btn)
    
    # Stats Info Panel
    stats_text = if has_stats?
      stats = load_stats
      "Wins: #{stats[:wins]}\nHighest Score: #{stats[:high_score]}\nGames Played: #{stats[:total_games]}"
    else
      "Start a new game to\ntrack your stats"
    end
    
    @stats_panel = InfoPanel.new(
      x: 150,
      y: 550,
      width: 300,
      height: 180,
      title: "Your Stats",
      content: stats_text
    )
    add_element(@stats_panel)
    
    # Version text
    @version = Text.new(
      "v2.0 - Ruby2D Edition",
      x: 900,
      y: 720,
      size: 12,
      color: 'gray',
      z: 10
    )
    add_text(@version)
  end
  
  def render(window)
    super
    # Draw all components
  end
  
  def update
    # Handle any animations (e.g., pulsing buttons, floating text)
  end
  
  def handle_key_down(key)
    # Handle keyboard shortcuts
    case key
    when 'escape'
      exit
    when 'n'
      @game.change_screen(DifficultyScreen)
    when 'l'
      @game.change_screen(LoadGameScreen)
    when 'o'
      @game.change_screen(OptionsScreen)
    when 'q'
      exit
    end
  end
  
  def handle_mouse_down(x, y)
    super
  end
  
  private
  
  def has_last_save?
    # Check if there's a recent save file
    File.exist?('saves/last_save.json')
  end
  
  def has_stats?
    File.exist?('saves/stats.json')
  end
  
  def load_stats
    begin
      data = JSON.parse(File.read('saves/stats.json'))
      data
    rescue
      {}
    end
  end
  
  def load_last_game
    slot = 1 # or read from config
    @game.state = load_game(slot)[0]
    @game.change_screen(GameScreen)
  end
end
