# Quick Reference Guide

## 📋 Game Development Roadmap

### Stage 0: Foundations (Current)
- [ ] Install Godot
- [ ] Understand game loops
- [ ] Learn basic programming
- [ ] Create first interactive program

### Stage 1: 1D Games
- [ ] Game 1: Number Guessing
- [ ] Game 2: 1D Catch
- [ ] Game 3: 1D Pong
- [ ] Game 4: 1D Endless Runner

### Stage 2: 2D Games
- [ ] Game 5: 2D Clicker
- [ ] Game 6: 2D Pong
- [ ] Game 7: Snake
- [ ] Game 8: Breakout
- [ ] Game 9: Top-Down Collect
- [ ] Game 10: 2D Platformer

### Stage 3: 2D Advanced
- [ ] Game 11: Space Shooter
- [ ] Game 12: Tower Defense

### Stage 4: 3D Games
- [ ] Game 13: Roll-a-Ball
- [ ] Game 14: Maze Explorer
- [ ] Game 15: Mini Racing
- [ ] Game 16: Mini Adventure

### Capstone
- [ ] Design your own game
- [ ] Implement and polish
- [ ] Complete!

### Bonus: Ren'Py Visual Novels
- [ ] Install Ren'Py
- [ ] VN 1: Branching Story
- [ ] VN 2: Character Expressions
- [ ] VN 3: Inventory Quest VN
- [ ] VN 4: Your Own Visual Novel

---

## 🎮 Godot Quick Reference

### Essential Shortcuts

| Action | Windows/Linux | macOS |
|--------|---------------|-------|
| Run Scene | F5 | Cmd+B |
| Run Current Scene | F6 | Cmd+R |
| Stop | F8 | Cmd+. |
| Save Scene | Ctrl+S | Cmd+S |
| Play | F5 | F5 |
| Pause | F7 | F7 |
| Search Help | F1 | F1 |
| Distraction Free | Ctrl+Shift+F11 | Cmd+Shift+F11 |

### Common Node Types

**2D Nodes**:
- `Node2D` - Basic 2D node with position, rotation, scale
- `Sprite2D` - Displays an image
- `AnimatedSprite2D` - Displays animated sprites
- `CharacterBody2D` - Physics body for characters
- `RigidBody2D` - Physics body with realistic physics
- `StaticBody2D` - Non-moving physics body
- `Area2D` - Detects overlaps
- `CollisionShape2D` - Defines collision area
- `Camera2D` - 2D camera
- `TileMap` - Grid-based level design

**3D Nodes**:
- `Node3D` - Basic 3D node
- `MeshInstance3D` - Displays 3D model
- `CharacterBody3D` - Physics body for characters
- `RigidBody3D` - Physics body with realistic physics
- `StaticBody3D` - Non-moving physics body
- `Area3D` - Detects overlaps
- `CollisionShape3D` - Defines collision volume
- `Camera3D` - 3D camera
- `DirectionalLight3D` - Sun-like light
- `OmniLight3D` - Point light

**UI Nodes**:
- `Control` - Base UI node
- `Label` - Text display
- `Button` - Clickable button
- `TextureRect` - Displays image in UI
- `Panel` - Background panel
- `VBoxContainer` - Vertical layout
- `HBoxContainer` - Horizontal layout
- `MarginContainer` - Adds margins

**Utility Nodes**:
- `Timer` - Countdown timer
- `AudioStreamPlayer` - Plays sounds
- `AnimationPlayer` - Plays animations
- `CanvasLayer` - Separate rendering layer

### Scene Structure Best Practices

```
Player (CharacterBody2D)
├── Sprite2D (visual)
├── CollisionShape2D (physics)
├── Camera2D (follows player)
└── AnimationPlayer (animations)
```

---

## 💻 GDScript Quick Reference

### Basic Syntax

