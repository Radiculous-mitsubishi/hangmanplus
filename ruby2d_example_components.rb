# UI Button Component

class Button
  attr_reader :x, :y, :width, :height
  
  def initialize(x:, y:, width: 200, height: 50, text:, callback: nil, color: 'steelblue', hover_color: 'lightblue')
    @x = x
    @y = y
    @width = width
    @height = height
    @text = text
    @callback = callback
    @color = color
    @hover_color = hover_color
    @hovered = false
    
    # Create visual components
    @rect = Square.new(x: x, y: y, size: width, color: @color, z: 5)
    @text_obj = Text.new(text, x: x + (width / 2) - (text.length * 4), y: y + (height / 2) - 10, size: 20, color: 'white', z: 10)
  end
  
  def draw
    # Update color based on hover state
    color = @hovered ? @hover_color : @color
    
    # Draw background
    Square.new(x: @x, y: @y, size: @width, color: color, z: 5)
    
    # Draw border
    line_width = @hovered ? 2 : 1
    draw_border(line_width)
    
    # Draw text
    @text_obj.draw
  end
  
  def click(mouse_x, mouse_y)
    if clicked?(mouse_x, mouse_y)
      @callback&.call
      return true
    end
    false
  end
  
  def hover(mouse_x, mouse_y)
    @hovered = clicked?(mouse_x, mouse_y)
  end
  
  private
  
  def clicked?(x, y)
    x >= @x && x <= @x + @width &&
    y >= @y && y <= @y + @height
  end
  
  def draw_border(width)
    # Top line
    Line.new(x1: @x, y1: @y, x2: @x + @width, y2: @y, color: 'gold', width: width, z: 6)
    # Bottom line
    Line.new(x1: @x, y1: @y + @height, x2: @x + @width, y2: @y + @height, color: 'gold', width: width, z: 6)
    # Left line
    Line.new(x1: @x, y1: @y, x2: @x, y2: @y + @height, color: 'gold', width: width, z: 6)
    # Right line
    Line.new(x1: @x + @width, y1: @y, x2: @x + @width, y2: @y + @height, color: 'gold', width: width, z: 6)
  end
end

# Info Panel
class InfoPanel
  def initialize(x:, y:, width: 400, height: 200, title:, content:)
    @x = x
    @y = y
    @width = width
    @height = height
    @title = title
    @content = content
  end
  
  def draw
    # Background
    Square.new(x: @x, y: @y, size: @width, color: 'darkslateblue', z: 4)
    
    # Border
    Line.new(x1: @x, y1: @y, x2: @x + @width, y2: @y, color: 'gold', width: 2, z: 5)
    Line.new(x1: @x, y1: @y + @height, x2: @x + @width, y2: @y + @height, color: 'gold', width: 2, z: 5)
    Line.new(x1: @x, y1: @y, x2: @x, y2: @y + @height, color: 'gold', width: 2, z: 5)
    Line.new(x1: @x + @width, y1: @y, x2: @x + @width, y2: @y + @height, color: 'gold', width: 2, z: 5)
    
    # Title
    Text.new(@title, x: @x + 15, y: @y + 10, size: 18, color: 'gold', z: 6)
    
    # Content (supports multiline)
    lines = @content.split("\n")
    lines.each_with_index do |line, idx|
      Text.new(line, x: @x + 15, y: @y + 40 + (idx * 25), size: 14, color: 'white', z: 6)
    end
  end
end
