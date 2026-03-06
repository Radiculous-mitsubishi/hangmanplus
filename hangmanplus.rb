# v12 hangmanplus.rb

# Code for Hangman Plus game
# New feature: Skill Card Reroll as a shop item

class HangmanPlus
  def initialize
    @shop_items = []
  end

  def add_shop_item(item)
    @shop_items << item
  end

  def show_shop_items
    puts "Available Shop Items:"
    @shop_items.each { |item| puts item }
  end
end

# Adding the new shop item
hangman = HangmanPlus.new
hangman.add_shop_item('Skill Card Reroll')
hangman.show_shop_items
