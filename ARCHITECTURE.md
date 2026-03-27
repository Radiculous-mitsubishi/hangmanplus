# HangmanPlus Game Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    hangmanplus.rb                           │
│                   (Entry Point)                             │
└────────────────────┬────────────────────────────────────────┘
                     │
       ┌─────────────┼─────────────┬─────────────────┐
       ▼             ▼             ▼                 ▼
   ┌───────┐    ┌─────────┐   ┌────────┐      ┌─────────────┐
   │  lib/ │    │ config/ │   │ game/  │      │   menus/    │
   ├───────┤    ├─────────┤   ├────────┤      ├─────────────┤
   │color. │    │constants│   │game.rb │      │consumables. │
   │rb     │    │.rb      │   │        │      │rb           │
   │       │    │         │   │(entry) │      │             │
   │display│    │items.rb │   ├────────┤      │inventory.rb │
   │.rb    │    │         │   │round.rb│      │(skills &    │
   │       │    │(data &  │   │        │      │ cards)      │
   │(UI)   │    │ items)  │   ├────────┤      │             │
   └───────┘    └─────────┘   │        │      │shop.rb      │
                               │difficu│      │(shop &      │
                               │lty.rb │      │ purchasing) │
                               │        │      │             │
                               └────────┘      │slots.rb     │
                                               │(mini-game) │
                                               │             │
                                               │dev.rb       │
                                               │(debugging)  │
                                               └─────────────┘
```

## File Organization by Purpose

### Core Game Loop
```
game/game.rb
  ├─ Initializes state
  ├─ Main event loop
  ├─ Handles win/loss progression
  └─ Triggers skill card rolls every 5 wins
```

### Gameplay
```
game/round.rb
  ├─ Letter guessing logic
  ├─ Streak/points calculation
  ├─ Wrong letter tracking
  ├─ Integration with consumables menu
  └─ Round win/lose determination
```

### Progression
```
game/difficulty.rb
  ├─ Easy/Medium/Hard/Extreme selection
  ├─ Category selection
  ├─ Difficulty unlock prompts
  └─ Difficulty-based word selection
```

### User Interface
```
lib/display.rb
  ├─ Game screen rendering
  ├─ HUD (score, streak, inventory)
  ├─ Box layouts and borders
  ├─ Hangman ASCII art
  └─ Text formatting utilities

lib/color.rb
  └─ Terminal color codes and formatting
```

### Data
```
config/constants.rb
  ├─ 16 word categories with 30+ words each
  ├─ ASCII hangman stages
  └─ Game constants

config/items.rb
  ├─ 5 shop items definitions
  ├─ 20+ skill cards (common to mythic)
  ├─ Gold card (completion reward)
  ├─ Card rarity configurations
  └─ Stackable card definitions
```

### Menus
```
menus/consumables.rb
  ├─ Consumable item selection
  ├─ Use item functions (reveal, extra life, etc.)
  └─ Inventory management during round

menus/inventory.rb
  ├─ Skill card collection view
  ├─ Card detail view
  ├─ Sorting (by rarity/name)
  ├─ Filtering by rarity
  ├─ Card rendering with animations
  └─ Rarity-based styling

menus/shop.rb
  ├─ Item purchasing interface
  ├─ Permanent upgrade purchases
  ├─ Consumable purchasing
  └─ Slot machine access

menus/slots.rb
  ├─ Slot machine UI
  ├─ Spin animation
  ├─ Win/loss determination
  └─ Card rewarding logic

menus/dev.rb
  ├─ Developer passcode protection
  ├─ Point/card manipulation
  ├─ Difficulty override
  ├─ State reset
  └─ Game testing tools
```

## Data Flow

1. **Game Start** → initialization in `game/game.rb`
2. **Round Setup** → category & difficulty in `game/difficulty.rb`
3. **Gameplay** → guessing in `game/round.rb`
4. **Consumables** → usage from `menus/consumables.rb`
5. **Win Streak** → every 5 wins → card roll in `menus/inventory.rb`
6. **Points Earned** → usable in `menus/shop.rb`
7. **Slot Machine** → optional mini-game in `menus/slots.rb`

## Easy Customization

| What                | Where to Edit          |
|---------------------|------------------------|
| Add word category   | `config/constants.rb`  |
| Change shop prices  | `config/items.rb`      |
| Add skill card      | `config/items.rb`      |
| Modify UI colors    | `lib/color.rb`         |
| Change difficulty   | `game/difficulty.rb`   |
| Adjust point system | `game/round.rb`        |
| New menu system     | Create in `menus/`     |
