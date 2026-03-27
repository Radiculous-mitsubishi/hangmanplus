#!/usr/bin/env ruby
# encoding: utf-8
# ============================================================
#  H A N G M A N  —  Ruby Terminal Edition  (with Shop & Skill Cards!)
# ============================================================

require 'io/console'

# ── Colour helpers ──────────────────────────────────────────
module Color
  def self.red(s)     "\e[31m#{s}\e[0m" end
  def self.green(s)   "\e[32m#{s}\e[0m" end
  def self.yellow(s)  "\e[33m#{s}\e[0m" end
  def self.cyan(s)    "\e[36m#{s}\e[0m" end
  def self.bold(s)    "\e[1m#{s}\e[0m"  end
  def self.dim(s)     "\e[2m#{s}\e[0m"  end
  def self.magenta(s) "\e[35m#{s}\e[0m" end
  def self.white(s)   "\e[97m#{s}\e[0m" end
  def self.rarity(r)
    case r
    when :common then "\e[37m#{s}\e[0m"
    when :rare then cyan(s)
    when :ultra_rare then magenta(s)
    when :legendary then yellow(s)
    when :mythic then "\e[35m#{s}\e[0m"
    else s
    end
  end
end

# ── Word categories ─────────────────────────────────────────
CATEGORIES = {
  "Household Items" => %w[
    refrigerator microwave dishwasher pillowcase curtains
    bookshelf lampshade broom dustpan colander spatula
    tablecloth wardrobe cabinet toaster blender kettle
    cushion mattress doorbell saucepan utensil napkin
    fireplace chandelier console wallpaper escalator
    banister countertop furnace thermostat plunger
  ],
  "Tanks" => %w[
    abrams leopard challenger panzer tiger sherman
    pershing centurion merkava crusader chieftain firefly
    matilda panther hellcat stug sturmtiger ferdinand
    hetzer panzerkampfwagen t34 t44 t54 kv vickers
    conqueror tortoise jaegerb archer cromwell cromwell
  ],
  "Utilities" => %w[
    electricity plumbing broadband sewage heating
    waterworks gasline telephone recycling drainage
    transformer substation reservoir pipeline generator
    powerline conduit faucet septic aqueduct gridlock
    turbine hydroelectric geothermal windmill
  ],
  "Animals" => %w[
    hippopotamus chimpanzee rhinoceros salamander crocodile
    armadillo platypus chameleon flamingo porcupine
    wolverine albatross jellyfish giraffe elephant
    ostrich pangolin tapir anteater ferret meerkat
    capybara orangutan gibbon antelope impala warthog
    cheetah lynx aardvark skunk badger lemur tarsier
  ],
  "Countries" => %w[
    mozambique kazakhstan liechtenstein azerbaijan madagascar
    switzerland philippines uzbekistan cambodia venezuela
    argentina indonesia guatemala dominican mauritius
    singapore laos latvia estonia turkmenistan tajikistan
    kyrgyzstan montenegro luxembourg malta cyprus samoa
  ],
  "Space" => %w[
    nebula asteroid comet galaxy pulsar supernova blackhole
    quasar telescope satellite cosmonaut trajectory atmosphere
    exoplanet orbit supergiant redgiant whitedwarf neutron
    aurora constellation zodiac eclipse solar lunar eclipse
    andromeda orion cygnus draco ursa vega sirius altair
  ],
  "Dinosaurs" => %w[
    tyrannosaurus triceratops stegosaurus brachiosaurus
    velociraptor parasaurolophus ankylosaurus iguanodon
    spinosaurus allosaurus carnotaurus therizinosaurus
    diplodocus apatosaurus brachiosaurus deinonychus
    compsognathus ostracoderms archaeopteryx
  ],
  "Mythology" => %w[
    zeus athena apollo artemis aphrodite hermes hades
    poseidon ares hephaestus demeter hera dionysus
    minotaur centaur pegasus chimera phoenix cyclops
    medusa cerberus sphinx gorgon harpy siren nymph
    valkyrie golem basilisk banshee kraken leviathan
  ],
  "Musical Instruments" => %w[
    saxophone trumpet trombone clarinet tuba violin
    cello viola guitar mandolin ukulele harp piano
    accordion xylophone marimba timpani cymbal tambourine
    harmonica synthesizer flute oboe bassoon piccolo
    metronome gong bugle cornet euphonium sousaphone
  ],
  "Technology" => %w[
    computer laptop smartphone tablet monitor keyboard
    mouse router modem processor graphics memory
    motherboard power circuit database algorithm
    software hardware firmware application encryption
    javascript typescript python cryptocurrency blockchain
  ],
  "Foods & Cuisine" => %w[
    spaghetti lasagna pizza paella risotto burritos
    tacos enchiladas dumplings ramen noodles sashimi
    tiramisu bruschetta croissant escargot schnitzel
    goulash stroganoff pierogi borsch gazpacho ceviche
    poutine hamburger hotdog carbonara bolognese chowder
  ],
  "Landmarks & Monuments" => %w[
    pyramids colosseum parthenon statue liberty tower
    eiffel bigben burjkhalifa chrysler empire domtower
    sagrada familia westminster alhambra versailles
    machu picchu angkor stonehenge moai taj mahaj
  ],
  "Gemstones & Minerals" => %w[
    diamond sapphire emerald ruby amethyst topaz
    garnet opal turquoise obsidian jade lapis malachite
    quartz feldspar mica magnetite hematite limestone
    marble granite slate talc asbestos fluorite
  ],
  "Sports" => %w[
    basketball football baseball cricket volleyball
    badminton tennis racquetball squash golf hockey
    lacrosse curling singleskatebowling billiards archery
    fencing wrestling judo karate taekwondo sumo
    weightlifting gymnastics skiing snowboarding sledding
  ]
}

# ── ASCII hangman stages ─────────────────────────────────────
HANGMAN = [
  "    ________\n    |      |\n    |\n    |\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |      |\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\\\n    |\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\\\n    |     /\n    |\n  __|__",
  "    ________\n    |      |\n    |      O\n    |     /|\\\n    |     / \\\n    |\n  __|__"
]

BASE_MAX_WRONG = 6

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

# ── Utilities ────────────────────────────────────────────────
def clear = print("\e[2J\e[H")

BOX_WIDTH = 60

