# Ruby2D Hangman+ Setup Guide

## Prerequisites

Make sure you have:
- Ruby 2.7+
- Bundler installed
- SDL2 libraries (required by ruby2d)

### Install SDL2

**Windows (with Chocolatey):**
```bash
choco install sdl2
```

**Windows (manual):**
- Download from https://libsdl.org/download-2.0.php
- Follow installation instructions

**macOS:**
```bash
brew install sdl2
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install libsdl2-dev
```

## Project Setup

### Step 1: Create Ruby2D Project Structure

```bash
mkdir hangmanplus_ruby2d
cd hangmanplus_ruby2d

# Create folders
mkdir -p config lib/ui screens game assets/fonts
```

### Step 2: Create Gemfile

```ruby
# Gemfile
source 'https://rubygems.org'

ruby '2.7.0'

# Ruby2D Graphics
gem 'ruby2d', '~> 1.4'

# File handling
gem 'json'

# Optional: Development tools
group :development do
  gem 'pry'
  gem 'rubocop'
end
```

### Step 3: Install Dependencies

```bash
bundle install
```

### Step 4: Copy Core Game Files

From your terminal version, copy:
```
config/constants.rb      → config/
config/items.rb          → config/
lib/save_system.rb       → lib/
game/difficulty.rb       → game/
```

(These files will need minor updates but the logic is preserved)

## File Structure

```
hangmanplus_ruby2d/
├── Gemfile                          # Dependencies
├── Gemfile.lock
├── main.rb                          # Entry point
├── config/
│   ├── constants.rb                 # Game constants (reused)
│   ├── items.rb                     # Shop items (reused)
│   └── colors.rb                    # Ruby2D color palette
├── lib/
│   ├── ui/
│   │   ├── button.rb               # Button component
│   │   ├── panel.rb                # Info panel
│   │   └── components.rb           # Other UI elements
│   ├── save_system.rb              # Save/load (reused)
│   └── game_state.rb               # State manager
├── screens/
│   ├── screen.rb                   # Base screen class
│   ├── main_menu.rb                # Main menu
│   ├── game_screen.rb              # Gameplay
│   ├── shop_screen.rb              # Shop
│   ├── inventory_screen.rb         # Cards/inventory
│   ├── slots_screen.rb             # Slot machine
│   ├── pause_screen.rb             # Pause menu
│   └── difficulty_screen.rb        # Difficulty select
├── game/
│   ├── game.rb                     # Game logic (adapted)
│   ├── round.rb                    # Round logic (adapted)
│   └── difficulty.rb               # Difficulty (reused)
├── assets/
│   └── fonts/                      # Font files
└── saves/                          # Save files (generated)
```

## Ruby2D Color Reference

```ruby
# Use in Ruby2D like this:
Text.new("Hello", color: 'gold')
Square.new(x: 100, y: 100, size: 50, color: 'steelblue')

# Available colors:
# 'navy', 'steelblue', 'darkslateblue', 'gold', 'yellow', 'lightblue'
# 'white', 'gray', 'darkgray', 'red', 'darkred', 'green', 'darkgreen'
# 'lightgreen', 'orange', 'crimson', etc.
```

## Key Differences from Terminal Version

### Input Handling

**Terminal Version:**
```ruby
ch = $stdin.getch.downcase
```

**Ruby2D Version:**
```ruby
on :key_down do |event|
  game.handle_key_down(event.key)
end

on :mouse_down do |event|
  game.handle_mouse_down(event.x, event.y)
end
```

### Rendering

**Terminal Version:**
```ruby
puts Color.bold(Color.green("Success!"))
```

**Ruby2D Version:**
```ruby
Text.new("Success!", x: 100, y: 100, size: 20, color: 'green')
```

### Screen Management

**Terminal Version:**
```ruby
loop do
  system('clear')
  puts header
  # ... render menu ...
end
```

**Ruby2D Version:**
```ruby
on :draw do
  current_screen.render(window)
  current_screen.update
end
```

## Running the Game

```bash
ruby main.rb
```

## Development Tips

### 1. Test Components Individually
```ruby
# Create test file to verify button works
require './lib/ui/button'

# Draw button on screen
```

### 2. Use Pry for Debugging
```ruby
require 'pry'
# Add breakpoints:
binding.pry
```

### 3. Create Helper Methods
```ruby
def draw_header(text, size: 48)
  Text.new(text, x: 512 - (text.length * 15), y: 50, size: size, color: 'gold')
end

def draw_divider(y)
  Line.new(x1: 20, y1: y, x2: 1004, y2: y, color: 'gold', width: 2)
end
```

### 4. Screen Transitions
```ruby
# Switch to shop screen
@game.change_screen(ShopScreen)

# Pass data between screens
@game.change_screen(GameScreen, category: "Animals", word: "elephant", difficulty: :easy)
```

## Common Issues

### Issue: "Can't load SDL2"
**Solution:** Make sure SDL2 is installed (see Prerequisites)

### Issue: "Window doesn't appear"
**Solution:** Check Ruby2D version compatibility and try updating:
```bash
bundle update ruby2d
```

### Issue: "Text looks blurry"
**Solution:** Use even numbers for coordinates and sizes for crisp rendering

### Issue: "Buttons not responding"
**Solution:** Ensure mouse coordinates are checked correctly and button bounds are set right

## Example: Hello World in Ruby2D

```ruby
#!/usr/bin/env ruby
require 'ruby2d'

set title: "Hangman+", width: 800, height: 600, background: 'navy'

Text.new(
  "Hello, Hangman+!",
  x: 250,
  y: 250,
  size: 48,
  color: 'gold'
)

show
```

Save as `hello.rb` and run:
```bash
ruby hello.rb
```

## Resources

- **Ruby2D Docs**: https://www.ruby2d.com/
- **Ruby2D Examples**: https://github.com/ruby2d/ruby2d/tree/master/samples
- **SDL2 Documentation**: https://wiki.libsdl.org/

## Next Steps

1. Set up the project structure
2. Test basic Ruby2D window
3. Create UI components
4. Port screens one by one
5. Integrate game logic
6. Test and polish

Good luck! 🎮
