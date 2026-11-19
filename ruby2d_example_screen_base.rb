# Base Screen Class - All screens inherit from this

class Screen
  PADDING = 20
  
  def initialize(game_manager)
    @game = game_manager
    @elements = []
    @buttons = []
    @text_objects = []
    @background_color = 'navy'
  end
  
  def render(window)
    # Draw background
    Square.new(x: 0, y: 0, size: 2000, color: @background_color, z: 0)
    
    # Draw all UI elements
    @elements.each { |e| e.draw }
    @text_objects.each { |t| t.draw }
    @buttons.each { |b| b.draw }
  end
  
  def update
    # Override for animation/updates
  end
  
  def handle_key_down(key)
    # Override in subclasses
  end
  
  def handle_mouse_down(x, y)
    @buttons.each { |btn| btn.click(x, y) }
  end
  
  def handle_mouse_move(x, y)
    @buttons.each { |btn| btn.hover(x, y) }
  end
  
  # Helper methods for consistent styling
  protected
  
  def draw_header(text, y: 50, size: 36)
    Text.new(text, x: 512 - (text.length * 10), y: y, size: size, color: 'gold', z: 10)
  end
  
  def draw_title(text, y: 100)
    # Bold title with shadow effect
    Text.new(text, x: 30, y: y, size: 48, color: 'gold', z: 10)
  end
  
  def draw_divider(y)
    Line.new(x1: 20, y1: y, x2: 1004, y2: y, color: 'gray', width: 1, z: 5)
  end
  
  def add_button(btn)
    @buttons << btn
  end
  
  def add_text(text_obj)
    @text_objects << text_obj
  end
  
  def add_element(element)
    @elements << element
  end
end