def strip_color(s)
  s.gsub(/\e\[[0-9;]*m/, '')
end

def box_line(content)
  inner_len = strip_color(content).length
  padding   = [BOX_WIDTH - 4 - inner_len, 0].max
  Color.cyan("  |") + " #{content}#{' ' * padding} " + Color.cyan("|")
end

def draw_header(title)
  puts Color.cyan("  +" + "-" * (BOX_WIDTH - 2) + "+")
  title_pad   = [(BOX_WIDTH - 2 - title.length) / 2, 0].max
  title_right = BOX_WIDTH - 2 - title_pad - title.length
  puts Color.cyan("  |") + " " * title_pad + Color.bold(Color.white(title)) + " " * title_right + Color.cyan("|")
  puts Color.cyan("  +" + "-" * (BOX_WIDTH - 2) + "+")
end

def draw_divider
  puts Color.cyan("  +" + "-" * (BOX_WIDTH - 2) + "+")
end

def draw_footer
  puts Color.cyan("  +" + "-" * (BOX_WIDTH - 2) + "+")
end

def center_text(text, width = BOX_WIDTH)
  stripped = strip_color(text)
  pad = [(width - stripped.length) / 2, 0].max
  " " * pad + text
end

def rarity_color(rarity)
  case rarity
  when :common then Color.white("●")
  when :rare then Color.cyan("●")
  when :ultra_rare then Color.magenta("●")
  when :legendary then Color.yellow("●")
  when :mythic then Color.red("●")
  when :gold   then Color.bold(Color.yellow("✦"))
  else "●"
  end
end

def rarity_name_colored(rarity)
  case rarity
  when :common then Color.white("COMMON")
  when :rare then Color.cyan("RARE")
  when :ultra_rare then Color.magenta("ULTRA RARE")
  when :legendary then Color.yellow("LEGENDARY")
  when :gold    then Color.bold(Color.yellow("✦ GOLD ✦"))
  else "UNKNOWN"
  end
end

# ── HUD ──────────────────────────────────────────────────────
def draw_hud(state)
  bonus = state[:permanent_bonuses][:bonus_point] || 0
  base  = 1 + bonus
  mult  = state[:streak]
  tmult = state[:temp_multiplier] || 1
  eff   = mult * tmult

  score_str  = Color.bold(Color.yellow("#{state[:score]} pts"))
  streak_str = eff > 1 ? Color.bold(Color.cyan("#{eff}x STREAK!")) : Color.dim("1x")
  base_str   = Color.dim("next correct = +#{base * eff}pts")
  inv_str    = inventory_summary(state[:inventory])
  wins_str   = Color.dim("W:#{state[:wins]}/5")

  puts box_line(Color.dim("Score: ") + score_str + "   " + streak_str + "  " + base_str + "  " + wins_str)
  unless inv_str.empty?
    puts box_line(Color.dim("Inventory: ") + Color.cyan(inv_str))
  end
  draw_divider
end

def inventory_summary(inv)
  labels = { reveal_letter: "[?]Reveal", extra_life: "[+]Life", double_down: "[x2]Double", safety_net: "[]Shield" }
  parts  = []
  labels.each do |id, label|
    qty = inv[id] || 0
    parts << "#{label}x#{qty}" if qty > 0
  end
  parts.join("  ")
end

# ── Hangman art ───────────────────────────────────────────────
def draw_hangman(wrong_count, max_wrong)
  art_color = wrong_count <= max_wrong / 3 ? :green : (wrong_count <= max_wrong * 2 / 3 ? :yellow : :red)
  HANGMAN[wrong_count].each_line do |line|
    puts box_line(Color.send(art_color, line.rstrip))
  end
end

# ── Main game screen ──────────────────────────────────────────
def draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong, difficulty = :easy)
  clear
  draw_header("H  A  N  G  M  A  N")
  draw_hud(state)
  draw_hangman(wrong_count, max_wrong)
  draw_divider

  difficulty_colors = { easy: Color.green("EASY"), medium: Color.yellow("MEDIUM"), hard: Color.red("HARD"), extreme: Color.magenta("EXTREME") }
  diff_display = difficulty_colors[difficulty] || "UNKNOWN"
  round_display = Color.dim("Round: ") + Color.bold(Color.cyan("#{state[:total_rounds]}"))
  puts box_line(diff_display + Color.dim(" | ") + round_display)

  if difficulty == :easy || difficulty == :medium
    puts box_line(Color.dim("Category: ") + Color.bold(Color.magenta(category)))
  elsif difficulty == :hard
    puts box_line(Color.dim("Category: ") + Color.dim("[Hidden]"))
  else
    puts box_line(Color.dim("Category: ") + Color.red("[Hidden]") + Color.dim(" | Length: ") + Color.red("[Hidden]"))
  end

  if difficulty == :extreme
    display = word.chars.map { |c|
      guessed.include?(c) ? Color.bold(Color.green(" #{c} ")) : Color.red("[?]")
    }.join
  else
    display = word.chars.map { |c|
      guessed.include?(c) ? Color.bold(Color.green(" #{c} ")) : Color.dim(" _ ")
    }.join
  end
  puts box_line(display)

  if wrong_letters.empty?
    puts box_line(Color.dim("No wrong guesses yet"))
  else
    puts box_line(Color.dim("Wrong: ") + wrong_letters.sort.map { |l| Color.red(l.upcase) }.join("  "))
  end

  remaining = max_wrong - wrong_count
  hearts = (Color.green("<3 ") * remaining).rstrip
  skulls = (Color.red("X ") * wrong_count).rstrip
  puts box_line(hearts + (wrong_count > 0 ? "  " + skulls : ""))

  draw_divider
  puts box_line(Color.dim("Press ") + Color.bold(Color.yellow("+")) + Color.dim(" to open consumables menu"))
  draw_footer
  print "  Guess a letter: "
end

# ── Skill Card Rolling System ────────────────────────────────
def roll_skill_cards(num_rolls = 3)
  # Define rarity weights
  rarities = []
  100.times do |i|
    case i
    when 0..49 then rarities << :common
    when 50..74 then rarities << :rare
    when 75..89 then rarities << :ultra_rare
    when 90..98 then rarities << :legendary
    when 99 then rarities << :mythic
    end
  end

  cards = []
  num_rolls.times do
    rarity = rarities.sample
    card_keys = SKILL_CARDS.select { |_, v| v[:rarity] == rarity }.keys
    card_key = card_keys.sample
    cards << [card_key, SKILL_CARDS[card_key]]
  end
  cards
end

def skill_card_selection_menu(state)
  reroll_count     = 0
  base_reroll_cost = 20

  loop do
    # Check for Gold Card condition first
    if owns_all_cards?(state) && !(state[:active_skills] || []).any? { |c| c[:rarity] == :gold }
      award_gold_card(state)
      return
    end

    cards = roll_skill_cards(3)

    # Annotate each card with its duplicate status
    card_status = cards.map do |(key, card)|
      if already_owns?(state, card)
        status = stackable_card?(card) ? :stack : :reject
      else
        status = :new
      end
      [key, card, status]
    end

    clear
    draw_header("★ S K I L L  C A R D  R O L L ★")
    draw_divider
    puts box_line(Color.bold(Color.yellow("You've won 5 rounds! Choose a skill card:")))
    draw_divider

    card_status.each_with_index do |(key, card, status), idx|
      rarity_label = rarity_name_colored(card[:rarity])
      status_tag = case status
        when :new    then ""
        when :stack  then Color.bold(Color.green(" [+15% BOOST]"))
        when :reject then Color.bold(Color.red(" [OWNED — auto-reroll if picked]"))
        end
      puts box_line("#{Color.bold(Color.yellow((idx+1).to_s))}. #{rarity_label} - #{Color.bold(card[:name])}#{status_tag}")
      puts box_line("   #{card[:description]}")
    end

    draw_divider
    if reroll_count == 0
      puts box_line("#{Color.bold(Color.yellow('R'))}. Reroll cards #{Color.dim('(FREE - 1 per card select)')}")
    else
      reroll_cost = (base_reroll_cost * ((1.075) ** reroll_count)).round
      can_afford  = state[:score] >= reroll_cost
      cost_color  = can_afford ? Color.green("#{reroll_cost}pts") : Color.red("#{reroll_cost}pts")
      puts box_line("#{Color.bold(Color.yellow('R'))}. Reroll cards #{cost_color}")
    end
    puts box_line("#{Color.bold(Color.yellow('S'))}. Skip (no reward)")
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input

    case input
    when '1', '2', '3'
      idx         = input.to_i - 1
      key, card, status = card_status[idx]

      case status
      when :new
        apply_skill_card(state, card)
        puts Color.green("\n  ✓ Card acquired: #{card[:name]}!")

      when :stack
        apply_skill_card(state, card, stack_boost: true)
        puts Color.bold(Color.green("\n  ✦ Duplicate! #{card[:name]} boosted +15%!"))

      when :reject
        # Auto-reroll this slot until we get something non-rejected
        puts Color.yellow("\n  Already owned and non-stackable — rerolling...")
        sleep 0.6
        replacement_card = nil
        15.times do
          _, rc = roll_skill_cards(1).first
          next if already_owns?(state, rc) && !stackable_card?(rc)
          replacement_card = rc
          break
        end
        if replacement_card
          is_dup = already_owns?(state, replacement_card)
          apply_skill_card(state, replacement_card, stack_boost: is_dup && stackable_card?(replacement_card))
          tag = is_dup ? Color.bold(Color.green(" (+15% boost)")) : ""
          puts Color.cyan("  → Got: #{rarity_name_colored(replacement_card[:rarity])} #{replacement_card[:name]}#{tag}")
        else
          puts Color.dim("  → No alternatives found. Skipping.")
        end
      end

      sleep 1.5

      # Check Gold Card after every acquisition
      if owns_all_cards?(state) && !(state[:active_skills] || []).any? { |c| c[:rarity] == :gold }
        sleep 0.5
        award_gold_card(state)
      end
      return

    when 'r'
      if reroll_count == 0
        reroll_count += 1
        puts Color.cyan("  [FREE] Rerolling cards..."); sleep 0.8
      else
        reroll_cost = (base_reroll_cost * ((1.075) ** reroll_count)).round
        if state[:score] < reroll_cost
          puts Color.red("  Not enough points! Need #{reroll_cost}pts, have #{state[:score]}pts"); sleep 1
        else
          state[:score] -= reroll_cost
          reroll_count  += 1
          puts Color.green("  [-#{reroll_cost}pts] Rerolling cards..."); sleep 0.8
        end
      end

    when 's'
      puts Color.yellow("\n  Skipped reward."); sleep 1; return

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end


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

def stackable_card?(card)
  return true if card[:type] == :item_upgrade && STACKABLE_TARGETS.include?(card[:target])
  return true if card[:type] == :unique_skill && card[:effect].keys.any? { |k| STACKABLE_UNIQUE_EFFECTS.include?(k) }
  false
end

# Returns true if the player already owns this card (by name)
def already_owns?(state, card)
  all = (state[:skill_cards] || []) + (state[:active_skills] || [])
  all.any? { |c| c[:name] == card[:name] }
end

