# Button class for reusable buttons
class Button
  attr_accessor :x, :y, :width, :height, :text, :color, :hovered

  def initialize(x, y, width, height, text, color = 'blue')
    @x = x
    @y = y
    @width = width
    @height = height
    @text = text
    @color = color
    @hovered = false
    @rect = Rectangle.new(x: @x, y: @y, width: @width, height: @height, color: @color)
    
    # Adjust text size based on button size
    text_size = @width > 100 ? 28 : 20
    text_x = @x + (@width / 2) - (@text.length * text_size / 4)
    text_y = @y + (@height / 2) - 10
    
    @text_obj = Text.new(@text, x: text_x, y: text_y, size: text_size, color: 'white')
  end

  def draw
    # Already drawn in initialize, but we'll update color if hovered
    @rect.color = @hovered ? 'lime' : @color
  end

  def clicked?(mouse_x, mouse_y)
    mouse_x >= @x && mouse_x <= (@x + @width) &&
    mouse_y >= @y && mouse_y <= (@y + @height)
  end

  def hover?(mouse_x, mouse_y)
    @hovered = clicked?(mouse_x, mouse_y)
  end

  def remove
    @rect.remove
    @text_obj.remove
  end
end
