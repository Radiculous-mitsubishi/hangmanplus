# Hangman+ Ruby2D Conversion Guide

## Project Structure

```
hangmanplus_ruby2d/
├── Gemfile
├── main.rb                          # Entry point
├── config/
│   ├── constants.rb                 # (reuse from terminal)
│   ├── items.rb                     # (reuse from terminal)
│   └── colors.rb                    # Ruby2D color palette
├── lib/
│   ├── ui/
│   │   ├── button.rb               # Clickable button component
│   │   ├── text_field.rb           # Text input component
│   │   ├── panel.rb                # UI panel/container
│   │   └── components.rb           # Reusable UI elements
│   ├── save_system.rb              # (mostly reuse)
│   └── game_state.rb               # State management
├── screens/
│   ├── screen.rb                   # Base screen class
│   ├── main_menu.rb                # Main menu screen
│   ├── game_screen.rb              # Gameplay screen
│   ├── shop_screen.rb              # Shop screen
│   ├── inventory_screen.rb         # Inventory screen
│   ├── slots_screen.rb             # Slot machine screen
│   └── pause_screen.rb             # Pause/settings screen
├── game/
│   ├── game.rb                     # (reuse logic, adapt rendering)
│   ├── round.rb                    # (reuse logic, adapt rendering)
│   └── difficulty.rb               # (reuse logic)
└── assets/
    └── (fonts, later if needed)
```

## Key Differences from Terminal Version

### 1. **No Terminal I/O**
- Replace: `puts`, `print`, `gets`, `getch`
- Use: Ruby2D text rendering, window drawing

### 2. **Event-Driven Input**
- Replace: Blocking input with `getch`
- Use: Ruby2D's `on :key_down` events

### 3. **Visual State Management**
- Replace: Screen clears with `system('clear')`
- Use: Scene/screen system that only redraws changed elements

### 4. **Color & Styling**
- Replace: ANSI color codes
- Use: Ruby2D color system (RGB/Hex)

## Architecture Approach

### Screen System
```ruby
class Screen
  def initialize(game_state)
    @game_state = game_state
    @drawn_elements = []
  end
  
  def render(window)
    # Clear and redraw screen
    @drawn_elements.each { |e| e.draw(window) }
  end
  
  def handle_input(key, mouse_pos)
    # Process user input
  end
  
  def update
    # Update animations/state
  end
end
```

### Component System
```ruby
class UIButton
  def initialize(x, y, width, height, text, &callback)
    @rect = [x, y, width, height]
    @text = text
    @callback = callback
    @hovered = false
  end
  
  def draw(window)
    # Draw button with hover effect
  end
  
  def click(x, y)
    @callback.call if clicked?(x, y)
  end
  
  def mouse_move(x, y)
    @hovered = clicked?(x, y)
  end
end
```

## Conversion Steps (Simplified)

### Phase 1: Core Setup
1. Create Ruby2D window
2. Implement screen manager
3. Port main menu (non-interactive first)

### Phase 2: Interactive UI
1. Create button/input components
2. Port main menu with functionality
3. Add game screen rendering

### Phase 3: Gameplay
1. Adapt round logic to render graphically
2. Create Hangman drawing system
3. Implement letter buttons/input

### Phase 4: Menus
1. Port shop screen
2. Port inventory/cards screen
3. Add animations

## Code Size Estimate
- **Ruby2D Framework**: ~400-500 lines
- **Screen System**: ~200-300 lines
- **UI Components**: ~300-400 lines
- **Screen Implementations**: ~1000-1500 lines
- **Adapted Game Logic**: ~500-700 lines (mostly reuse)
- **Total**: ~2500-3500 lines (vs ~1800 terminal)

## Development Timeline
- Setup & Basic Window: 1-2 hours
- Screen System & Components: 2-3 hours
- Main Menu Port: 1-2 hours
- Game Screen: 3-4 hours
- Shop/Menus: 2-3 hours
- Polish & Testing: 2-3 hours
- **Total: 11-17 hours**

## Reusable Code
These can stay almost unchanged:
- `game/game.rb` (core logic)
- `game/round.rb` (game loop logic)
- `game/difficulty.rb` (difficulty handling)
- `config/constants.rb` (item/card definitions)
- `lib/save_system.rb` (save/load)

## New Dependencies
```ruby
# Gemfile
source 'https://rubygems.org'

gem 'ruby2d', '~> 1.4'
```

## Key Advantages of Ruby2D Port
✓ More polished appearance
✓ Better animations
✓ Mouse support (more accessible)
✓ Can export as standalone app
✓ Better for distribution
✓ Potential mobile port later (with additional tools)
