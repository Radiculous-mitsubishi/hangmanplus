# 🎮 Hangman+ — Ruby Terminal Edition

A feature-rich, difficulty-scaling Hangman game with a shop system, skill cards, consumable items, and dynamic progression. Built in pure Ruby with full terminal color support.

## 📋 Features

### Dynamic Difficulty Scaling System (Automatic Progression)
The game automatically progresses through difficulty tiers based on your round count. **You do not manually choose difficulty at the start**—the system scales dynamically:

- **EASY (Rounds 1-8)**: You choose your preferred word category. Category is displayed during gameplay for full visibility.
- **MEDIUM (Rounds 9-15)**: Automatically progresses with notification. Categories are now random, but still displayed as a hint to help you strategize.
- **HARD (Rounds 16-25)**: Automatically progresses with notification. Random words with **hidden category** to increase challenge.
- **EXTREME (After Round 25)**: Optional unlock requiring player confirmation. Maximum difficulty mode with **no category hint** and **word length completely hidden**.

> **Transition Prompts**: When advancing to MEDIUM and HARD difficulties, you'll see an informational screen explaining the new restrictions before continuing.

### Core Gameplay
- **Streak System**: Build consecutive correct guesses for exponentially multiplied points.
- **Point Scoring**: Earn points based on your base multiplier + streak multiplier (1x starting, 999x+ possible with upgrades).
- **Win Milestone**: Win 5 consecutive rounds to unlock a random **Skill Card** roll.
- **Performance Tracking**: Monitor wins, losses, total rounds, and peak streak in real-time.
- **Local Leaderboard**: View rankings by username and lifetime points earned across all saves.
- **Custom Word Lists**: Play from a local TXT or CSV file by entering its path.
- **Difficulty Presets**: Choose Standard, Relaxed, Speedrun, or Hardcore when starting a game.

### Shop System
Spend earned points on permanent upgrades and consumable items:

- **Bonus Point** ⭐ (Permanent, Max 5) - Increases base points per correct letter (1 → 2 → 3 → etc.)
- **Reveal a Letter** ❓ (Consumable) - Instantly reveals one hidden letter during a round
- **Extra Life** ➕ (Consumable) - Adds 1 extra wrong guess for the current round
- **Double Down** ❌² (Consumable) - Doubles your streak multiplier for the current round
- **Safety Net** 🛡️ (Consumable) - First wrong guess of a round doesn't count

All consumables can be used mid-round by pressing **+** during gameplay.

### Skill Cards System
Every 5 wins, you roll for 3 random skill cards and choose one! Cards are tiered by rarity:

**COMMON** (50% drop rate):
- Steady Hand: Bonus Point gains +10% effectiveness
- Keen Eye: Gain +1 free Reveal Letter use per roll
- Cautious: Safety Net absorbs 2 wrong guesses instead of 1

**RARE** (25% drop rate):
- Amplify: Double Down now triples streak instead of doubling
- Extra Resilience: Enhances the Extra Life consumable
- Lucky Streak: Start each round with 3x streak multiplier

**ULTRA RARE** (15% drop rate):
- Momentum: Gain +2 streak per correct letter instead of +1
- Precision: Win without wrong guesses = +50% score bonus
- Exponential: Double Down now quadruples streak multiplier

**LEGENDARY** (9% drop rate):
- Omniscience: See the first and last letter of each word automatically
- Second Wind: Get a free revive when you lose a round (once per 10 rounds)
- Infinite Power: Bonus Point has no level cap and x2 effectiveness

**MYTHIC** (1% drop rate):
- Godlike: Every correct guess is perfectly scored
- Destiny: 10% chance to auto-win any round

#### Skill Card Rerolls
When rolling for skill cards, you get:
- **1 FREE reroll** per card select (displayed with green indicator)
- **Paid rerolls** cost escalating points (base 20pts, +7.5% per reroll)
  - 1st paid reroll: 20pts
  - 2nd paid reroll: 22pts
  - 3rd paid reroll: 23pts, etc.
- Cost resets when you acquire a card or skip

### 14 Word Categories
**260+ unique words** spread across diverse categories:

1. **Household Items** (21 words)
2. **Tanks** (21 historical & modern)
3. **Utilities** (19 infrastructure terms)
4. **Animals** (26 exotic creatures)
5. **Countries** (24 world nations)
6. **Space** (26 astronomical terms)
7. **Dinosaurs** (15 prehistoric creatures)
8. **Mythology** (20 gods & legends)
9. **Musical Instruments** (23 instruments)
10. **Technology** (15 modern tech)
11. **Foods & Cuisine** (20 international dishes)
12. **Landmarks & Monuments** (15 famous structures)
13. **Gemstones & Minerals** (15 precious/natural materials)
14. **Sports** (22 athletic activities)

