#!/usr/bin/env ruby
# ============================================================
#  H A N G M A N  —  Ruby Terminal Edition  (with Shop!)
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
end

# ── Word categories ─────────────────────────────────────────
CATEGORIES = {
  "Household Items" => %w[
    refrigerator microwave dishwasher pillowcase curtains
    bookshelf lampshade broom dustpan colander spatula
    tablecloth wardrobe cabinet toaster blender
  ],
  "Tanks" => %w[
    abrams leopard challenger panzer tiger
    sherman pershing centurion merkava crusader
    chieftain firefly matilda panther hellcat
  ],
  "Utilities" => %w[
    electricity plumbing broadband sewage heating
    waterworks gasline telephone recycling drainage
    transformer substation reservoir pipeline generator
  ],
  "Animals" => %w[
    hippopotamus chimpanzee rhinoceros salamander
    crocodile armadillo platypus chameleon
    flamingo porcupine wolverine albatross jellyfish
  ],
  "Countries" => %w[
    mozambique kazakhstan liechtenstein azerbaijan
    madagascar switzerland philippines uzbekistan
    cambodia venezuela argentina indonesia
  ],
  "Space" => %w[
    nebula asteroid comet galaxy pulsar
    supernova blackhole quasar telescope satellite
    cosmonaut trajectory atmosphere exoplanet orbit
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

  puts box_line(Color.dim("Score: ") + score_str + "   " + streak_str + "  " + base_str)
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
def draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong)
  clear
  draw_header("H  A  N  G  M  A  N")
  draw_hud(state)
  draw_hangman(wrong_count, max_wrong)
  draw_divider

  puts box_line(Color.dim("Category: ") + Color.bold(Color.magenta(category)))

  display = word.chars.map { |c|
    guessed.include?(c) ? Color.bold(Color.green(" #{c} ")) : Color.dim(" _ ")
  }.join
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

# ── Category menu ─────────────────────────────────────────────
def choose_category
  keys = CATEGORIES.keys
  loop do
    clear
    draw_header("Choose a Word Category")
    keys.each_with_index do |name, i|
      puts box_line("#{Color.bold(Color.yellow((i+1).to_s))}. #{name} #{Color.dim("(#{CATEGORIES[name].length} words)")}")
    end
    puts box_line("#{Color.bold(Color.yellow('R'))}. Random category")
    draw_footer
    print "  Choice: "

    input = $stdin.getch.strip.downcase
    puts input
    return keys.sample   if input == 'r'
    return keys[input.to_i - 1] if (1..keys.length).include?(input.to_i)
    puts Color.red("  Invalid."); sleep 0.7
  end
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
        level  = state[:permanent_bonuses][item[:id]] || 0
        at_max = item[:max] && level >= item[:max]
        owned  = at_max ? Color.dim("[MAX]") : Color.dim("[Lv.#{level}]")
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
    puts box_line("#{Color.bold(Color.yellow('X'))}. Leave shop")
    draw_footer
    print "  Buy (1-#{SHOP_ITEMS.length}) or X: "

    input = $stdin.getch.strip.downcase
    puts input
    break if input == 'x'

    idx = input.to_i - 1
    next unless (0...SHOP_ITEMS.length).include?(idx)
    item = SHOP_ITEMS[idx]

    if item[:type] == :permanent
      level = state[:permanent_bonuses][item[:id]] || 0
      if item[:max] && level >= item[:max]
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

# ── Round-end prompt ──────────────────────────────────────────
def round_end_prompt(state, result, word)
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
  puts center_text("[S] Shop   [Y] Play Again   [N] Quit")
  puts

  loop do
    print "  Choice: "
    ch = $stdin.getch.downcase
    puts ch
    case ch
    when 's' then open_shop(state)
             puts center_text("[S] Shop   [Y] Play Again   [N] Quit")
    when 'y' then return :play
    when 'n' then return :quit
    end
  end
end

# ── Play one round ────────────────────────────────────────────
def play_round(category, word, state)
  guessed       = []
  wrong_letters = []
  wrong_count   = 0
  max_wrong_ref = [BASE_MAX_WRONG + (state[:pending_extra_lives] || 0)]
  state[:pending_extra_lives] = 0  # consume pending extra lives
  safety_armed  = [false]
  safety_used   = [false]

  # Snapshot temp_multiplier at round start, then consume it
  temp_mult            = state[:temp_multiplier] || 1
  state[:temp_multiplier] = nil

  loop do
    draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0])

    ch = $stdin.getch.downcase

    # Open consumables menu with '+'
    if ch == '+'
      consumable_menu(word, guessed, state, max_wrong_ref, safety_armed)

      # After reveal, check win immediately
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

      # Show streak chain: 1x → 2x → 3x ... and what comes next
      streak_chain = (1..state[:streak]).map { |n| Color.bold(Color.yellow("#{n}x")) }.join(Color.dim(" → "))
      next_mult    = (state[:streak] + 1) * temp_mult

      puts "\n  " + Color.green("+#{earned} pts") +
           Color.dim("  [") + streak_chain + Color.dim("]") +
           Color.dim("  Next correct: ") + Color.bold(Color.cyan("#{next_mult}x"))

      # Advance streak AFTER displaying, so next letter benefits
      state[:streak] += 1
      sleep 0.6

      if word.chars.uniq.all? { |c| guessed.include?(c) }
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0])
        state[:wins] += 1
        state[:peak_streak] = [state[:streak], state[:peak_streak] || 1].max
        return :win
      end

    else
      # Safety net absorbs the FIRST wrong guess if armed and not yet used
      if safety_armed[0] && !safety_used[0]
        safety_used[0] = true
        wrong_letters << letter
        puts "\n  " + Color.yellow("[S] Safety Net absorbed '#{letter.upcase}'! (still #{max_wrong_ref[0] - wrong_count} lives)")
        sleep 0.9
        next
      end

      wrong_letters << letter
      wrong_count   += 1

      # Streak broken feedback
      if state[:streak] > 1
        puts "\n  " + Color.red("Streak broken!") + Color.dim("  (was #{state[:streak]}x → back to 1x)")
        sleep 0.7
      end
      state[:streak] = 1   # reset to base

      if wrong_count >= max_wrong_ref[0]
        draw_screen(category, word, guessed, wrong_letters, wrong_count, state, max_wrong_ref[0])
        state[:losses] += 1
        state[:peak_streak] = [state[:peak_streak] || 1, 1].max
        return :lose
      end
    end
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
    inventory:         {},
    permanent_bonuses: {},
    temp_multiplier:   nil,
    pending_extra_lives: 0
  }

  clear
  draw_header("H  A  N  G  M  A  N")
  puts box_line("")
  puts box_line(Color.dim("Guess letters to reveal the hidden word."))
  puts box_line(Color.dim("Each correct letter earns points x your streak."))
  puts box_line(Color.dim("Win rounds to grow your streak multiplier!"))
  puts box_line(Color.dim("Spend points in the Shop on powerful upgrades."))
  puts box_line(Color.dim("Press + to use consumables during gameplay!"))
  puts box_line("")
  puts box_line(Color.bold("Press any key to start..."))
  draw_footer
  $stdin.getch

  loop do
    category = choose_category
    word     = CATEGORIES[category].sample.downcase
    result   = play_round(category, word, state)
    action   = round_end_prompt(state, result, word)
    break if action == :quit
  end

  clear
  draw_header("G  A  M  E  O  V  E  R")
  puts box_line(Color.bold(Color.yellow("Final Score:  #{state[:score]} pts")))
  puts box_line(Color.dim("Wins: #{state[:wins]}   Losses: #{state[:losses]}   Peak Streak: #{state[:peak_streak]}x"))
  draw_footer
  puts
end

main