# Returns true if the player owns every normal card
def owns_all_cards?(state)
  all_names = SKILL_CARDS.values.map { |c| c[:name] }.to_set
  owned     = ((state[:skill_cards] || []) + (state[:active_skills] || [])).map { |c| c[:name] }.to_set
  all_names.subset?(owned)
end

def apply_skill_card(state, card, stack_boost: false)
  boost = stack_boost ? 1.15 : 1.0

  # Always track copy count — increment if already owned, set to 1 if new
  state[:card_counts] ||= {}
  state[:card_counts][card[:name]] = (state[:card_counts][card[:name]] || 0) + 1

  if card[:type] == :item_upgrade
    state[:skill_cards] ||= []
    # Only add to collection list if first copy
    state[:skill_cards] << card if state[:card_counts][card[:name]] == 1

    case card[:target]
    when :bonus_point
      state[:permanent_bonuses][:bonus_multiplier] =
        (state[:permanent_bonuses][:bonus_multiplier] || 1.0) * (card[:effect][:bonus_multiplier] * boost)
      state[:permanent_bonuses][:bonus_point_no_cap] = true if card[:effect][:no_cap]
    when :double_down
      current = state[:permanent_bonuses][:double_multiplier] || card[:effect][:multiplier_boost]
      state[:permanent_bonuses][:double_multiplier] = (current * boost).round(2)
    when :reveal_letter
      state[:inventory][:reveal_letter] = (state[:inventory][:reveal_letter] || 0) + card[:effect][:usage_bonus]
    when :safety_net
      state[:permanent_bonuses][:safety_durability] = card[:effect][:durability]
    when :extra_life
      state[:permanent_bonuses][:extra_life_grant] = card[:effect][:life_grant]
    end

  elsif card[:type] == :unique_skill
    state[:active_skills] ||= []
    # Only add to collection list if first copy
    state[:active_skills] << card if state[:card_counts][card[:name]] == 1

    if stack_boost
      existing = state[:active_skills].find { |c| c[:name] == card[:name] }
      if existing
        card[:effect].each do |k, v|
          existing[:effect][k] = (v * boost).round(3) if v.is_a?(Numeric)
        end
      end
    end

  elsif card[:rarity] == :gold
    state[:active_skills] ||= []
    state[:active_skills] << card unless state[:active_skills].any? { |c| c[:rarity] == :gold }
    state[:permanent_bonuses][:gold_card] = true
  end
end

# Handle duplicate: stackable → boost, non-stackable → signal reroll
# Returns :stacked, :reject, or :gold
def handle_duplicate(state, card)
  return :gold if card[:rarity] == :gold
  if stackable_card?(card)
    :stack
  else
    :reject
  end
end