```gdscript
# Variables
var player_name = "Hero"
var health = 100
var is_alive = true
var position = Vector2(0, 0)

# Constants
const MAX_HEALTH = 100
const SPEED = 200

# Functions
func take_damage(amount):
    health -= amount
    if health <= 0:
        die()

func die():
    is_alive = false
    print("Game Over")

# Built-in Functions
func _ready():
    # Called when node enters scene
    print("Game started!")

func _process(delta):
    # Called every frame
    # delta = time since last frame
    position.x += SPEED * delta

func _physics_process(delta):
    # Called every physics frame (fixed rate)
    # Use for physics calculations
    pass
```

### Common Patterns

**Movement**:
```gdscript
func _process(delta):
    var velocity = Vector2.ZERO
    
    if Input.is_action_pressed("ui_right"):
        velocity.x += 1
    if Input.is_action_pressed("ui_left"):
        velocity.x -= 1
    if Input.is_action_pressed("ui_down"):
        velocity.y += 1
    if Input.is_action_pressed("ui_up"):
        velocity.y -= 1
    
    velocity = velocity.normalized() * SPEED
    position += velocity * delta
```

**Collision Detection**:
```gdscript
func _on_Area2D_body_entered(body):
    if body.name == "Player":
        print("Player entered area!")
```

**Timer**:
```gdscript
func _ready():
    var timer = Timer.new()
    timer.wait_time = 2.0
    timer.one_shot = true
    timer.timeout.connect(_on_timer_timeout)
    add_child(timer)
    timer.start()

func _on_timer_timeout():
    print("2 seconds passed!")
```

### Data Types

```gdscript
# Numbers
var integer = 42
var floating = 3.14

# Strings
var text = "Hello"
var multiline = """
Multiple
lines
"""

# Booleans
var flag = true

# Arrays
var items = [1, 2, 3, 4]
items.append(5)
items[0] = 10

# Dictionaries
var player = {
    "name": "Hero",
    "health": 100,
    "level": 5
}
print(player["name"])

# Vectors
var pos2d = Vector2(10, 20)
var pos3d = Vector3(10, 20, 30)
```

---

## 🎯 Common Game Patterns

### Singleton (Autoload) for Global Data

**Create `global.gd`**:
```gdscript
extends Node

var score = 0
var player_name = "Player"

func reset_game():
    score = 0
```

**Add to Project Settings > Autoload**

**Use anywhere**:
```gdscript
Global.score += 10
```

### Scene Switching

```gdscript
func go_to_level_2():
    get_tree().change_scene_to_file("res://scenes/level_2.tscn")
```

### Spawning Objects

```gdscript
var EnemyScene = preload("res://scenes/enemy.tscn")

func spawn_enemy():
    var enemy = EnemyScene.instantiate()
    enemy.position = Vector2(100, 100)
    add_child(enemy)
```

### Simple State Machine

```gdscript
enum State { IDLE, RUNNING, JUMPING, FALLING }
var current_state = State.IDLE

func _process(delta):
    match current_state:
        State.IDLE:
            handle_idle()
        State.RUNNING:
            handle_running()
        State.JUMPING:
            handle_jumping()
        State.FALLING:
            handle_falling()
```

---

## 🐛 Debugging Tips

### Print Debugging
```gdscript
print("Health: ", health)
print("Position: ", position)
```

### Breakpoints
- Click left of line number to add breakpoint
- Run in debug mode (F5)
- Game pauses at breakpoint
- Inspect variables in debugger panel

### Common Errors

**"Invalid get index 'x' (on base: 'Nil')"**
- Trying to access property of null object
- Check if object exists before accessing

**"Identifier not declared in current scope"**
- Variable or function name misspelled
- Variable not declared with `var`

**"Parser Error: Expected ')'"**
- Missing closing parenthesis
- Check all opening `(` have closing `)`

---

## 📚 Learning Resources

### Official Godot Docs
- **Getting Started**: https://docs.godotengine.org/en/stable/getting_started/introduction/index.html
- **GDScript Basics**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- **Your First 2D Game**: https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html

### Community
- **Godot Q&A**: https://ask.godotengine.org/
- **Reddit**: r/godot
- **Discord**: https://discord.gg/godotengine

### YouTube Channels
- **Brackeys** (Unity, but concepts apply)
- **GDQuest** (Godot-specific)
- **HeartBeast** (Godot tutorials)

---

