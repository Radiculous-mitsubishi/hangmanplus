# HangmanPlus - Refactored Structure

## Overview
The game has been reorganized into a clean folder structure that separates concerns and improves maintainability. The game logic, UI, and data are now in separate modules.

## Folder Structure

```
hangmanplus/
├── hangmanplus.rb              # Main entry point - runs the game
├── hangmanplus_original.rb     # Backup of original monolithic file
│
├── lib/                        # Shared utilities and helpers
│   ├── color.rb                # Color module for terminal colors
│   └── display.rb              # UI drawing functions (boxes, HUD, screens)
│
├── config/                     # Game data and constants
│   ├── constants.rb            # Game constants (CATEGORIES, HANGMAN, BASE_MAX_WRONG)
│   └── items.rb                # Shop items and skill cards definitions
│
├── game/                       # Core game logic
│   ├── game.rb                 # Main game loop and state initialization
│   ├── round.rb                # Single round gameplay logic
│   └── difficulty.rb           # Difficulty selection and progression
│
└── menus/                      # Menu systems and UI interactions
    ├── consumables.rb          # Consumable items menu (Reveal, Extra Life, etc.)
    ├── inventory.rb            # Skill card inventory and card rendering
    ├── shop.rb                 # Shop menu and purchasing system
    ├── slots.rb                # Slot machine mini-game
    └── dev.rb                  # Developer menu for testing/debugging
```

## How It Works

### Entry Point
- **hangmanplus.rb** - The main script you run. It loads all modules and calls `main()`

### Library Files (lib/)
- **color.rb** - Provides the `Color` module with terminal color methods
- **display.rb** - Contains all UI drawing functions: boxes, HUD, game screen, etc.

### Configuration Files (config/)
- **constants.rb** - Word categories, hangman stages, slot symbols, and game constants
- **items.rb** - Shop items, skill card definitions, and card rarity configuration

### Game Logic (game/)
- **game.rb** - Main game loop, state initialization, round progression, and difficulty transitions
- **round.rb** - Play a single round: guess letters, track streaks, handle consumables
- **difficulty.rb** - Choose difficulty level, select categories, show difficulty unlock prompts

### Menu Systems (menus/)
- **consumables.rb** - Use consumable items during gameplay
- **inventory.rb** - View collected skill cards, card details, animations, and rarity filters
- **shop.rb** - Purchase consumables and permanent upgrades with points
- **slots.rb** - Slot machine mini-game to earn skill cards
- **dev.rb** - Developer tools for testing (add points, cards, change difficulty, etc.)

## Key Design Decisions

1. **Separation of Concerns**
   - Game logic is separate from UI
   - Display functions don't contain game state logic
   - Configuration is in dedicated files

2. **Modular Menus**
   - Each menu system is its own file
   - Menus can be required on-demand from game flow
   - Makes it easy to add new menus or modify existing ones

3. **Centralized Constants**
   - All game data (categories, items, cards) in `config/`
   - Easy to tweak game balance
   - Simple to add new content

4. **Minimal Dependencies**
   - Each file requires what it needs
   - Circular dependencies handled by on-demand requires in functions
   - `hangmanplus.rb` is the only true entry point

## Running the Game

```bash
ruby hangmanplus.rb
```

## Modifying the Game

- **Add a new word category?** Edit `config/constants.rb`
- **Change shop prices?** Edit `config/items.rb`
- **Add a new skill card?** Edit `config/items.rb`
- **Modify game difficulty?** Edit `game/difficulty.rb`
- **Change UI appearance?** Edit `lib/display.rb`
- **Add a new menu?** Create a new file in `menus/` and require it from the appropriate game flow location
- **Change colors?** Edit `lib/color.rb`

## Original File

The original monolithic `hangmanplus_original.rb` is kept as a backup. You can compare against it if needed or revert to it if desired.