# ── Consumable Menu ──────────────────────────────────────────
def consumable_menu(word, guessed, state, max_wrong_ref, safety_armed)
  loop do
    clear
    draw_header("C O N S U M A B L E S")
    draw_divider

    inv = state[:inventory]

    puts box_line(Color.dim("Select a consumable to use:"))
    draw_divider

    if (inv[:reveal_letter] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('R'))}. [?] Reveal a Letter (#{inv[:reveal_letter]}x)")
    else
      puts box_line("#{Color.dim('R')}}. [?] Reveal a Letter #{Color.dim('(unavailable)')}")
    end

    if (inv[:extra_life] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('E'))}. [+] Extra Life (#{inv[:extra_life]}x)")
    else
      puts box_line("#{Color.dim('E')}}. [+] Extra Life #{Color.dim('(unavailable)')}")
    end

    if (inv[:double_down] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('D'))}. [x2] Double Down (#{inv[:double_down]}x)")
    else
      puts box_line("#{Color.dim('D')}}. [x2] Double Down #{Color.dim('(unavailable)')}")
    end

    if (inv[:safety_net] || 0) > 0
      puts box_line("#{Color.bold(Color.yellow('S'))}. [S] Safety Net (#{inv[:safety_net]}x)")
    else
      puts box_line("#{Color.dim('S')}}. [S] Safety Net #{Color.dim('(unavailable)')}")
    end

    draw_divider
    puts box_line("#{Color.bold(Color.yellow('B'))}. Back to game")
    draw_footer
    print "  Choice: "

    ch = $stdin.getch.downcase
    puts ch

    case ch
    when 'r'
      if (inv[:reveal_letter] || 0) > 0
        use_reveal_letter(word, guessed, inv)
        return
      else
        puts Color.red("  You don't have any Reveal consumables!"); sleep 1
      end

    when 'e'
      if (inv[:extra_life] || 0) > 0
        use_extra_life(state, max_wrong_ref, inv)
        return
      else
        puts Color.red("  You don't have any Extra Life consumables!"); sleep 1
      end

    when 'd'
      if (inv[:double_down] || 0) > 0
        use_double_down(state, inv)
        return
      else
        puts Color.red("  You don't have any Double Down consumables!"); sleep 1
      end

    when 's'
      if (inv[:safety_net] || 0) > 0
        use_safety_net(state, safety_armed, inv)
        return
      else
        puts Color.red("  You don't have any Safety Net consumables!"); sleep 1
      end

    when 'b'
      return

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

# ── Individual consumable functions ──────────────────────────
def use_reveal_letter(word, guessed, inv)
  hidden = word.chars.uniq.reject { |c| guessed.include?(c) }
  if hidden.empty?
    puts Color.yellow("  No hidden letters left!")
    sleep 1
    return
  end
  revealed = hidden.sample
  guessed << revealed
  inv[:reveal_letter] -= 1
  puts Color.green("  [?] Revealed: '#{revealed.upcase}'!")
  sleep 1
end

def use_extra_life(state, max_wrong_ref, inv)
  if state[:pending_extra_lives] > 0
    max_wrong_ref[0] += 1
    state[:pending_extra_lives] -= 1
    inv[:extra_life] -= 1
    puts Color.green("  [+] Extra life! You can now miss #{max_wrong_ref[0]} times.")
    sleep 1
  end
end

def use_double_down(state, inv)
  state[:temp_multiplier] = ((state[:temp_multiplier] || 1) * 2)
  inv[:double_down] -= 1
  puts Color.green("  [x2] Streak doubled for this round!")
  sleep 1
end

def use_safety_net(state, safety_armed, inv)
  if safety_armed[0]
    puts Color.yellow("  Safety Net is already armed!")
    sleep 1
    return
  end
  safety_armed[0] = true
  inv[:safety_net] -= 1
  puts Color.green("  [S] Safety Net armed! Your next wrong guess won't count.")
  sleep 1
end

# ── Difficulty Selection Menu ─────────────────────────────
def choose_difficulty
  loop do
    clear
    draw_header("Select Difficulty")
    draw_divider
    puts box_line(Color.bold(Color.green("EASY")) + Color.dim(" - Choose category, category shown"))
    puts box_line(Color.dim("Rounds 1-8"))
    draw_divider
    puts box_line(Color.bold(Color.yellow("MEDIUM")) + Color.dim(" - Random words, category shown"))
    puts box_line(Color.dim("Rounds 8-15"))
    draw_divider
    puts box_line(Color.bold(Color.red("HARD")) + Color.dim(" - Random words, category hidden"))
    puts box_line(Color.dim("Rounds 15-25"))
    draw_divider
    puts box_line(Color.bold(Color.magenta("EXTREME")) + Color.dim(" - Unlock after 25 rounds"))
    puts box_line(Color.dim("No category hint, word length hidden"))
    draw_divider
    puts box_line("Choose difficulty: " + Color.bold(Color.yellow("[E]Easy  [M]Medium  [H]Hard")))
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input
    case input
    when 'e' then return :easy
    when 'm' then return :medium
    when 'h' then return :hard
    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

# ── Category menu ─────────────────────────────────────────────
def choose_category(difficulty = :easy)
  keys = CATEGORIES.keys
  
  if difficulty == :easy
    loop do
      clear
      draw_header("Choose a Word Category")
      keys.each_with_index do |name, i|
        puts box_line("#{Color.bold(Color.yellow((i+1).to_s))}. #{name} #{Color.dim("(#{CATEGORIES[name].length} words)")}")
      end
      puts box_line("#{Color.bold(Color.yellow('R'))}. Random category")
      draw_footer
      print "  Choice: "

      input = $stdin.gets.strip.downcase
      puts input
      return keys.sample   if input == 'r'
      return keys[input.to_i - 1] if (1..keys.length).include?(input.to_i)
      puts Color.red("  Invalid."); sleep 0.7
    end
  else
    return keys.sample
  end
end

# ── Slot Machine ─────────────────────────────────────────────
SLOT_SYMBOLS = [
  { name: "7",      display: Color.bold(Color.yellow(" 7 ")),   weight: 5  },
  { name: "BAR",    display: Color.bold(Color.white("BAR")),    weight: 10 },
  { name: "BELL",   display: Color.bold(Color.yellow("BEL")),   weight: 15 },
  { name: "STAR",   display: Color.bold(Color.cyan(" * ")),     weight: 20 },
  { name: "CHERRY", display: Color.bold(Color.red(" C ")),      weight: 25 },
  { name: "LEMON",  display: Color.bold(Color.yellow(" L ")),   weight: 25 },
].freeze

def spin_reel
  pool = SLOT_SYMBOLS.flat_map { |s| [s] * s[:weight] }
  pool.sample
end

def slot_spin_cost(state)
  spins = state[:slot_spins] || 0
  (10 * (1.10 ** spins)).ceil
end

def animate_slots(final_reels)
  # Build frame timings: fast at first, then slow down as reels "stop"
  # Total ~2.5 seconds across 14 frames
  timings = [0.08, 0.08, 0.08, 0.08, 0.10, 0.10, 0.12, 0.14, 0.16, 0.18, 0.22, 0.26, 0.30, 0.35]

  timings.each_with_index do |delay, frame|
    # In the last 3 frames, lock reels one by one left to right
    r1 = frame >= timings.length - 3 ? final_reels[0] : SLOT_SYMBOLS.sample
    r2 = frame >= timings.length - 2 ? final_reels[1] : SLOT_SYMBOLS.sample
    r3 = frame >= timings.length - 1 ? final_reels[2] : SLOT_SYMBOLS.sample

    label = frame >= timings.length - 1 ? "" : Color.dim("  spinning...")
    puts "  " + Color.cyan("| ") + [r1, r2, r3].map { |r| r[:display] }.join(Color.dim(" | ")) + Color.cyan(" |") + label
    sleep delay
    print "\e[1A\e[2K"
  end

  # Final locked result
  puts "  " + Color.cyan("| ") + final_reels.map { |r| r[:display] }.join(Color.dim(" | ")) + Color.cyan(" |")
end

def award_gold_card(state)
  apply_skill_card(state, GOLD_CARD)
  clear
  # Dramatic full-screen reveal
  6.times do |i|
    clear
    sparkle = [" ✦ ", " ★ ", " ◆ ", " ★ ", " ✦ ", " · "][i % 6]
    border  = Color.bold(Color.yellow("  ╔" + "═" * 52 + "╗"))
    puts "\n\n\n"
    puts border
    puts Color.bold(Color.yellow("  ║")) + "  " * 26 + Color.bold(Color.yellow("║"))
    title = "#{sparkle}  T H E   G O L D   C A R D  #{sparkle}"
    t_pad = [(52 - title.length) / 2, 0].max
    puts Color.bold(Color.yellow("  ║")) + " " * t_pad + Color.bold(Color.white(title)) + " " * [52 - title.length - t_pad, 0].max + Color.bold(Color.yellow("║"))
    puts Color.bold(Color.yellow("  ║")) + "  " * 26 + Color.bold(Color.yellow("║"))
    puts Color.bold(Color.yellow("  ╚" + "═" * 52 + "╝"))
    sleep 0.25
  end
  puts
  puts Color.bold(Color.yellow("  ╔" + "═" * 52 + "╗"))
  puts Color.bold(Color.yellow("  ║")) + Color.bold(Color.white("  ✦  T H E   G O L D   C A R D  ✦               ")) + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ╠" + "═" * 52 + "╣"))
  puts Color.bold(Color.yellow("  ║")) + Color.bold(Color.yellow("  You have collected every skill card!          ")) + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ╠" + "═" * 52 + "╣"))
  puts Color.bold(Color.yellow("  ║")) + Color.white("  All point gains are permanently doubled.       ") + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ║")) + Color.dim("  This bonus stacks with all other effects.      ") + Color.bold(Color.yellow("║"))
  puts Color.bold(Color.yellow("  ╚" + "═" * 52 + "╝"))
  puts
  puts Color.dim("  Press any key to continue...")
  $stdin.getch
end

def open_slot_machine(state)
  loop do
    clear
    draw_header("S L O T  M A C H I N E")
    spins_done = state[:slot_spins] || 0
    cost       = slot_spin_cost(state)
    next_cost  = (10 * (1.10 ** (spins_done + 1))).ceil

    puts box_line(Color.dim("Your points: ") + Color.bold(Color.yellow("#{state[:score]} pts")))
    puts box_line(Color.dim("Spins taken:  ") + Color.cyan("#{spins_done}"))
    draw_divider
    puts box_line(Color.bold(" [ ? ] [ ? ] [ ? ] "))
    draw_divider
    puts box_line("Match 3 symbols to win a " + Color.bold(Color.magenta("Skill Card")) + "!")
    puts box_line(Color.dim("  Win chance: ") + Color.green("33%") + Color.dim("  |  Nothing: ") + Color.red("67%"))
    draw_divider

    can_afford = state[:score] >= cost
    cost_str   = can_afford ? Color.green("#{cost} pts") : Color.red("#{cost} pts (too poor)")
    puts box_line("#{Color.bold(Color.yellow('[S]'))} Spin!  Cost: #{cost_str}")
    puts box_line(Color.dim("    Next spin will cost: #{next_cost} pts"))
    draw_divider
    puts box_line("#{Color.bold(Color.yellow('[X]'))} Leave")
    draw_footer
    print "  Choice: "

    ch = $stdin.getch.downcase
    puts ch

    case ch
    when 'x'
      break

    when 's'
      unless state[:score] >= cost
        puts Color.red("  Not enough points!"); sleep 1; next
      end

      state[:score]      -= cost
      state[:slot_spins]  = spins_done + 1

      # Determine outcome: 33% win (3-of-a-kind), 67% lose
      win = rand < 0.33

      if win
        # Pick one symbol, fill all 3 reels with it
        sym     = SLOT_SYMBOLS.sample
        reels   = [sym, sym, sym]
      else
        # Guarantee NO three-of-a-kind by always making reel 3 differ
        r1 = spin_reel
        r2 = spin_reel
        # Keep rerolling r3 until it doesn't complete a triple
        r3 = spin_reel
        r3 = spin_reel while r3[:name] == r1[:name] && r3[:name] == r2[:name]
        reels = [r1, r2, r3]
      end

      clear
      draw_header("S L O T  M A C H I N E")
      puts box_line(Color.dim("Spinning..."))
      draw_divider
      puts ""   # blank line for animation space
      animate_slots(reels)
      puts ""
      draw_divider

      if win
        sym_display = reels[0][:display].strip
        puts box_line(Color.bold(Color.green("★ THREE #{sym_display}s! YOU WIN! ★")))
        puts box_line(Color.bold(Color.magenta("You earned a Skill Card!")))
        draw_footer
        sleep 1.5

        # Award one skill card using existing rarity roll — handle duplicates
        awarded = roll_skill_cards(1).first
        key, card = awarded

        if already_owns?(state, card)
          if stackable_card?(card)
            apply_skill_card(state, card, stack_boost: true)
            clear
            draw_header("★ SKILL CARD AWARDED ★")
            draw_divider
            puts box_line(rarity_name_colored(card[:rarity]) + " — " + Color.bold(card[:name]))
            puts box_line("  " + Color.dim(card[:description]))
            draw_divider
            puts box_line(Color.bold(Color.yellow("You already own this! Stats boosted +15%")))
            draw_divider
            puts box_line(Color.dim("Press any key to continue..."))
            draw_footer
            $stdin.getch
          else
            # Non-stackable duplicate — reroll until something useful
            10.times do
              awarded = roll_skill_cards(1).first
              key, card = awarded
              break unless already_owns?(state, card) && !stackable_card?(card)
            end
            apply_skill_card(state, card, stack_boost: already_owns?(state, card) && stackable_card?(card))
            clear
            draw_header("★ SKILL CARD AWARDED ★")
            draw_divider
            puts box_line(Color.dim("(Duplicate rerolled)"))
            puts box_line(rarity_name_colored(card[:rarity]) + " — " + Color.bold(card[:name]))
            puts box_line("  " + Color.dim(card[:description]))
            draw_divider
            puts box_line(Color.dim("Press any key to continue..."))
            draw_footer
            $stdin.getch
          end
        else
          apply_skill_card(state, card)
          clear
          draw_header("★ SKILL CARD AWARDED ★")
          draw_divider
          puts box_line(rarity_name_colored(card[:rarity]) + " — " + Color.bold(card[:name]))
          puts box_line("  " + Color.dim(card[:description]))
          draw_divider
          puts box_line(Color.dim("Press any key to continue..."))
          draw_footer
          $stdin.getch
        end

        # Check for Gold Card
        if owns_all_cards?(state) && !(state[:active_skills] || []).any? { |c| c[:rarity] == :gold }
          sleep 0.5
          award_gold_card(state)
        end
      else
        names = reels.map { |r| r[:display] }.join(Color.dim("  "))
        puts box_line(Color.red("No match.") + Color.dim("  #{names}"))
        puts box_line(Color.dim("Better luck next time!"))
        draw_footer
        sleep 1.2
      end

    else
      puts Color.red("  Invalid choice!"); sleep 0.7
    end
  end
end

# ══════════════════════════════════════════════════════════════
#  C A R D   I N V E N T O R Y   S Y S T E M
# ══════════════════════════════════════════════════════════════

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

def card_color(rarity, text)
  cfg = RARITY_CFG[rarity] || RARITY_CFG[:common]
  Color.send(cfg[:color], text)
end

def word_wrap(text, width)
  lines = []; cur = ""
  text.split.each do |w|
    test = cur.empty? ? w : "#{cur} #{w}"
    if test.length <= width then cur = test
    else lines << cur; cur = w end
  end
  lines << cur unless cur.empty?
  lines
end

def card_border(cfg, frame, top)
  c  = cfg[:color]
  tl = top ? cfg[:tl] : cfg[:bl]
  tr = top ? cfg[:tr] : cfg[:br]
  h  = cfg[:h]
  w  = CARD_W + 2
  inner = case cfg[:anim]
  when :ripple  then (0...w).map { |i| ((i + frame * 2) % (w * 2)) < w / 2 ? "~" : h }.join
  when :shine   then pos = (frame * 3) % w; (0...w).map { |i| (i - pos).abs <= 1 ? "=" : h }.join
  when :glimmer then (0...w).map { rand < 0.12 ? "*" : h }.join
  else h * w
  end
  bold = cfg[:bold_border] || (cfg[:anim] == :pulse && frame.even?)
  s = tl + inner + tr
  bold ? Color.bold(Color.send(c, s)) : Color.send(c, s)
end

def card_row(cfg, content_ansi, content_len, _frame)
  c   = cfg[:color]
  v   = cfg[:v]
  w   = CARD_W + 2
  pad = [w - content_len, 0].max
  lp  = pad / 2; rp = pad - lp
  Color.bold(Color.send(c, v)) + " " * lp + content_ansi + " " * rp + Color.bold(Color.send(c, v))
end

def card_sep(cfg)
  c = cfg[:color]
  Color.bold(Color.send(c, cfg[:lt] + cfg[:h] * (CARD_W + 2) + cfg[:rt]))
end

def render_card_lines(card, index_label: nil, frame: 0, copies: 1)
  r   = card[:rarity]
  cfg = RARITY_CFG[r] || RARITY_CFG[:common]
  c   = cfg[:color]

  name      = card[:name].length > CARD_W ? card[:name][0, CARD_W - 3] + "..." : card[:name]
  icon      = cfg[:icon] * cfg[:stars]
  rname     = cfg[:label]
  type_str  = card[:type] == :unique_skill ? "◆ UNIQUE" : "▲ UPGRADE"
  dl        = word_wrap(card[:description], CARD_W)
  d1        = dl[0] || ""; d2 = dl[1] || ""

  ls = []
  ls << card_border(cfg, frame, true)
  ls << card_row(cfg, Color.bold(Color.send(c, name)), name.length, frame)
  ls << card_sep(cfg)
  ls << card_row(cfg, Color.bold(icon), icon.length, frame)
  ls << card_sep(cfg)
  ls << card_row(cfg, rarity_name_colored(r), rname.length, frame)
  ls << card_row(cfg, Color.dim(type_str), type_str.length, frame)
  ls << card_sep(cfg)
  ls << card_row(cfg, Color.dim(d1), d1.length, frame)
  ls << card_row(cfg, Color.dim(d2), d2.length, frame)
  ls << card_border(cfg, frame, false)

  # Badge: index label + copy count if >1
  copy_tag  = copies > 1 ? Color.bold(Color.green(" x#{copies}")) : ""
  copy_plain = copies > 1 ? " x#{copies}" : ""
  badge      = index_label ? Color.bold(Color.yellow("[ #{index_label} ]")) + copy_tag : ""
  badge_len  = index_label ? "[ #{index_label} ]".length + copy_plain.length : 0
  bpad       = [(CARD_W + 4 - badge_len) / 2, 0].max
  ls << " " * bpad + badge
  ls
end

# ── Detail view (flicker-free) ────────────────────────────────
def card_detail_view(card, copies: 1)
  r   = card[:rarity]
  cfg = RARITY_CFG[r] || RARITY_CFG[:common]
  c   = cfg[:color]
  w   = 44   # total inner span (border to border, excluding the │ chars themselves)
  cw  = w - 2  # usable content width (w minus 1 space padding each side)

  type_str  = card[:type] == :unique_skill ? "◆  UNIQUE SKILL" : "▲  ITEM UPGRADE"
  desc_ls   = word_wrap(card[:description], cw)
  copies_str = copies > 1 ? "Copies: #{copies}  (+#{copies - 1} boost#{"s" if copies > 2})" : "Copies: 1"
  copies_col = copies > 1 ? Color.bold(Color.green(copies_str)) : Color.dim(copies_str)

  make_border = lambda do |top, f|
    tl = top ? cfg[:tl] : cfg[:bl]; tr = top ? cfg[:tr] : cfg[:br]; h = cfg[:h]
    inner = case cfg[:anim]
    when :ripple  then (0...w).map { |i| ((i + f * 2) % (w * 2)) < w / 2 ? "~" : h }.join
    when :shine   then pos = (f * 3) % w; (0...w).map { |i| (i - pos).abs <= 1 ? "=" : h }.join
    when :glimmer then (0...w).map { rand < 0.10 ? "*" : h }.join
    else h * w
    end
    Color.bold(Color.send(c, tl + inner + tr))
  end

  make_row = lambda do |txt, tlen|
    pad = [w - tlen, 0].max; lp = pad / 2; rp = pad - lp
    Color.bold(Color.send(c, cfg[:v])) + " " * lp + txt + " " * rp + Color.bold(Color.send(c, cfg[:v]))
  end

  sep = Color.bold(Color.send(c, cfg[:lt] + cfg[:h] * w + cfg[:rt]))

  build = lambda do |f|
    icon_strip = cfg[:icon] * cfg[:stars]   # e.g. "✦✦✦✦" for legendary
    ls = [""]
    ls << "  " + make_border.call(true, f)
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_row.call(Color.bold(Color.send(c, card[:name])), card[:name].length)
    ls << "  " + make_row.call("", 0)
    ls << "  " + sep
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_row.call(Color.bold(icon_strip), icon_strip.length)
    ls << "  " + make_row.call("", 0)
    ls << "  " + sep
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_row.call(rarity_name_colored(r), cfg[:label].length)
    ls << "  " + make_row.call(Color.dim(type_str), type_str.length)
    ls << "  " + make_row.call(copies_col, copies_str.length)
    ls << "  " + make_row.call("", 0)
    ls << "  " + sep
    ls << "  " + make_row.call("", 0)
    desc_ls.each { |dl| ls << "  " + make_row.call(Color.white(dl), dl.length) }
    ls << "  " + make_row.call("", 0)
    ls << "  " + make_border.call(false, f)
    ls << ""
    ls << Color.dim("  Press any key to go back...")
    ls
  end

  clear
  lines = build.call(0)
  top_idx = 1
  bot_idx = lines.length - 3
  lines.each { |l| puts l }
  $stdout.flush

  frame = 1
  loop do
    ready = IO.select([$stdin], nil, nil, 0.20)
    if ready; $stdin.getch; return; end
    new_lines = build.call(frame)
    total = lines.length
    [top_idx, bot_idx].each do |idx|
      up = total - idx
      print "\e[#{up}A\e[1G#{new_lines[idx]}\e[0K\e[#{up}B\e[1G"
    end
    $stdout.flush
    frame += 1
  end
end

# ── Inventory screen ──────────────────────────────────────────
def open_card_inventory(state)
  # Deduplicate — one entry per unique card name
  raw = (state[:skill_cards] || []) + (state[:active_skills] || [])
  seen = {}
  all_cards = raw.select { |cd| seen[cd[:name]] ? false : (seen[cd[:name]] = true) }
  counts = state[:card_counts] || {}

  if all_cards.empty?
    clear
    draw_header("C A R D   I N V E N T O R Y")
    puts box_line(""); puts box_line(Color.dim("You have no skill cards yet."))
    puts box_line(Color.dim("Win 5 rounds or try the Slot Machine!"))
    puts box_line(""); puts box_line(Color.dim("Press any key to go back...")); draw_footer
    $stdin.getch; return
  end

  sort_mode     = :rarity
  filter_rarity = nil
  page          = 0
  per_page      = 3
  frame         = 0
  full_redraw   = true
  ctrl_h        = 5   # number of lines in the controls block

  ctrl_lines = lambda do
    ls = ["", Color.dim("  " + "─" * 56)]
    nav = [
      Color.bold(Color.yellow("[A]")) + Color.dim(" Prev"),
      Color.bold(Color.yellow("[D]")) + Color.dim(" Next"),
      Color.bold(Color.yellow("[1-3]")) + Color.dim(" Inspect"),
      Color.bold(Color.yellow("[S]")) + Color.dim(" Sort"),
      Color.bold(Color.yellow("[F]")) + Color.dim(" Filter"),
      Color.bold(Color.yellow("[X]")) + Color.dim(" Back"),
    ]
    ls << "  " + nav.join("   ")
    ls << Color.dim("  " + "─" * 56)
    ls << "  Input: "
    ls
  end

  loop do
    sorted = all_cards.sort_by { |cd|
      sort_mode == :rarity ? [RARITY_ORDER.index(cd[:rarity]) || 0, cd[:name]] : [cd[:name]]
    }.reverse
    filtered = filter_rarity ? sorted.select { |cd| cd[:rarity] == filter_rarity } : sorted
    pages    = [(filtered.length / per_page.to_f).ceil, 1].max
    page     = [[page, 0].max, pages - 1].min
    slice    = filtered[page * per_page, per_page] || []

    labeled = slice.each_with_index.map { |cd, i| [cd, (i + 1).to_s] }
    while labeled.length < 3; labeled << nil; end
    cols   = labeled.map { |e| e ? render_card_lines(e[0], index_label: e[1], frame: frame, copies: counts.fetch(e[0][:name], 1)) : Array.new(12, " " * (CARD_W + 4)) }
    max_h  = cols.map(&:length).max
    cols.each { |col| col << "" while col.length < max_h }
    card_rows = max_h.times.map { |i| cols.map { |col| col[i] }.join("    ") }

    if full_redraw
      clear
      # Header
      sparkles = ["✦", "★", "◆", "·"]
      sp_l = sparkles[frame % sparkles.length]; sp_r = sparkles[(frame + 2) % sparkles.length]
      inner_w = 52
      title   = "#{sp_l}  C A R D   C O L L E C T I O N  #{sp_r}"
      t_pad   = [(inner_w - title.length) / 2, 0].max
      t_right = [inner_w - title.length - t_pad, 0].max
      puts Color.bold(Color.yellow("  ╔" + "═" * inner_w + "╗"))
      puts Color.bold(Color.yellow("  ║")) + " " * t_pad + Color.bold(Color.white(title)) + " " * t_right + Color.bold(Color.yellow("║"))
      puts Color.bold(Color.yellow("  ╚" + "═" * inner_w + "╝"))
      puts ""
      rarity_counts = RARITY_ORDER.map { |r| n = all_cards.count { |cd| cd[:rarity] == r }; n > 0 ? card_color(r, "#{rarity_abbrev(r)}:#{n}") : Color.dim("#{rarity_abbrev(r)}:0") }.join(Color.dim("  "))
      puts "  " + Color.dim("Collection: ") + Color.bold(Color.yellow("#{all_cards.length} cards")) + Color.dim("   ") + rarity_counts
      puts "  " + Color.dim("Page #{page + 1}/#{pages}   Sort: ") + Color.bold(Color.cyan(sort_mode.to_s.upcase)) +
           Color.dim("   Filter: ") + (filter_rarity ? card_color(filter_rarity, filter_rarity.to_s.upcase.gsub("_", " ")) : Color.dim("ALL"))
      puts ""
      # Cards
      card_rows.each { |l| puts l }
      # Controls
      ctrl_lines.call.each { |l| puts l }
      $stdout.flush
      full_redraw = false
    end

    ready = IO.select([$stdin], nil, nil, 0.25)
    if ready
      ch = $stdin.getch.downcase
      case ch
      when 'x' then return
      when 'a' then page = (page - 1) % pages; full_redraw = true; frame = 0
      when 'd' then page = (page + 1) % pages; full_redraw = true; frame = 0
      when '1', '2', '3'
        cd = slice[ch.to_i - 1]
        if cd
          card_detail_view(cd, copies: counts.fetch(cd[:name], 1))
          full_redraw = true; frame = 0
        end
      when 's' then sort_mode = sort_mode == :rarity ? :name : :rarity; full_redraw = true; frame = 0
      when 'f' then filter_rarity = cycle_filter(filter_rarity); full_redraw = true; frame = 0
      end
      next
    end

    frame += 1
    next if slice.all? { |cd| cd.nil? || RARITY_CFG.dig(cd[:rarity], :anim) == :none }

    # Re-render cards in-place
    new_cols  = labeled.map { |e| e ? render_card_lines(e[0], index_label: e[1], frame: frame, copies: counts.fetch(e[0][:name], 1)) : Array.new(12, " " * (CARD_W + 4)) }
    new_cols.each { |col| col << "" while col.length < max_h }
    new_card_rows = max_h.times.map { |i| new_cols.map { |col| col[i] }.join("    ") }

    ctrl_h = ctrl_lines.call.length
    total_up = ctrl_h + max_h
    print "\e[#{total_up}A"
    new_card_rows.each { |l| print "\e[1G#{l}\e[0K\n" }
    ctrl_lines.call.each { |l| print "\e[1G#{l}\e[0K\n" }
    $stdout.flush
  end
end

def rarity_abbrev(r)
  case r
  when :common     then "C"
  when :rare       then "R"
  when :ultra_rare then "UR"
  when :legendary  then "L"
  when :mythic     then "M"
  when :gold       then "G"
  else "?"
  end
end

def cycle_filter(current)
  order = [nil] + RARITY_ORDER
  idx   = order.index(current) || 0
  order[(idx + 1) % order.length]
end


# ── Shop ──────────────────────────────────────────────────────
def open_shop(state)
  loop do
    clear
    draw_header("  S H O P  ")
    puts box_line(Color.dim("Your points: ") + Color.bold(Color.yellow("#{state[:score]} pts")))
    draw_divider

    SHOP_ITEMS.each_with_index do |item, i|
      if item[:type] == :permanent
        level      = state[:permanent_bonuses][item[:id]] || 0
        no_cap     = item[:id] == :bonus_point && state[:permanent_bonuses][:bonus_point_no_cap]
        at_max     = !no_cap && item[:max] && level >= item[:max]
        owned      = if at_max
          Color.dim("[MAX]")
        elsif no_cap
          Color.bold(Color.yellow("[Lv.#{level} ∞]"))
        else
          Color.dim("[Lv.#{level}]")
        end
      else
        qty   = state[:inventory][item[:id]] || 0
        owned = qty > 0 ? Color.cyan("[x#{qty}]") : ""
      end
      can_afford = state[:score] >= item[:cost]
      cost_str   = can_afford ? Color.green("#{item[:cost]}pts") : Color.red("#{item[:cost]}pts")
      puts box_line("#{Color.bold(Color.yellow((i+1).to_s))}. [#{item[:emoji]}] #{Color.bold(item[:name])} #{cost_str} #{owned}")
      puts box_line("     #{Color.dim(item[:description])}")
    end

    draw_divider
    slotcost = slot_spin_cost(state)
    slotafford = state[:score] >= slotcost
    puts box_line("#{Color.bold(Color.yellow('L'))}. [~] Slot Machine  #{slotafford ? Color.green("#{slotcost}pts/spin") : Color.red("#{slotcost}pts/spin")}  #{Color.dim("(33% chance: Skill Card)")}")
    draw_divider
    puts box_line("#{Color.bold(Color.yellow('X'))}. Leave shop")
    draw_footer
    print "  Buy (1-#{SHOP_ITEMS.length}), [L]Slots, or X: "

    input = $stdin.getch.strip.downcase
    puts input
    break if input == 'x'

    if input == 'l'
      open_slot_machine(state)
      next
    end

    idx = input.to_i - 1
    next unless (0...SHOP_ITEMS.length).include?(idx)
    item = SHOP_ITEMS[idx]

    if item[:type] == :permanent
      level  = state[:permanent_bonuses][item[:id]] || 0
      no_cap = item[:id] == :bonus_point && state[:permanent_bonuses][:bonus_point_no_cap]
      if !no_cap && item[:max] && level >= item[:max]
        puts Color.red("  Already at max level!"); sleep 1; next
      end
    end

    if state[:score] < item[:cost]
      puts Color.red("  Not enough points!"); sleep 1; next
    end

    state[:score] -= item[:cost]
    if item[:type] == :permanent
      state[:permanent_bonuses][item[:id]] ||= 0
      state[:permanent_bonuses][item[:id]] += 1
      puts Color.green("  [#{item[:emoji]}] #{item[:name]} upgraded to level #{state[:permanent_bonuses][item[:id]]}!")
    else
      state[:inventory][item[:id]] ||= 0
      state[:inventory][item[:id]] += 1
      puts Color.green("  [#{item[:emoji]}] #{item[:name]} purchased!")
    end
    sleep 1
  end
end

DEV_PASSCODE = "I_LOVE_CISCO"

def dev_passcode_prompt
  clear
  puts Color.bold(Color.red("  ╔══════════════════════════════════════════════════╗"))
  puts Color.bold(Color.red("  ║          ⚠  D E V   A C C E S S  ⚠             ║"))
  puts Color.bold(Color.red("  ╚══════════════════════════════════════════════════╝"))
  puts
  puts Color.dim("  Enter passcode (Enter to confirm, Esc to cancel):")
  print "  > "

  input = ""
  loop do
    ch = $stdin.getch
    case ch
    when "\r", "\n"   # Enter — confirm
      puts
      break
    when "\e"         # Escape — cancel
      puts
      return false
    when "\u007F", "\b"  # Backspace
      unless input.empty?
        input = input[0..-2]
        print "\b \b"
      end
    else
      input += ch
      print "*"   # mask input
    end
  end

  if input == DEV_PASSCODE
    true
  else
    puts Color.red("  Incorrect passcode.")
    sleep 1
    false
  end
end

# ── Dev Menu ──────────────────────────────────────────────────
def open_dev_menu(state, difficulty_ref)
  loop do
    clear
    puts Color.bold(Color.red("  ╔══════════════════════════════════════════════════╗"))
    puts Color.bold(Color.red("  ║          ⚠  D E V   M E N U  ⚠                 ║"))
    puts Color.bold(Color.red("  ╚══════════════════════════════════════════════════╝"))
    puts

    # Current state snapshot
    puts Color.bold(Color.white("  ── State ──────────────────────────────────────────"))
    puts "  " + Color.dim("Score:       ") + Color.bold(Color.yellow("#{state[:score]} pts"))
    puts "  " + Color.dim("Wins/Losses: ") + Color.green("#{state[:wins]}W") + Color.dim(" / ") + Color.red("#{state[:losses]}L")
    puts "  " + Color.dim("Streak:      ") + Color.cyan("#{state[:streak]}x")
    puts "  " + Color.dim("Difficulty:  ") + Color.magenta(difficulty_ref[0].to_s.upcase)
    puts "  " + Color.dim("Rounds:      ") + "#{state[:total_rounds]}"
    puts "  " + Color.dim("Cards:       ") + "#{((state[:skill_cards]||[]) + (state[:active_skills]||[])).length} collected"
    puts

    puts Color.bold(Color.white("  ── Points ─────────────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[1]")) + " Add 100 pts"
    puts "  " + Color.bold(Color.yellow("[2]")) + " Add 1000 pts"
    puts "  " + Color.bold(Color.yellow("[3]")) + " Add 10000 pts"
    puts "  " + Color.bold(Color.yellow("[4]")) + " Wipe points to 0"
    puts

    puts Color.bold(Color.white("  ── Cards & Events ─────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[5]")) + " Trigger skill card selection"
    puts "  " + Color.bold(Color.yellow("[6]")) + " Trigger slot machine"
    puts "  " + Color.bold(Color.yellow("[7]")) + " Give one random card (instant)"
    puts "  " + Color.bold(Color.yellow("[G]")) + " Give ALL cards (skips owned)"
    puts "  " + Color.bold(Color.yellow("[8]")) + " Wipe all cards"
    puts "  " + Color.bold(Color.yellow("[9]")) + " Force Gold Card ceremony"
    puts

    puts Color.bold(Color.white("  ── Difficulty ──────────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[E]")) + " Set Easy"
    puts "  " + Color.bold(Color.yellow("[M]")) + " Set Medium"
    puts "  " + Color.bold(Color.yellow("[H]")) + " Set Hard"
    puts "  " + Color.bold(Color.yellow("[X]")) + " Set Extreme"
    puts

    puts Color.bold(Color.white("  ── Progress ────────────────────────────────────────"))
    puts "  " + Color.bold(Color.yellow("[W]")) + " Add 5 wins (triggers card roll if at milestone)"
    puts "  " + Color.bold(Color.yellow("[R]")) + " Reset all state"
    puts
    puts "  " + Color.bold(Color.yellow("[0]")) + " Close dev menu"
    puts

    print Color.red("  DEV> ")
    ch = $stdin.getch.downcase
    puts ch

    case ch
    when '1' then state[:score] += 100;   puts Color.green("  +100 pts"); sleep 0.6
    when '2' then state[:score] += 1000;  puts Color.green("  +1000 pts"); sleep 0.6
    when '3' then state[:score] += 10000; puts Color.green("  +10000 pts"); sleep 0.6
    when '4' then state[:score] = 0;      puts Color.red("  Points wiped"); sleep 0.6

    when '5'
      skill_card_selection_menu(state)

    when '6'
      open_slot_machine(state)

    when '7'
      _, card = roll_skill_cards(1).first
      is_dup  = already_owns?(state, card)
      apply_skill_card(state, card, stack_boost: is_dup && stackable_card?(card))
      tag = is_dup ? " (+15% boost, duplicate)" : ""
      puts Color.green("  Gave: #{card[:name]} [#{card[:rarity]}]#{tag}")
      sleep 1.2

    when 'g'
      given  = 0
      skipped = 0
      SKILL_CARDS.each_value do |card|
        if already_owns?(state, card)
          skipped += 1
        else
          apply_skill_card(state, card)
          given += 1
        end
      end
      puts Color.green("  Gave #{given} new card#{"s" if given != 1}.")
      puts Color.dim("  Skipped #{skipped} already owned.") if skipped > 0
      sleep 1.2

    when '8'
      state[:skill_cards]  = []
      state[:active_skills] = []
      state[:card_counts]  = {}
      state[:permanent_bonuses].delete(:bonus_multiplier)
      state[:permanent_bonuses].delete(:double_multiplier)
      state[:permanent_bonuses].delete(:gold_card)
      puts Color.red("  All cards wiped"); sleep 0.7

    when '9'
      award_gold_card(state)

    when 'e' then difficulty_ref[0] = :easy;    puts Color.green("  Difficulty → EASY"); sleep 0.6
    when 'm' then difficulty_ref[0] = :medium;  puts Color.green("  Difficulty → MEDIUM"); sleep 0.6
    when 'h' then difficulty_ref[0] = :hard;    puts Color.green("  Difficulty → HARD"); sleep 0.6
    when 'x' then difficulty_ref[0] = :extreme; puts Color.green("  Difficulty → EXTREME"); sleep 0.6

    when 'w'
      state[:wins] += 5
      puts Color.green("  +5 wins (total: #{state[:wins]})")
      sleep 0.5
      if state[:wins] % 5 == 0
        puts Color.cyan("  Triggering card roll...")
        sleep 0.6
        skill_card_selection_menu(state)
      end

    when 'r'
      state[:score]            = 0
      state[:wins]             = 0
      state[:losses]           = 0
      state[:streak]           = 1
      state[:peak_streak]      = 1
      state[:total_rounds]     = 0
      state[:inventory]        = {}
      state[:permanent_bonuses] = {}
      state[:temp_multiplier]  = nil
      state[:pending_extra_lives] = 0
      state[:skill_cards]      = []
      state[:active_skills]    = []
      state[:card_counts]      = {}
      difficulty_ref[0]        = :easy
      puts Color.red("  Full state reset"); sleep 0.8

    when '0' then return
    else puts Color.red("  Unknown command"); sleep 0.5
    end
  end
end

# ── Round-end prompt ──────────────────────────────────────────
def round_end_prompt(state, result, word, difficulty_ref)
  puts
  if result == :win
    puts center_text(Color.bold(Color.green("You won!  The word was: #{word.upcase}")))
  else
    puts center_text(Color.bold(Color.red("Game over!  The word was: #{word.upcase}")))
  end
  puts
  puts center_text(Color.bold(Color.yellow("Score: #{state[:score]} pts")) +
                   Color.dim("  |  W:#{state[:wins]} L:#{state[:losses]}  Peak streak: #{state[:peak_streak]}x"))
  puts
  puts center_text("[S] Shop   [I] Cards   [-] Dev   [Y] Play Again   [N] Quit")
  puts

  loop do
    print "  Choice: "
    ch = $stdin.getch.downcase
    puts ch
    case ch
    when 's' then open_shop(state)
             puts center_text("[S] Shop   [I] Cards   [-] Dev   [Y] Play Again   [N] Quit")
    when 'i' then open_card_inventory(state)
             puts center_text("[S] Shop   [I] Cards   [-] Dev   [Y] Play Again   [N] Quit")
    when '-'
      if dev_passcode_prompt
        open_dev_menu(state, difficulty_ref)
      end
      puts center_text("[S] Shop   [I] Cards   [-] Dev   [Y] Play Again   [N] Quit")
    when 'y' then return :play
    when 'n' then return :quit
    end
  end
end

# ── Play one round ────────────────────────────────────────────
def play_round(category, word, state, difficulty = :easy)
  guessed       = []
  wrong_letters = []
  wrong_count   = 0
  max_wrong_ref = [BASE_MAX_WRONG + (state[:pending_extra_lives] || 0)]
  state[:pending_extra_lives] = 0
  safety_armed  = [false]
  safety_used   = [false]

  # Omniscience: pre-reveal first and last letter of the word
  if (state[:active_skills] || []).any? { |c| c[:effect][:see_word_hint] }
    guessed |= [word[0], word[-1]].compact.uniq
  end

  temp_mult            = state[:temp_multiplier] || 1
  state[:temp_multiplier] = nil

  loop do
    draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)

    ch = $stdin.getch.downcase

    if ch == '+'
      consumable_menu(word, guessed, state, max_wrong_ref, safety_armed)

      if word.chars.uniq.all? { |c| guessed.include?(c) }
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0])
        state[:wins] += 1
        state[:peak_streak] = [state[:streak], state[:peak_streak] || 1].max
        return :win
      end
      next
    end

    next unless ch.match?(/[a-z]/)
    letter = ch

    if guessed.include?(letter) || wrong_letters.include?(letter)
      puts "\n  " + Color.yellow("Already guessed '#{letter}'!"); sleep 0.7; next
    end

    if word.include?(letter)
      guessed << letter

      base          = 1 + (state[:permanent_bonuses][:bonus_point] || 0)
      eff           = state[:streak] * temp_mult
      earned        = base * eff
      state[:score] += earned

      streak_chain = (1..state[:streak]).map { |n| Color.bold(Color.yellow("#{n}x")) }.join(Color.dim(" → "))
      next_mult    = (state[:streak] + 1) * temp_mult

      puts "\n  " + Color.green("+#{earned} pts") +
           Color.dim("  [") + streak_chain + Color.dim("]") +
           Color.dim("  Next correct: ") + Color.bold(Color.cyan("#{next_mult}x"))

      state[:streak] += 1
      sleep 0.6

      if word.chars.uniq.all? { |c| guessed.include?(c) }
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)
        state[:wins] += 1
        state[:peak_streak] = [state[:streak], state[:peak_streak] || 1].max
        return :win
      end

    else
      if safety_armed[0] && !safety_used[0]
        safety_used[0] = true
        wrong_letters << letter
        puts "\n  " + Color.yellow("[S] Safety Net absorbed '#{letter.upcase}'! (still #{max_wrong_ref[0] - wrong_count} lives)")
        sleep 0.9
        next
      end

      wrong_letters << letter
      wrong_count   += 1

      if state[:streak] > 1
        puts "\n  " + Color.red("Streak broken!") + Color.dim("  (was #{state[:streak]}x → back to 1x)")
        sleep 0.7
      end
      state[:streak] = 1

      if wrong_count >= max_wrong_ref[0]
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0], difficulty)
        state[:losses] += 1
        state[:peak_streak] = [state[:peak_streak] || 1, 1].max
        return :lose
      end
    end
  end