## ✅ Quality Checklist

Before considering a game complete:

- [ ] Game has clear objective
- [ ] Player input works correctly
- [ ] Win/lose condition exists
- [ ] Restart functionality works
- [ ] No critical bugs
- [ ] Code is readable
- [ ] Files are organized
- [ ] README explains how to run
- [ ] At least one improvement beyond prototype

---

## 🎓 Concept Progression

**Stage 0-1**: Logic & State
- Variables, functions, conditions
- Game loop understanding
- Simple state management

**Stage 2**: Graphics & Input
- 2D coordinates
- Sprites and rendering
- Mouse/keyboard input
- Basic collision

**Stage 3**: Physics & Systems
- Vectors and velocity
- Gravity and forces
- Complex collision
- Multiple object management

**Stage 4**: 3D Space
- 3D coordinates
- Camera perspective
- 3D physics
- Spatial reasoning

### Bonus: Ren'Py Narrative Track
- Visual novel structure
- Branching choices
- Character systems
- Save/load for text games

---

## 📖 Ren'Py Quick Reference

### Basic Script Structure

```renpy
# Define characters
define e = Character("Eileen", color="#c8ffc8")
define m = Character("Me", color="#c8c8ff")

# Start of game
label start:
    scene bg room
    show eileen happy
    
    e "Hello! This is a visual novel."
    
    menu:
        "What do you do?"
        
        "Say hello."
            e "Nice to meet you!"
            $ friendship += 1
        
        "Stay silent."
            e "You don't talk much, do you?"
    
    return
```

### Common Ren'Py Commands

| Command | Description | Example |
|---------|-------------|---------|
| `label name:` | Named section | `label start:` |
| `scene image` | Show background | `scene bg room` |
| `show image` | Show character/sprite | `show eileen happy` |
| `hide image` | Hide character/sprite | `hide eileen` |
| `character "text"` | Dialogue | `e "Hello!"` |
| `"narration"` | Narration text | `"It was dark."` |
| `menu:` | Player choices | See example above |
| `$ var = value` | Python expression | `$ score += 10` |
| `if condition:` | Conditional | `if friendship > 5:` |
| `jump label` | Go to label | `jump chapter2` |
| `call label` | Go and return | `call help_menu` |
| `return` | End of section | `return` |
| `with dissolve` | Fade transition | `scene bg room with dissolve` |

### Character Definition

```renpy
define e = Character("Eileen", color="#c8ffc8")
define m = Character("You", color="#c8c8ff")
define narrator = Character(None)
```

### Variables in Ren'Py

```renpy
# In init block or during game
$ score = 0
$ player_name = "Hero"
$ has_key = false

# Using variables
"You have [score] points."
e "Hello, [player_name]!"
```

### Branching Choices

```renpy
menu:
    "Where do you want to go?"
    "Forest":
        jump forest_scene
    "Castle":
        jump castle_scene
    "Stay here." (if has_map):
        "You decide to wait."
```

### Conditional Story

```renpy
if has_key:
    "You unlock the door."
    jump inside
else:
    "The door is locked."
```

### Image Paths

```
project/
├── game/
│   ├── script.rpy
│   ├── images/
│   │   ├── bg room.png
│   │   ├── eileen happy.png
│   │   └── eileen sad.png
```

Use in script:
```renpy
scene bg room
show eileen happy
show eileen sad with dissolve
```

### Common Ren'Py File Structure

```
MyVN/
├── game/
│   ├── script.rpy          # Main story
│   ├── options.rpy         # Game settings
│   ├── screens.rpy         # UI screens
│   ├── gui.rpy             # GUI settings
│   ├── images/             # Backgrounds and sprites
│   ├── audio/              # Music and sounds
│   └── saves/              # Save files
├── MyVN.exe                # Launcher
└── project.json
```

### Ren'Py Resources

- **Official Tutorial**: https://www.renpy.org/doc/html/tutorial.html
- **Ren'Py Cookbook**: https://lemmasoft.renai.us/forums/viewforum.php?f=51
- **Official Site**: https://www.renpy.org/

---

**Keep this reference handy as you build your games! 🚀**
