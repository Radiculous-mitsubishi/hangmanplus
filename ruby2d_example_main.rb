#!/usr/bin/env ruby
# encoding: utf-8
# Hangman+ Ruby2D Version - Main Entry Point

require 'ruby2d'

# Set window properties
set title: "Hangman+", width: 1024, height: 768, background: 'navy'

# Load configuration and game logic
require_relative 'config/constants'
require_relative 'config/colors_ruby2d'
require_relative 'lib/save_system'
require_relative 'lib/ui/components'
require_relative 'screens/screen'
require_relative 'screens/main_menu'

# Game State Manager
class GameManager
  attr_accessor :state, :current_screen, :window
  
  def initialize(window)
    @window = window
    @state = {
      score: 0,
      wins: 0,
      losses: 0,
      streak: 1,
      peak_streak: 1,
      total_rounds: 0,
      inventory: {},
      permanent_bonuses: {},
      skill_cards: [],
      active_skills: [],
      card_counts: {},
      difficulty: :easy
    }
    
    # Start with main menu
    @current_screen = MainMenu.new(self)
  end
  
  def render
    @current_screen.render(@window)
  end
  
  def update
    @current_screen.update
  end
  
  def handle_key_down(key)
    @current_screen.handle_key_down(key)
  end
  
  def handle_mouse_down(x, y)
    @current_screen.handle_mouse_down(x, y)
  end
  
  def change_screen(screen_class, *args)
    @current_screen = screen_class.new(self, *args)
  end
end

# Initialize game manager
game = GameManager.new(Window)

# Render loop
on :draw do
  game.render
  game.update
end

# Input handling
on :key_down do |event|
  game.handle_key_down(event.key)
end

on :mouse_down do |event|
  game.handle_mouse_down(event.x, event.y)
end

# Start the game
show