end

# ── Difficulty Transition Prompts ──────────────────────────
def show_medium_prompt
  clear
  draw_header("★ DIFFICULTY INCREASED ★")
  draw_divider
  puts box_line(Color.bold(Color.yellow("You've completed 8 rounds!")))
  draw_divider
  puts box_line(Color.bold(Color.yellow("MEDIUM DIFFICULTY UNLOCKED")))
  draw_divider
  puts box_line("Difficulty Changes:")
  puts box_line(Color.cyan("  • Categories are now RANDOM"))
  puts box_line(Color.dim("  • Category is still shown (you can adapt your strategy)"))
  puts box_line(Color.dim("  • Word selection is completely unpredictable"))
  draw_divider
  puts box_line(Color.dim("Prepare yourself for varied challenges!"))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Press Enter to continue...")))
  draw_footer
  $stdin.gets
end

def show_hard_prompt
  clear
  draw_header("★ EXTREME DIFFICULTY UNLOCKED ★")
  draw_divider
  puts box_line(Color.bold(Color.red("You've completed 15 rounds!")))
  draw_divider
  puts box_line(Color.bold(Color.red("HARD DIFFICULTY UNLOCKED")))
  draw_divider
  puts box_line("Difficulty Changes:")
  puts box_line(Color.red("  • Categories are now HIDDEN"))
  puts box_line(Color.dim("  • You won't know what type of word you're guessing"))
  puts box_line(Color.dim("  • Word length is still shown"))
  puts box_line(Color.dim("  • Pure guessing skill is required!"))
  draw_divider
  puts box_line(Color.yellow("This is a significant jump in difficulty. Stay sharp!"))
  draw_divider
  puts box_line(Color.bold(Color.yellow("Press Enter to continue...")))
  draw_footer
  $stdin.gets
