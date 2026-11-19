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
require_relative 'lib/leaderboard'

# Load configuration files
require_relative 'config/constants'
require_relative 'config/items'
require_relative 'config/difficulty_presets'

# Load menu files
require_relative 'menus/saves'

# Load game files
require_relative 'game/game'

# Start the game with save/load
begin
	current_username = nil
	loop do
		game_selection = main_menu_with_load(current_username)
		current_username = game_selection[:username]
		break unless main(game_selection) == :main_menu
	end
rescue StandardError => error
	warn "\nHangman Plus encountered an error: #{error.class}: #{error.message}"
	warn error.backtrace.join("\n")
	if $stdin.tty?
		warn "\nPress Enter to close this message..."
		$stdin.gets
	end
	exit 1
end
