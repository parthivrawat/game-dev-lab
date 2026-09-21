# Lesson 2: Functions

## 🎯 Learning Objectives

By the end of this lesson you will be able to:

- Define functions with parameters, defaults, and return values
- Use type hints on parameters and return types
- Distinguish local variables from member variables
- Recognize the special callbacks Godot calls for you (`_init`, `_ready`,
  `_process`, `_physics_process`)
- Structure a program as small, single-purpose functions

---

## 🧱 Defining Functions

```gdscript
func greet():
    print("Hello!")

func add(a, b):
    return a + b

# Typed version — preferred style for this lab:
func add_typed(a: int, b: int) -> int:
    return a + b

func heal(amount: int) -> void:      # void = returns nothing
    health += amount
```

### Default Parameters

```gdscript
func take_damage(amount: int = 10) -> void:
    health -= amount

take_damage()      # health -10
take_damage(30)    # health -30
```

Parameters with defaults must come **after** parameters without them — same
rule as Python.

### Return Values and Early Return

```gdscript
func get_rank(score: int) -> String:
    if score >= 1000:
        return "S"
    if score >= 500:
        return "A"
    return "B"
```

No `return` statement needed at the end of a `void` function — but you can use
bare `return` to exit early.

---

## 🏠 Scope: Members vs. Locals

```gdscript
extends Node

var score := 0          # member variable — lives on the object, shared by all
                        # functions in this script

func add_points(points: int) -> void:
    var old_score = score       # local — exists only during this call
    score += points             # member — persists after the call
    print("Was %d, now %d" % [old_score, score])
```

**Rule of thumb**:
- Data that describes the *game state* → member variable
- Data used inside one calculation → local variable

You'll see this pattern everywhere in Godot: `_process` reads input, updates
member variables, and rendering reads those members. The member variables
*are* the game state from Lesson `01-What-Is-A-Game`.

---

## 🔔 Functions Godot Calls For You

Godot scripts don't start at "line 1" — the engine calls specific **callback
functions** at specific moments. You write the function, Godot decides *when*.

```gdscript
func _init() -> void:
    # Constructor — runs when the object is created.
    # For -s/--script SceneTree scripts, this is effectively "main()".
    pass

func _ready() -> void:
    # Runs once when the node enters the scene tree.
    # Good place for setup that needs the scene to exist.
    pass

func _process(delta: float) -> void:
    # Runs EVERY FRAME. delta = seconds since last frame
    # (~0.0167 at 60 FPS). This is the "Update" phase of the game loop.
    pass

func _physics_process(delta: float) -> void:
    # Runs at a fixed rate (default 60 Hz) — for physics and movement.
    pass

func _input(event: InputEvent) -> void:
    # Runs once per input event (key press, mouse click...).
    pass
```

### `delta` — the most important parameter in game dev

```gdscript
func _process(delta: float) -> void:
    position.x += SPEED * delta    # move SPEED pixels per SECOND,
                                    # regardless of frame rate
```

Why multiply by `delta`? If your game runs at 30 FPS on one machine and 144 FPS
on another, `position.x += 5` per frame moves the object ~5× faster on the
faster machine. `SPEED * delta` makes movement **frame-rate independent** —
a habit worth building from day one, even though Stage 0/1 games barely need it.

---

## 🧩 Functions as Organization

Look at the TextAdventure deliverable — its whole structure is functions:

```gdscript
func _init() -> void:
    _print_intro()
    _render()
    while game_running:
        var command := _read_input()     # INPUT
        _update(command)                 # UPDATE
        _render()                        # RENDER
    _print_outro()
    quit()
```

The game loop from `01-What-Is-A-Game.md` is *literally* three function calls.
Each function does one thing:

- `_read_input()` — gets and cleans a command
- `_update(command)` — all game logic
- `_render()` — all drawing

**When a function grows past ~20-30 lines or does two things, split it.**

### Naming conventions in this lab

- `snake_case` for everything (functions, variables)
- Leading `_` for Godot callbacks and private helpers: `_update`, `_render`
- Verb-first names: `take_damage`, `spawn_enemy`, `get_rank`

---

## 🧪 Thought Exercises

1. **What prints?**

   ```gdscript
   var count := 0

   func bump() -> void:
       var count := 5
       count += 1

   func _ready() -> void:
       bump()
       bump()
       print(count)
   ```

   <details><summary>Answer</summary>
   <code>0</code> — the local <code>count</code> inside <code>bump()</code>
   *shadows* the member variable. The member is never touched.
   To modify the member, drop the <code>var</code>.
   </details>

2. **Which callback?** — you want an enemy to move toward the player every
   frame. Does the movement code go in `_ready`, `_process`, or `_init`?

   <details><summary>Answer</summary>
   <code>_process</code> (or <code>_physics_process</code> for physics-driven
   movement). <code>_ready</code> runs once, <code>_init</code> runs at
   construction — neither repeats.
   </details>

3. **Design check** — a function named `update_player` reads input, moves the
   player, checks collisions, plays sounds, and updates the HUD. What's wrong?

   <details><summary>Answer</summary>
   It does five things. Split into <code>_read_input</code>,
   <code>_move_player</code>, <code>_check_collisions</code>, etc. Small
   functions are easier to test, debug, and reuse.
   </details>

---

## ✅ Self-Assessment

- [ ] I can write typed functions with defaults and return values
- [ ] I know the difference between member and local variables
- [ ] I can name the callbacks Godot provides and when each runs
- [ ] I understand what `delta` is and why it matters
- [ ] I know how the game loop maps to function calls

---

## 🚀 What's Next?

We can compute and organize code — now we need the player to *talk* to the
game, a way to represent position, and a way to model menu/playing/game-over.

→ `Lesson03-Input-Coordinates-States.md`
