# Shop Screen - Example of Menu UI in Ruby2D

class ShopScreen < Screen
  def initialize(game_manager)
    super(game_manager)
    @background_color = 'navy'
    @selected_item = nil
    @scroll_offset = 0
    setup_ui
  end
  
  def setup_ui
    # Title
    @title = Text.new(
      "SHOP",
      x: 450,
      y: 30,
      size: 48,
      color: 'gold',
      z: 10
    )
    
    # Points display
    @points_text = Text.new(
      "Points: #{@game.state[:score]} pts",
      x: 50,
      y: 80,
      size: 20,
      color: 'lightgreen',
      z: 10
    )
    
    # Item list
    create_item_buttons
    
    # Item detail panel
    @detail_panel = InfoPanel.new(
      x: 650,
      y: 200,
      width: 340,
      height: 500,
      title: "Item Details",
      content: "Select an item\nto view details"
    )
    add_element(@detail_panel)
    
    # Back button
    back_btn = Button.new(
      x: 900,
      y: 700,
      width: 100,
      height: 50,
      text: "Back",
      callback: -> { @game.change_screen(GameScreen) }
    )
    add_button(back_btn)
  end
  
  def create_item_buttons
    SHOP_ITEMS.each_with_index do |item, idx|
      # Calculate item cost with scaling
      cost = calculate_item_cost(item[:cost], item, @game.state)
      can_afford = @game.state[:score] >= cost
      
      btn = Button.new(
        x: 80,
        y: 150 + (idx * 70),
        width: 550,
        height: 60,
        text: "#{item[:emoji]} #{item[:name]} - #{cost}pts",
        callback: -> { purchase_item(item, cost) },
        color: can_afford ? 'steelblue' : 'darkgray',
        hover_color: can_afford ? 'lightblue' : 'darkgray'
      )
      add_button(btn)
    end
  end
  
  def calculate_item_cost(base_cost, item, state)
    if item[:type] == :permanent
      level = state[:permanent_bonuses][item[:id]] || 0
      scaled_cost = (base_cost * (1 + level * 0.5)).round
    else
      qty = state[:inventory][item[:id]] || 0
      scaled_cost = (base_cost * (1 + qty * 0.2)).round
    end
    
    if state[:score] > 1000
      wealth_multiplier = 1 + ((state[:score] - 1000) / 500) * 0.05
      scaled_cost = (scaled_cost * wealth_multiplier).round
    end
    
    scaled_cost
  end
  
  def purchase_item(item, cost)
    if @game.state[:score] < cost
      show_notification("Not enough points!", 'red')
      return
    end
    
    @game.state[:score] -= cost
    
    if item[:type] == :permanent
      @game.state[:permanent_bonuses][item[:id]] ||= 0
      @game.state[:permanent_bonuses][item[:id]] += 1
      show_notification("Upgraded #{item[:name]}!", 'green')
    else
      @game.state[:inventory][item[:id]] ||= 0
      @game.state[:inventory][item[:id]] += 1
      show_notification("Purchased #{item[:name]}!", 'green')
    end
    
    # Refresh UI
    @buttons.clear
    @text_objects.clear
    setup_ui
  end
  
  def show_notification(message, color = 'yellow')
    # Display a temporary notification
    notif = Text.new(
      message,
      x: 512 - (message.length * 6),
      y: 680,
      size: 18,
      color: color,
      z: 20
    )
    add_text(notif)
    
    # TODO: Add fade-out timer
  end
  
  def render(window)
    super
  end
  
  def update
    # Handle animations
  end
  
  def handle_key_down(key)
    case key
    when 'escape', 'b'
      @game.change_screen(GameScreen)
    when 'up'
      @scroll_offset -= 70
    when 'down'
      @scroll_offset += 70
    end
  end
  
  def handle_mouse_down(x, y)
    super
  end
end

# Inventory Screen - View owned skill cards
class InventoryScreen < Screen
  def initialize(game_manager)
    super(game_manager)
    @background_color = 'navy'
    setup_ui
  end
  
  def setup_ui
    # Title
    @title = Text.new(
      "SKILL CARDS",
      x: 400,
      y: 30,
      size: 48,
      color: 'gold',
      z: 10
    )
    
    # Card count
    card_count = @game.state[:skill_cards].length
    @count_text = Text.new(
      "Cards: #{card_count}",
      x: 50,
      y: 80,
      size: 18,
      color: 'lightblue',
      z: 10
    )
    
    # Display active skills
    create_card_displays
    
    # Back button
    back_btn = Button.new(
      x: 900,
      y: 700,
      width: 100,
      height: 50,
      text: "Back",
      callback: -> { @game.change_screen(GameScreen) }
    )
    add_button(back_btn)
  end
  
  def create_card_displays
    active_cards = @game.state[:active_skills] || []
    
    active_cards.each_with_index do |card, idx|
      # Create visual card representation
      card_panel = InfoPanel.new(
        x: 50 + (idx % 3) * 300,
        y: 150 + (idx / 3) * 250,
        width: 280,
        height: 220,
        title: card[:name],
        content: "Rarity: #{card[:rarity]}\n#{card[:description]}"
      )
      add_element(card_panel)
    end
  end
  
  def render(window)
    super
  end
  
  def handle_key_down(key)
    case key
    when 'escape', 'b'
      @game.change_screen(GameScreen)
    end
  end
end