---

## 🎮 How to Play

### Starting the Game
```bash
ruby hangmanplus.rb
```
Create a local account or sign in from the main menu before starting or loading a game. **New Game** asks for a save name and difficulty preset.
Account credentials, saves, and leaderboard data are stored locally on this device; passwords are stored as salted hashes.
Choose **B** from the main menu to view the local leaderboard.
Choose **W** while signed in to load a custom word list by path. TXT and CSV files are supported, with one word per line or comma-separated words. Words must use A–Z and be 2–30 letters long; each list can contain up to 5,000 unique words. The list is embedded in the save so it remains available when the original file is moved or removed.

### LAN Lobby Prototype
- Sign in or create a local account, then choose **R** from the main menu.
- One player hosts; other players choose Join and enter the host's local IP address and port (default `45678`). The host may need to allow Ruby through the computer's firewall.
- Share the host's **Wi-Fi** adapter address when both devices use Wi-Fi; ignore VPN/virtual adapter addresses. If the host's connection-attempt count stays at zero, check guest Wi-Fi/client isolation, VLAN/subnet separation, and that both devices are on the same LAN.
- The prototype supports an 8-player lobby with join, refresh, duplicate-name rejection, and leave. Multiplayer matches and ranked scoring are not implemented yet.
- Passwords are never sent over the LAN. For now, the host accepts the username supplied by the signed-in client; identity is not independently verified by the host, so this lobby is not cheat-proof or suitable for trusted rankings.
- Use only on a trusted local network. The host listens on the local network interfaces; do not forward the lobby port to the public internet.

### Difficulty Presets
- **Standard**: Existing progression (Easy → Medium → Hard); Extreme remains optional after 25 rounds.
- **Relaxed**: Allows 8 wrong guesses and progresses more slowly; Extreme is optional after 50 rounds.
- **Speedrun**: Adds a 30-second timer to each round.
- **Hardcore**: Starts on Medium, allows 5 wrong guesses, advances to Hard at round 16, and forces Extreme at round 41 (after 40 completed rounds). Easy is unavailable.
The selected preset is stored with the save and remains active when the game is loaded.

### Category Selection (EASY Mode Only)
When in EASY difficulty:
1. The game displays all 14 available categories with word counts
2. **Enter a category number** (e.g., `3` for Utilities)
3. Press **Enter** to confirm your selection
4. Alternatively, enter `R` and press Enter for a random category

### Round Flow
1. The game presents a word to guess
2. Guess one letter at a time
3. Correct guesses reveal the letter and build your streak
4. Wrong guesses count toward your maximum allowed mistakes
5. Win by revealing all letters before running out of guesses

### During Gameplay
- Press **+** to open the consumables menu
- Press **-** to open the hidden developer menu; enter the dev passcode to access testing tools
- Use purchased items mid-round for strategic advantages
- Watch your streak multiplier grow with each correct guess
- View your username's lifetime points total in the HUD; it is shared across saves
- See remaining lives as hearts ❤️ (full) and skulls ❌ (used)

### Difficulty Progression Table

| Rounds | Difficulty | Category Selection | Category Shown? | Word Length Shown? | Progression |
|--------|-----------|-------------------|------------------|-------------------|------------|
| 1-8 | EASY | ✅ Player Chooses | ✅ Yes | ✅ Yes | Auto → Msg → Medium |
| 9-15 | MEDIUM | ❌ Random | ✅ Yes | ✅ Yes | Auto → Msg → Hard |
| 16-25 | HARD | ❌ Random | ❌ Hidden | ✅ Yes | Auto → Msg → Extreme |
| 26+ | EXTREME | ❌ Random | ❌ Hidden | ❌ Hidden | Player Choice* |

*Only if player opts in with confirmation

### Difficulty Transition Prompts
When advancing to a new difficulty, you'll see a transition screen explaining:
- What changes are coming
- How it affects gameplay
- Any new restrictions

Press **Enter** to acknowledge and continue.

### After Each Round
- View score, wins/losses, and peak streak
- Access the Shop to purchase upgrades
- Choose **M** to return to the main menu; you can save to a slot first, return without saving, or cancel
- Choose **Y** to play again or **N** to quit; to guard against terminals buffering rapid keypresses, quitting requires typing **QUIT** and pressing Enter
- Every 5th win triggers a Skill Card roll

