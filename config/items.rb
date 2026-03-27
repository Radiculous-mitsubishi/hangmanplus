# ── Shop item definitions ────────────────────────────────────
SHOP_ITEMS = [
  {
    id:          :bonus_point,
    name:        "Bonus Point",
    emoji:       "*",
    description: "Permanently +1 point per correct letter (max 5)",
    cost:        15,
    type:        :permanent,
    max:         5
  },
  {
    id:          :reveal_letter,
    name:        "Reveal a Letter",
    emoji:       "?",
    description: "Instantly reveals one hidden letter in-round",
    cost:        10,
    type:        :consumable
  },
  {
    id:          :extra_life,
    name:        "Extra Life",
    emoji:       "+",
    description: "Adds 1 extra wrong guess allowed next round",
    cost:        12,
    type:        :consumable
  },
  {
    id:          :double_down,
    name:        "Double Down",
    emoji:       "x2",
    description: "Doubles your streak multiplier for one round",
    cost:        20,
    type:        :consumable
  },
  {
    id:          :safety_net,
    name:        "Safety Net",
    emoji:       "[]",
    description: "First wrong guess of a round does not count",
    cost:        18,
    type:        :consumable
  }
]

# ── Skill Card Definitions ───────────────────────────────────
SKILL_CARDS = {
  # COMMON CARDS
  common_bonus_1: {
    name: "Steady Hand",
    rarity: :common,
    type: :item_upgrade,
    target: :bonus_point,
    effect: { bonus_multiplier: 1.1 },
    description: "Bonus Point gains +10% effectiveness"
  },
  common_reveal_1: {
    name: "Keen Eye",
    rarity: :common,
    type: :item_upgrade,
    target: :reveal_letter,
    effect: { usage_bonus: 1 },
    description: "Gain +1 free Reveal Letter use per roll"
  },
  common_safety_1: {
    name: "Cautious",
    rarity: :common,
    type: :item_upgrade,
    target: :safety_net,
    effect: { durability: 2 },
    description: "Safety Net absorbs 2 wrong guesses instead of 1"
  },

  # RARE CARDS
  rare_double_1: {
    name: "Amplify",
    rarity: :rare,
    type: :item_upgrade,
    target: :double_down,
    effect: { multiplier_boost: 3.0 },
    description: "Double Down now triples streak instead of doubling"
  },
  rare_life_1: {
    name: "Extra Resilience",
    rarity: :rare,
    type: :item_upgrade,
    target: :extra_life,
    effect: { life_grant: 2 },
    description: "Extra Life grants +2 lives instead of +1"
  },
  rare_skill_1: {
    name: "Lucky Streak",
    rarity: :rare,
    type: :unique_skill,
    effect: { auto_streak_start: 3 },
    description: "Start each round with 3x streak multiplier"
  },

  # ULTRA RARE CARDS
  ultra_rare_skill_1: {
    name: "Momentum",
    rarity: :ultra_rare,
    type: :unique_skill,
    effect: { streak_per_correct: 2 },
    description: "Gain +2 streak per correct letter instead of +1"
  },
  ultra_rare_skill_2: {
    name: "Precision",
    rarity: :ultra_rare,
    type: :unique_skill,
    effect: { perfect_bonus: 0.5 },
    description: "Win without wrong guesses = +50% score bonus"
  },
  ultra_rare_double_2: {
    name: "Exponential",
    rarity: :ultra_rare,
    type: :item_upgrade,
    target: :double_down,
    effect: { multiplier_boost: 4.0 },
    description: "Double Down now quadruples streak multiplier"
  },

  # LEGENDARY CARDS
  legendary_skill_1: {
    name: "Omniscience",
    rarity: :legendary,
    type: :unique_skill,
    effect: { see_word_hint: true },
    description: "See the first and last letter of each word automatically"
  },
  legendary_skill_2: {
    name: "Second Wind",
    rarity: :legendary,
    type: :unique_skill,
    effect: { resurrection: true },
    description: "Get a free revive when you lose a round (once per 10 rounds)"
  },
  legendary_bonus_1: {
    name: "Infinite Power",
    rarity: :legendary,
    type: :item_upgrade,
    target: :bonus_point,
    effect: { bonus_multiplier: 2.0, no_cap: true },
    description: "Bonus Point has no level cap and x2 effectiveness"
  },

  # MYTHIC CARDS
  mythic_skill_1: {
    name: "Godlike",
    rarity: :mythic,
    type: :unique_skill,
    effect: { max_streak: 999, perfect_guarantee: true },
    description: "Every correct guess is perfectly scored"
  },
  mythic_skill_2: {
    name: "Destiny",
    rarity: :mythic,
    type: :unique_skill,
    effect: { auto_win_chance: 0.1 },
    description: "10% chance to auto-win any round"
  }
}

# ── Gold Card ─────────────────────────────────────────────────
GOLD_CARD = {
  name:        "The Gold Card",
  rarity:      :gold,
  type:        :unique_skill,
  effect:      { gold_card: true },
  description: "Awarded for collecting every card. All point gains permanently doubled."
}.freeze

# Which cards are stackable (duplicate gives +15% boost instead of rejection)
STACKABLE_TARGETS = %i[bonus_point double_down].freeze
STACKABLE_UNIQUE_EFFECTS = %i[
  auto_streak_start streak_per_correct perfect_bonus
  see_word_hint resurrection max_streak auto_win_chance
].freeze

# ── Card Rarity Configuration ───────────────────────────────
CARD_W       = 22
RARITY_ORDER = %i[common rare ultra_rare legendary mythic gold]

RARITY_CFG = {
  common: {
    color: :white, bold_border: false,
    tl: "┌", tr: "┐", bl: "└", br: "┘", h: "─", v: "│", lt: "├", rt: "┤",
    icon: "✦",
    anim: :none, label: "COMMON", stars: 1,
  },
  rare: {
    color: :cyan, bold_border: true,
    tl: "╒", tr: "╕", bl: "╘", br: "╛", h: "═", v: "│", lt: "╞", rt: "╡",
    icon: "✦",
    anim: :ripple, label: "RARE", stars: 2,
  },
  ultra_rare: {
    color: :magenta, bold_border: true,
    tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║", lt: "╠", rt: "╣",
    icon: "✦",
    anim: :pulse, label: "ULTRA RARE", stars: 3,
  },
  legendary: {
    color: :yellow, bold_border: true,
    tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║", lt: "╠", rt: "╣",
    icon: "✦",
    anim: :shine, label: "LEGENDARY", stars: 4,
  },
  mythic: {
    color: :red, bold_border: true,
    tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║", lt: "╠", rt: "╣",
    icon: "✦",
    anim: :glimmer, label: "MYTHIC", stars: 5,
  },
  gold: {
    color: :yellow, bold_border: true,
    tl: "╔", tr: "╗", bl: "╚", br: "╝", h: "═", v: "║", lt: "╠", rt: "╣",
    icon: "✦",
    anim: :shine, label: "✦ GOLD ✦", stars: 6,
  },
}.freeze
