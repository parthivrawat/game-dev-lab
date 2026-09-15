# Lesson 1: What is a Game?

## 🎯 Learning Objectives

By the end of this lesson, you will understand:
- What defines a game
- The core components every game has
- What a game loop is and why it's fundamental
- The difference between game logic and rendering
- How games run in real-time

---

## 🎮 What is a Game?

### Definition

A **game** is an interactive system where:
1. **A player** makes decisions and takes actions
2. **Rules** govern what can happen
3. **Feedback** shows the results of actions
4. **A goal** gives purpose (win, lose, score, explore, etc.)

### Games vs. Other Software

| Software Type | Interactive? | Real-time? | Goal-oriented? | Example |
|---------------|--------------|------------|----------------|---------|
| **Game** | ✅ Yes | ✅ Yes | ✅ Yes | Pong, Minecraft |
| **Calculator** | ✅ Yes | ❌ No | ❌ No | Windows Calculator |
| **Video Player** | ⚠️ Limited | ✅ Yes | ❌ No | YouTube |
| **Simulation** | ✅ Yes | ✅ Yes | ⚠️ Maybe | Flight Simulator |

**Key difference**: Games continuously update and respond to player input in real-time.

---

## 🔄 The Game Loop: The Heart of Every Game

### What is a Game Loop?

The **game loop** is the core cycle that runs continuously while your game is running. It's what makes games "alive" and responsive.

### Basic Game Loop Structure

```
START GAME
↓
┌─────────────────────┐
│  1. Process Input   │ ← Read keyboard, mouse, controller
├─────────────────────┤
│  2. Update Game     │ ← Move objects, check collisions, update score
├─────────────────────┤
│  3. Render/Draw     │ ← Draw everything on screen
└─────────────────────┘
↓
Is game still running? → YES → Loop back to step 1
↓ NO
END GAME
```

### Real-World Analogy

Think of a **flip book animation**:
1. **Draw a frame** (Render)
2. **Flip to next page** (Update)
3. **Repeat** (Loop)

The faster you flip, the smoother the animation. Games typically run at 30-60+ flips (frames) per second!

### Example: Pong Game Loop

Let's trace one frame of Pong:

```
Frame 1:
1. INPUT:    Player 1 presses UP arrow
2. UPDATE:   Move paddle 1 up by 5 pixels
             Move ball based on its velocity
             Check if ball hit paddle
             Check if ball hit wall
             Update score if ball went past paddle
3. RENDER:   Clear screen
             Draw paddle 1 at new position
             Draw paddle 2
             Draw ball at new position
             Draw score
4. REPEAT:   Go to Frame 2
```

This happens **60 times per second**!

---

## 🧩 Core Components of a Game

### 1. Game State

**Game state** is all the data that describes the current situation.

**Examples**:
- Player position: (x=100, y=200)
- Player health: 75/100
- Score: 1250
- Level: 3
- Is game paused? No
- Enemies alive: 5

**Think of it as**: A snapshot of everything in your game at this exact moment.

### 2. Input

**Input** is how the player communicates with the game.

**Input devices**:
- Keyboard (keys pressed/released)
- Mouse (position, clicks)
- Controller (buttons, joysticks)
- Touch screen (taps, swipes)

**Input handling**:
```
If SPACE key is pressed:
    Make player jump

If LEFT mouse button clicked:
    Shoot weapon

If joystick moved right:
    Move character right
```

### 3. Game Logic (Update)

**Game logic** is the rules and calculations that change the game state.

**Examples**:
- Physics: Apply gravity to falling objects
- AI: Make enemies chase the player
- Collision: Detect when bullet hits enemy
- Scoring: Add 100 points when collecting coin
- Win/Lose: Check if player reached the goal

**This is where the "game" happens!**

### 4. Rendering (Drawing)

**Rendering** is displaying the current game state visually.

**Process**:
1. Clear the screen
2. Draw background
3. Draw game objects (player, enemies, items)
4. Draw UI (score, health bar, menus)
5. Display the frame

**Important**: Rendering doesn't change game state, it only shows it!

### 5. Time and Frames

**Frame**: One complete cycle of the game loop  
**Frame Rate (FPS)**: How many frames per second

**Common frame rates**:
- 30 FPS: Acceptable, slightly choppy
- 60 FPS: Smooth, standard for most games
- 120+ FPS: Very smooth, competitive gaming

**Frame time**: Time available for one frame
- 60 FPS = 16.67 milliseconds per frame
- 30 FPS = 33.33 milliseconds per frame

---

## 🎯 Game States (Not the same as Game State!)

Games often have different **modes** or **states**:

### Common Game States

```
┌──────────────┐
│  Main Menu   │
└──────┬───────┘
       ↓
┌──────────────┐
│   Playing    │ ←──┐
└──────┬───────┘    │
       ↓            │
┌──────────────┐    │
│    Paused    │ ───┘
└──────┬───────┘
       ↓
┌──────────────┐
│  Game Over   │
└──────┬───────┘
       ↓
┌──────────────┐
│  Main Menu   │
└──────────────┘
```

**Each state has different behavior**:
- **Main Menu**: Show buttons, wait for selection
- **Playing**: Run full game loop, process gameplay input
- **Paused**: Freeze game logic, show pause menu
- **Game Over**: Show final score, offer restart

---

## 💻 Simple Pseudocode Example

Let's write a simple number guessing game loop in pseudocode:

