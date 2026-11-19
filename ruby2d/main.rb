#!/usr/bin/env ruby
# encoding: utf-8
# Hangman+ Ruby2D Edition - Main Entry Point

require 'ruby2d'
require_relative 'button'
require_relative 'menu'
require_relative 'game_screen'
require_relative 'hangman_game'

set title: "Hangman+", width: 1024, height: 768, background: 'navy'

# Game state
current_screen = :menu
menu_buttons = []
game = nil
letter_buttons = []
end_game_buttons = []

# Create main menu on startup
menu_buttons = create_main_menu

# Handle keyboard input
on :key_down do |event|
  if event.key == 'q'
    close
  end
end

# Handle mouse clicks
on :mouse_down do |event|
  case current_screen
  when :menu
    menu_buttons.each do |btn_data|
      if btn_data[:button].clicked?(event.x, event.y)
        case btn_data[:action]
        when :quit
          close
        when :new_game
          # Clear the menu
          menu_buttons.each { |btn| btn[:button].remove }
          clear
          
          # Start new game
          game = HangmanGame.new
          current_screen = :game
          letter_buttons = create_game_screen(game)
          
        when :load_game
          puts "Load Game selected!"
          # TODO: Load game
        end
      end
    end
  when :game
    # Check letter button clicks
    letter_buttons.each do |btn_data|
      if btn_data[:button].clicked?(event.x, event.y)
        letter = btn_data[:letter]
        game.guess(letter)
        
        # Clear and redraw
        clear
        letter_buttons = create_game_screen(game)
        
        # Check for win/lose - show end game buttons
        if game.state == :won
          Text.new("You Won!", x: 350, y: 400, size: 56, color: 'lime')
          end_game_buttons = create_end_game_buttons
          current_screen = :game_end
        elsif game.state == :lost
          Text.new("Game Over! Word: #{game.word}", x: 250, y: 400, size: 40, color: 'red')
          end_game_buttons = create_end_game_buttons
          current_screen = :game_end
        end
      end
    end
  when :game_end
    # Check end game button clicks
    end_game_buttons.each do |btn_data|
      if btn_data[:button].clicked?(event.x, event.y)
        case btn_data[:action]
        when :next_round
          # Clear and start next round
          clear
          game.next_round
          current_screen = :game
          letter_buttons = create_game_screen(game)
          
        when :menu
          # Back to menu
          clear
          menu_buttons = create_main_menu
          current_screen = :menu
        end
      end
    end
  end
end

show
