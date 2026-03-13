# 🎮 Hangman+ — Ruby Terminal Edition

A feature-rich, difficulty-scaling Hangman game with a shop system, skill cards, consumable items, and dynamic progression. Built in pure Ruby with full terminal color support.

## 📋 Features

### Dynamic Difficulty Scaling System
Instead of manually choosing difficulty, the game automatically progresses through difficulty tiers as you play:

- **EASY (Rounds 1-8)**: Choose your preferred word category. Category is displayed during gameplay.
- **MEDIUM (Rounds 9-15)**: Difficulty automatically increases. Categories are now random, but still displayed as a hint.
- **HARD (Rounds 16-25)**: Further increase in challenge. Random words with **hidden category** as an extra challenge.
- **EXTREME (After 25 Rounds)**: Optional unlock with a disclaimer. Achievement mode with **no category hint** and **word length hidden** for maximum difficulty.

> **Note**: Difficulty automatically scales after completing the required round count. You cannot manually select "Hard" mode—it unlocks automatically at round 16. Extreme mode requires opt-in confirmation at round 26.

### Core Gameplay
- **Streak System**: Build consecutive correct guesses for multiplied points.
- **Point Scoring**: Earn points based on streak multiplier (1x to extreme values).
- **Win Condition**: Win 5 consecutive rounds to unlock a random **Skill Card**.
- **Performance Tracking**: See your wins, losses, and peak streak throughout your session.

### Shop System
Purchase upgrades with earned points:

- **Bonus Point** ⭐ (Permanent) - Increases base points per correct letter
- **Reveal a Letter** ❓ (Consumable) - Instantly reveals one hidden letter in-round
- **Extra Life** ➕ (Consumable) - Adds 1 extra wrong guess allowed next round
- **Double Down** ❌² (Consumable) - Doubles your streak multiplier for one round
- **Safety Net** 🛡️ (Consumable) - First wrong guess of a round doesn't count

### Skill Cards System
Win 5 rounds to roll for powerful skill cards! Cards come in 5 rarity tiers:

- **COMMON** ⚪: Basic item upgrades (10% bonus effectiveness)
- **RARE** 🔵: Enhanced item upgrades and passive skills
- **ULTRA RARE** 🟣: Powerful unique skills (streak bonuses, perfect play rewards)
- **LEGENDARY** 🟡: Game-changing abilities (see word hints, resurrection, unlimited growth)
- **MYTHIC** 🔴: Extreme modifiers (guaranteed perfect scores, auto-win chance)

Example skill cards:
- "Lucky Streak": Start each round with 3x streak multiplier
- "Momentum": Gain +2 streak per correct letter instead of +1
- "Omniscience": See the first and last letter of each word automatically
- "Precision": Win without wrong guesses = +50% score bonus

### Consumables Menu
During gameplay, press **+** to open the consumables menu and use your purchased items mid-round.

### 14 Word Categories
Each with 15-26 unique words:

1. **Household Items** - everyday kitchen and home objects
2. **Tanks** - historical and modern military tanks
3. **Utilities** - infrastructure and municipal services
4. **Animals** - exotic and unusual creatures
5. **Countries** - regions around the world
6. **Space** - astronomical and cosmic terms
7. **Dinosaurs** - prehistoric creatures
8. **Mythology** - gods, creatures, and legends
9. **Musical Instruments** - orchestral and electric instruments
10. **Technology** - modern tech and programming concepts
11. **Foods & Cuisine** - dishes from around the world
12. **Landmarks & Monuments** - famous structures
13. **Gemstones & Minerals** - precious and natural materials
14. **Sports** - athletic activities and competitions

**Total**: 260+ unique words across all categories.

## 🎮 How to Play

### Starting a Game
1. Run the game: `ruby hangmanplus.rb`
2. Press any key to begin
3. You'll start in **EASY** mode where you choose your category
4. Guess letters to reveal the hidden word

### Difficulty Progression
| Round Range | Difficulty | Features |
|-------------|-----------|----------|
| 1-8 | EASY | Choose category, category shown |
| 9-15 | MEDIUM | Random category, still shown |
| 16-25 | HARD | Random category, hidden |
| 26+ | EXTREME* | Random category hidden, word length hidden |

*Extreme mode requires player opt-in with a disclaimer at round 26.

### Scoring
- **Base points** = 1 + (Bonus level) = usually 1-5+ points
- **Multiplier** = Your current streak
- **Final** = Base points × Streak multiplier
- **Perfect round bonus** (Extreme skill): +50% if completed with no wrong guesses

### Winning & Progression
- Guess all letters before running out of wrong guesses to win the round
- Win 5 rounds in a row → unlock a skill card roll
- Complete 25 rounds → receive Extreme mode unlock prompt
- Quit anytime via the round-end menu

### Using Consumables
1. During a round, press **+**
2. Select from available items (R/E/D/S or B to go back)
3. Item is consumed and effect applies immediately

## 📊 Statistics & Tracking

Track your progress with:
- **Current Score**: Total points earned
- **Current Streak**: Multiplier on next correct guess
- **Wins/Losses**: Cumulative record
- **Round Counter**: Which round you're on (1-999+)
- **Peak Streak**: Your highest streak achieved
- **Skill Cards Collected**: Permanent upgrades acquired

## 🎨 Visual Elements

- **Color-coded UI**: Different colors for Easy (green), Medium (yellow), Hard (red), and Extreme (magenta) modes
- **ASCII Hangman**: Classic hangman figure that progresses with wrong guesses
- **Lives Display**: Visual hearts and skulls showing remaining guesses
- **Dynamic Menu**: Consoles update with available items and affordability

## 🚀 Requirements

- Ruby 2.5 or higher
- Terminal/Console with ANSI color support
- `io/console` gem (typically included with Ruby)

## 🏃 Running the Game

```bash
cd hangmanplus
ruby hangmanplus.rb
```

The game runs entirely in your terminal with no external dependencies beyond Ruby's standard library.

## 🎯 Strategy Tips

1. **Early Rounds**: Build your streak in Easy mode with chosen categories you know well
2. **Medium Mode**: Start taking calculated risks as categories become random
3. **Hard Mode**: Play more conservatively—you won't know what type of word you're facing
4. **Skill Cards**: Prioritize early streak multipliers and Bonus Point upgrades
5. **Consumables**: Save Double Down for high-confidence rounds to maximize streak multipliers
6. **Extreme Mode**: Only tackle if you're confident in your guessing skills

## 📝 Project Structure

```
hangmanplus/
├── hangmanplus.rb          # Main game executable
├── README.md              # This file
└── .git/                  # Version control
```

## 🔮 Game Architecture

### Key Systems
- **Color Module**: Terminal color support throughout UI
- **State Management**: Persistent game state across rounds
- **Difficulty Engine**: Automatic progression based on round count
- **Skill System**: Modifiers applied from collected cards
- **HUD Display**: Real-time stats and game information

### Core Functions
- `draw_screen()`: Renders main gameplay interface
- `play_round()`: Executes one complete round
- `open_shop()`: Merchandise and upgrades interface
- `skill_card_selection_menu()`: Rewards for consecutive wins
- `consumable_menu()`: Mid-round item usage

## 📈 Version History

- **v1.0** - Initial release with core hangman, shop system, skill cards, and dynamic difficulty scaling

## 🎮 Author

Created as a feature-rich terminal Hangman variant with progression systems.

---

**Have fun and good luck building your streak! 🎯**
