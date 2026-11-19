DIFFICULTY_PRESETS = {
  standard: {
    name: 'Standard',
    description: 'Current Hangman+ progression and rules.',
    starting_difficulty: :easy,
    medium_at: 9,
    hard_at: 16,
    extreme_at: 26,
    extreme_optional: true,
    max_wrong: 6,
    round_timer: nil,
    automatic_transitions: false
  },
  relaxed: {
    name: 'Relaxed',
    description: 'Eight misses; slower progression through the tiers.',
    starting_difficulty: :easy,
    medium_at: 15,
    hard_at: 31,
    extreme_at: 51,
    extreme_optional: true,
    max_wrong: 8,
    round_timer: nil,
    automatic_transitions: false
  },
  speedrun: {
    name: 'Speedrun',
    description: 'Thirty seconds to solve each word.',
    starting_difficulty: :easy,
    medium_at: 9,
    hard_at: 16,
    extreme_at: 26,
    extreme_optional: true,
    max_wrong: 6,
    round_timer: 30,
    automatic_transitions: false
  },
  hardcore: {
    name: 'Hardcore',
    description: 'Starts Medium; 5 misses; Extreme mandatory after 40.',
    starting_difficulty: :medium,
    medium_at: 1,
    hard_at: 16,
    extreme_at: 41,
    extreme_optional: false,
    max_wrong: 5,
    round_timer: nil,
    automatic_transitions: true
  }
}.freeze

DEFAULT_DIFFICULTY_PRESET = :standard

def difficulty_preset_settings(preset)
  key = preset.respond_to?(:to_sym) ? preset.to_sym : DEFAULT_DIFFICULTY_PRESET
  DIFFICULTY_PRESETS[key] || DIFFICULTY_PRESETS[DEFAULT_DIFFICULTY_PRESET]
end
