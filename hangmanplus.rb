#!/usr/bin/env ruby
# encoding: utf-8
# ============================================================
#  H A N G M A N  —  Ruby Terminal Edition  (with Shop & Skill Cards!)
# ============================================================

require 'io/console'

# Load library files
require_relative 'lib/color'
require_relative 'lib/display'
require_relative 'lib/effects'
require_relative 'lib/save_system'

# Load configuration files
require_relative 'config/constants'
require_relative 'config/items'
require_relative 'config/skins'

# Load menu files
require_relative 'menus/saves'

# Load game files
require_relative 'game/game'

# Start the game with save/load
chosen_slot = main_menu_with_load
main(chosen_slot)
