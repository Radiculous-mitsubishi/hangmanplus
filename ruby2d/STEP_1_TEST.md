# Step 1: Test Ruby2D Installation

## What we're doing
We're creating the simplest possible Ruby2D program to verify everything works.

## Steps

### 1. Install SDL2 (One time only)

**Windows:**
```
choco install sdl2
```

Or download from: https://libsdl.org/download-2.0.php

**Mac:**
```
brew install sdl2
```

**Linux:**
```
sudo apt-get install libsdl2-dev
```

### 2. Install gems

Go to the `ruby2d` folder and run:
```bash
bundle install
```

This reads the Gemfile and installs Ruby2D.

### 3. Run the test

```bash
ruby main.rb
```

You should see:
- A navy blue window
- Gold text saying "Hello! Ruby2D is working!"

**If it works:** Great! We're ready to build the game.
**If it doesn't:** The error message will tell us what's wrong.

## What happened

`main.rb` is doing very simple things:
1. `require 'ruby2d'` - Load the Ruby2D library
2. `set title: ...` - Create a window (1024x768 pixels, navy background)
3. `Text.new(...)` - Draw text on the screen
4. `show` - Display the window and keep it open

That's it! No loops, no callbacks, nothing complicated.

## Next Step

Once you confirm it works, we'll add:
- A button you can click
- Input handling
- Screen management

Take your time!