end

# ── Extreme Mode Disclaimer ───────────────────────────────
def show_extreme_prompt
  loop do
    clear
    draw_header("UNLOCK EXTREME MODE")
    draw_divider
    puts box_line(Color.bold(Color.magenta("You have completed 25 rounds!")))
    draw_divider
    puts box_line(Color.bold(Color.yellow("EXTREME MODE DISCLAIMER")))
    draw_divider
    puts box_line(Color.red("WARNING: EXTREME DIFFICULTY"))
    draw_divider
    puts box_line("Difficulty Modifiers:")
    puts box_line(Color.red("  * No category hints"))
    puts box_line(Color.red("  * Word length is hidden"))
    puts box_line(Color.red("  * Completely random selection"))
    puts box_line(Color.red("  * Maximum challenge!"))
    draw_divider
    puts box_line("Continue in HARD mode or unlock EXTREME?")
    draw_divider
    puts box_line(Color.bold(Color.yellow("[H] Hard Mode   [E] Extreme Mode")))
    draw_footer
    print "  Choice: "

    input = $stdin.getch.downcase
    puts input
    return :hard if input == 'h'
    return :extreme if input == 'e'
    puts Color.red("  Invalid choice!"); sleep 0.7
  end
end

# ── Main ──────────────────────────────────────────────────────
def main
  state = {
    score:             0,
    wins:              0,
    losses:            0,
    streak:            1,
    peak_streak:       1,
    total_rounds:      0,
    inventory:         {},
    permanent_bonuses: {},
    temp_multiplier:   nil,
    pending_extra_lives: 0,
    skill_cards:       [],
    active_skills:     [],
    card_counts:       {}
  }

  clear
  draw_header("H  A  N  G  M  A  N")
  puts box_line("")
  puts box_line(Color.dim("Guess letters to reveal the hidden word."))
  puts box_line(Color.dim("Each correct letter earns points x your streak."))
  puts box_line(Color.dim("Win 5 rounds to roll for a skill card!"))
  puts box_line(Color.dim("Spend points in the Shop on powerful upgrades."))
  puts box_line(Color.dim("Press + to use consumables during gameplay!"))
  puts box_line("")
  puts box_line(Color.bold("Press any key to start..."))
  draw_footer
  $stdin.getch

  difficulty_ref = [:easy]

  loop do
    state[:total_rounds] += 1

    if state[:total_rounds] == 9 && difficulty_ref[0] == :easy
      show_medium_prompt
      difficulty_ref[0] = :medium
    elsif state[:total_rounds] == 16 && difficulty_ref[0] == :medium
      show_hard_prompt
      difficulty_ref[0] = :hard
    elsif state[:total_rounds] == 26 && difficulty_ref[0] == :hard
      difficulty_ref[0] = show_extreme_prompt
    end

    category = choose_category(difficulty_ref[0])
    word     = CATEGORIES[category].sample.downcase
    result   = play_round(category, word, state, difficulty_ref[0])
    action   = round_end_prompt(state, result, word, difficulty_ref)
    break if action == :quit

    if state[:wins] % 5 == 0 && state[:wins] > 0
      skill_card_selection_menu(state)
    end
  end

  clear
  draw_header("G  A  M  E  O  V  E  R")
  puts box_line(Color.bold(Color.yellow("Final Score:  #{state[:score]} pts")))
  puts box_line(Color.dim("Wins: #{state[:wins]}   Losses: #{state[:losses]}   Peak Streak: #{state[:peak_streak]}x"))
  puts box_line(Color.dim("Skill Cards Collected: #{state[:skill_cards].length}"))
  draw_footer
  puts
end

main