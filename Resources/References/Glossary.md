# Game Development Glossary

Every term defined in this lab's lessons, in one place. Grouped by
topic — scan before asking "what does X mean again?"

---

## 🎮 Core Game Concepts

| Term | Definition |
|------|------------|
| **Game loop** | The continuous cycle: input → update → render |
| **Frame** | One complete iteration of the game loop |
| **FPS** | Frames per second; 60 is the standard target |
| **Delta** | Seconds elapsed since the last frame |
| **Game state** | All data describing the game right now (positions, score, HP) |
| **Game states (modes)** | Enum-like modes: menu, playing, paused, game over |
| **Tick** | One discrete step in a turn-based game |
| **Hitbox / hurtbox** | The shape that deals damage / the shape that receives it |
| **Game feel** | How responsive and satisfying actions are (feedback, juice) |
| **Difficulty curve** | How challenge scales over time |

## 💻 Programming

| Term | Definition |
|------|------------|
| **Variable** | A named box holding a value |
| **Constant** | A variable that never changes (`const`) |
| **Function** | A named, reusable block of code |
| **Parameter / argument** | Input a function accepts / the value you pass |
| **Return value** | What a function hands back |
| **`if` / `match`** | Branching: run code only under conditions |
| **Loop** | Repeating code (`for`, `while`) |
| **Array** | Ordered list of values |
| **Dictionary** | Key → value pairs |
| **Enum** | Named constants grouped together (`State.PLAYING`) |
| **Class / instance** | A blueprint / a concrete object built from it |
| **Callback** | A function handed to something else to call later |
| **Bug / regression** | Defect / a defect that returns after being fixed |

## 📐 Math & Physics

| Term | Definition |
|------|------------|
| **Coordinate** | A number locating a point on an axis |
| **Vector** | Direction + magnitude: `Vector2(x, y)` |
| **Magnitude** | A vector's length |
| **Normalized** | Scaled to length 1 — direction only |
| **Velocity** | Speed with direction (a vector) |
| **Acceleration** | Rate of change of velocity |
| **Lerp** | Linear interpolation between two values |
| **AABB** | Axis-aligned bounding box |
| **Tunneling** | Fast object skipping an obstacle between checks |
| **Swept collision** | Testing the whole motion path, not the endpoint |

## 🔧 Godot

| Term | Definition |
|------|------------|
| **Node** | One game object/component; everything is a node |
| **Scene** | A saved tree of nodes (`.tscn`) — level, enemy, menu |
| **Script** | Code attached to a node (`.gd`) |
| **Scene tree** | The live hierarchy of all nodes |
| **Signal** | A named event a node emits (`body_entered`, `timeout`) |
| **`_ready()`** | Called when the node enters the tree |
| **`_process(delta)`** | Called every rendered frame |
| **`_physics_process(delta)`** | Called at a fixed rate — put physics here |
| **Physics body** | `CharacterBody2D` / `RigidBody2D` / `StaticBody2D` |
| **`Area2D`** | Overlap detector that doesn't block movement |
| **CollisionShape** | Child node defining a body's shape |
| **Layer / mask** | What a body IS / what it collides WITH |
| **Autoload** | A globally-available singleton script |
| **`@onready`** | Assign when `_ready` runs (node refs exist by then) |
| **`res://`** | Path root = your project folder |
| **`extends SceneTree`** | Whole-game script (console/headless games) |

## 📖 Ren'Py

| Term | Definition |
|------|------------|
| **Visual novel** | A story game driven by text, images, and choices |
| **Label** | A named script section (`label start:`) |
| **`menu:`** | A player choice block |
| **`scene` / `show` / `hide`** | Background / sprite on / sprite off |
| **`$ code`** | An inline Python statement |
| **`default var`** | A variable Ren'Py saves & can roll back |
| **`jump` / `call`** | Go to a label / go and come back |
| **Sprite** | A character image |
| **Branching** | Story paths diverging based on choices |

---

*Each theory doc also has its own vocabulary table — this file is the
index of all of them. Add new terms as you learn them.*