### Skill Card Rolls
When you've won 5 rounds, the game pauses to show you 3 random cards. You can:
- **1/2/3**: Select that card
- **R**: Reroll (FREE first time, then costs escalating points)
- **S**: Skip this reward (rare, but an option)

---

## 📊 Scoring System

### Base Calculation
```
Points Earned = (1 + Permanent Bonuses) × Streak Multiplier × Temporary Modifiers
```

### Examples
- **First correct guess**: 1 point (1 base × 1 streak)
- **Second correct (if streak)**: 2 points (1 base × 2 streak)
- **With +1 Bonus upgrade**: 2 points (2 base × 1 streak)
- **With +1 Bonus + streak**: 4 points (2 base × 2 streak)
- **With Double Down active**: 8 points (2 base × 4 streak from doubling)

### Streak Rules
- Starts at 1x each round
- Increases by 1 for each correct letter (can reach 999x+ with multipliers)
- Resets to 1x on a wrong guess
- Can be boosted by Skill Cards (e.g., Lucky Streak starts you at 3x)

### Wrong Guesses
- You begin with 6 wrong guesses allowed
- Extra Life adds +1 wrong guess per use
- Safety Net consumable prevents 1 wrong guess from counting
- Running out means you lose the round

---

## 🛍️ Shop Strategy

### Early Game (Rounds 1-8)
- Focus on building points rather than big purchases
- Buy Bonus Points first to increase future earnings
- Save for consumables as you accumulate funds

### Mid Game (Rounds 9-16)
- Upgrade Bonus Points to 3-4 levels for compound growth
- Stock up on consumables (Double Down is powerful here)
- Plan Skill Card synergies
- Consider saving for skill card rerolls if hunting for specific cards

### Late Game (Rounds 16+)
- Double Down becomes extremely valuable with huge streaks
- Consider Reveal Letter if struggling with Hard mode
- Save points for paid skill card rerolls
- Prepare for Extreme mode with Safety Net stockpile

---

## 🎯 Gameplay Tips

1. **Easy Momentum**: Easy mode lets you choose familiar categories—build momentum with 5 wins for early Skill Card.
2. **Medium Adaptation**: Categories are random but shown. Adapt your strategy per category type.
3. **Hard Mode Survival**: Play conservatively. You won't know what type of word you're facing.
4. **Extreme Preparation**: Only attempt after collecting powerful Skill Cards that reduce guesswork.
5. **Consumable Timing**: Use Double Down on high-confidence rounds when your streak is already building.
6. **Skill Card Picks**: Prioritize cards that multiply your streaks over single-use boosts.
7. **Reroll Strategy**: Take free rerolls liberally. Save points for rare/legendary cards by rerolling early.

---

## 💻 Technical Requirements

- **Ruby**: 2.5 or higher
- **OS**: Linux, macOS, or Windows (with terminal support)
- **Dependencies**: None (uses only Ruby standard library)
- **Terminal**: Must support ANSI color escape sequences

### Optional
- Terminal with 80+ column width for best visuals
- Full-screen terminal application (not minimized)

---

## 🚀 Installation & Running

### Quick Start
```bash
cd c:\Users\otto.desouza\T_PROG
ruby hangmanplus.rb
```

### Verify Installation
```bash
ruby -c hangmanplus.rb  # Check syntax
```

---

## 🎨 Visual Features

- **Color-Coded Difficulty**: Easy (🟢 Green), Medium (🟡 Yellow), Hard (🔴 Red), Extreme (🟣 Magenta)
- **ASCII Hangman**: Progressive stick figure drawing (0-6 stages)
- **Live HUD**: Score, streak multiplier, inventory, wins/losses displayed in real-time
- **Bordered UI**: Clean box-drawing characters for menu organization
- **Error Feedback**: Color-coded invalid input messages
- **Transition Screens**: Beautiful prompts when advancing to new difficulties

---

## 📈 Game Architecture

### Core Systems
- **State Management**: Persistent player state across all rounds
- **Difficulty Engine**: Automatic progression based on round counter with transition prompts
- **Skill System**: Modifiable game rules from collected cards
- **Shop System**: Purchase and inventory management
- **HUD Renderer**: Real-time UI display during gameplay
- **Reroll Cost Engine**: Escalating cost calculations for skill card rerolls