```
# Game State
secret_number = random number between 1 and 100
attempts = 0
game_running = true

# Game Loop
while game_running:
    # 1. INPUT
    player_guess = ask player for a number
    
    # 2. UPDATE (Game Logic)
    attempts = attempts + 1
    
    if player_guess == secret_number:
        print "You won in " + attempts + " attempts!"
        game_running = false
    else if player_guess < secret_number:
        print "Higher!"
    else:
        print "Lower!"
    
    # 3. RENDER
    # (In this text game, printing IS rendering)
    
# Game Over
print "Thanks for playing!"
```

**Notice**:
- Game state: `secret_number`, `attempts`, `game_running`
- Input: `player_guess`
- Update: Increment attempts, check win condition
- Render: Print messages
- Loop: Continues while `game_running` is true

---

## 🔍 Deep Dive: Why Separate Update and Render?

### Reason 1: Clarity

**Update** = "What happens"  
**Render** = "What it looks like"

Separating these makes code easier to understand and modify.

### Reason 2: Performance

You might update game logic at 60 FPS but render at 30 FPS to save performance, or vice versa.

### Reason 3: Testing

You can test game logic without graphics:
```
# Test: Does player take damage when hit?
player.health = 100
enemy.attack(player)
assert player.health == 90  # No graphics needed!
```

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Game Loop** | The continuous cycle of input → update → render |
| **Game State** | All data describing the current game situation |
| **Input** | Player actions (keyboard, mouse, controller) |
| **Update** | Applying game logic to change state |
| **Render** | Drawing the current state to the screen |
| **Frame** | One complete loop iteration |
| **FPS (Frames Per Second)** | How many frames run per second |
| **Game State (mode)** | Current mode (menu, playing, paused, game over) |
| **Logic** | The rules and calculations of the game |
| **Feedback** | Information shown to the player (visuals, sounds) |

---

## 🧪 Thought Exercises

Before moving on, think about these questions:

1. **Pong Ball Movement**  
   The ball moves across the screen. In which part of the game loop does the ball's position change? (Input, Update, or Render?)

   <details>
   <summary>Answer</summary>
   <b>Update</b> - The ball's position is part of game state and changes during the update phase based on its velocity.
   </details>

2. **Drawing the Score**  
   The score is displayed at the top of the screen. In which part of the game loop is it drawn?

   <details>
   <summary>Answer</summary>
   <b>Render</b> - Drawing/displaying anything happens during the render phase.
   </details>

3. **Detecting a Button Press**  
   The player presses the SPACE key to jump. In which part of the game loop is this detected?

   <details>
   <summary>Answer</summary>
   <b>Input</b> - Reading player actions happens during the input phase.
   </details>

4. **Frame Rate Impact**  
   If a game runs at 30 FPS instead of 60 FPS, what changes?

   <details>
   <summary>Answer</summary>
   The game loop runs half as often (30 times per second instead of 60). The game may feel less smooth, and there's more time available per frame for calculations.
   </details>

---

## 📝 Practical Exercise

### Exercise 1: Identify the Parts

For each of these game actions, identify if it belongs to **Input**, **Update**, or **Render**:

1. Player presses the RIGHT arrow key
2. Character's X position increases by 5
3. Character sprite is drawn at new position
4. Mouse click is detected
5. Bullet is created when player clicks
6. Bullet moves forward
7. Bullet image is drawn on screen
8. Collision between bullet and enemy is detected
9. Enemy health decreases
10. Explosion animation is displayed

<details>
<summary>Answers</summary>

1. **Input** - Detecting key press
2. **Update** - Changing game state (position)
3. **Render** - Drawing to screen
4. **Input** - Detecting mouse action
5. **Update** - Creating game object (game logic)
6. **Update** - Changing position (game logic)
7. **Render** - Drawing to screen
8. **Update** - Collision detection (game logic)
9. **Update** - Changing game state (health)
10. **Render** - Displaying visual effect

</details>

### Exercise 2: Design a Simple Loop

Write pseudocode for a simple "Click the Button" game:
- A button appears on screen
- Player clicks it
- Score increases
- Button moves to random position
- Repeat

Try writing it yourself before looking at the example!

<details>
<summary>Example Solution</summary>

```
# Game State
score = 0
button_x = random(0, screen_width)
button_y = random(0, screen_height)
game_running = true

# Game Loop
while game_running:
    # INPUT
    if mouse_clicked:
        click_x = mouse.x
        click_y = mouse.y
    
    # UPDATE
    if mouse_clicked and click is on button:
        score = score + 1
        button_x = random(0, screen_width)
        button_y = random(0, screen_height)
    
    # RENDER
    clear_screen()
    draw_button(button_x, button_y)
    draw_text("Score: " + score, 10, 10)
    
    # Check exit condition
    if player_pressed_ESC:
        game_running = false
```

</details>

---

## ✅ Self-Assessment

Before moving to the next lesson, make sure you can:

- [ ] Explain what a game loop is in your own words
- [ ] Name the three main parts of a game loop
- [ ] Explain the difference between game state and game states (modes)
- [ ] Identify whether a game action is input, update, or render
- [ ] Explain why games run in a continuous loop
- [ ] Describe what happens in one frame of a simple game
- [ ] Explain what FPS means

---

## 🚀 What's Next?

Now that you understand what a game is and how the game loop works, you're ready to:

1. **Learn basic programming concepts** (variables, functions, conditions)
2. **Write your first interactive program** (text-based)
3. **Build your first game** (Number Guessing Game)

In the next lesson, we'll cover programming fundamentals you'll need to implement a game loop!

---

## 💭 Reflection Questions

Think about or write down answers to these:

1. What surprised you most about how games work?
2. Can you think of a game you've played and imagine its game loop?
3. What part of game development interests you most: input, logic, or rendering?
4. What questions do you still have about game loops?

---

**Great job! You've taken the first step into game development! 🎮**