### Key Functions
- `play_round()`: Executes one complete guessing round
- `draw_screen()`: Renders main game interface with difficulty-specific display
- `open_shop()`: Shop/upgrade interface
- `skill_card_selection_menu()`: 5-win reward system with reroll costs
- `consumable_menu()`: Mid-round item usage
- `show_medium_prompt()`: MEDIUM transition screen
- `show_hard_prompt()`: HARD transition screen
- `show_extreme_prompt()`: EXTREME opt-in confirmation

---

## 📝 Game State Tracking

The game maintains persistent state:
```ruby
{
  score:               0,         # Total points earned
  wins:                0,         # Total wins
  losses:              0,         # Total losses
  total_rounds:        0,         # Rounds played (1-based)
  streak:              1,         # Current multiplier (1x+)
  peak_streak:         1,         # Best streak achieved
  inventory:           {},        # Consumable items owned
  permanent_bonuses:   {},        # Permanent upgrades
  temp_multiplier:     nil,       # Temporary streak boost (Double Down, etc.)
  pending_extra_lives: 0,         # Extra lives queued for next round
  skill_cards:         [],        # Collected permanent card upgrades
  active_skills:       []         # Currently active unique abilities
}
```

---

## 🎮 Example Playthrough

**Round 1 (EASY - You Choose)**
- Select category 4: "Animals"
- Word: `hippopotamus` (12 letters)
- Guess progression: H (correct, 1 pt), I (correct, 2 pts), P (correct, 3 pts), ...
- Win with 42 points, 4x streak

**Round 8 (Last EASY round)**
- You see a notification that Round 9 will be MEDIUM difficulty
- Final easy category choice

**Round 9 (MEDIUM - Automatic Transition)**
- Screen prompt explains: "Categories are now RANDOM"
- Random category assigned automatically
- Category shown on screen: "Technology"
- Adapt strategy based on category type

**Round 16 (HARD - Automatic Transition)**
- Screen prompt explains: "Categories are now HIDDEN"
- Random category assigned but not shown to you
- Play more conservatively—you don't know word type
- Build streak to maximize unknown words

**Round 26+ (EXTREME - If Opted In)**
- Category hidden, word length hidden
- Maximum difficulty—pure word guessing skill
- Huge point potential with skill card multipliers
- Or continue in HARD if not ready

---

## 🏆 Achievement Milestones

- **First Win**: Complete 1 round
- **On a Roll**: Win 5 rounds consecutively
- **Card Collector**: Collect your first Skill Card
- **Category Master**: Complete all 14 categories
- **Mid-Game Master**: Reach round 16 (Hard mode)
- **Extreme Challenge**: Unlock and attempt Extreme mode
- **Legendary Streak**: Build 100x+ streak multiplier
- **Ultimate Score**: Exceed 10,000 points in one session
- **Reroll Hunter**: Spend 100+ points on skill card rerolls

---

## 🎓 Game Design Philosophy

Hangman+ is designed to be:
- **Progressive**: Difficulty scales automatically—no rushing into hard modes
- **Informative**: Clear prompts explain what's changing and why
- **Rewarding**: Multiple progression paths (points, streaks, cards, rerolls)
- **Accessible**: Easy mode with full familiarity and player choice
- **Challenging**: Hard/Extreme modes for experienced players seeking mastery
- **Customizable**: Skill cards allow unique builds and strategies
- **Replayable**: 260+ words, 14 categories, infinite combinations

---

## 📚 Version History

- **v1.0.2** (March 2026) - Difficulty transition improvements:
  - Auto-progression without startup menu
  - Transition prompts for MEDIUM and HARD
  - Category selection via Enter key (supports multi-digit numbers)
  - Skill card reroll cost system implemented

- **v1.0.1** (March 2026) - Category & word expansion:
  - Expanded all categories with more words
  - Added 8 new categories (Dinosaurs, Mythology, etc.)
  - Total categories: 14, Total words: 260+

- **v1.0** (March 2026) - Initial release with full feature set:
  - Dynamic difficulty scaling (Easy → Medium → Hard → Extreme)
  - Shop system with 5 items
  - Skill card system with 20 unique cards
  - Consumables menu
  - 14 word categories with 260+ words
  - Full terminal UI with colors

---

## 🤝 Contributing

This game was built as a feature-rich terminal Hangman variant. Improvements and suggestions welcome!

---

## 🎯 Future Possibilities

Potential enhancements for future versions:
- Multiplayer modes (competitive/cooperative)
- Sound effects via `beep`
- Session statistics export (JSON/CSV)
- Achievements/badges system

---

**Good luck and have fun! Build that streak and collect those rare Skill Cards! 🎉**
