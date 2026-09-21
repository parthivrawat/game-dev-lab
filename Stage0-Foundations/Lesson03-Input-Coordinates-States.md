# Lesson 3: Input, 1D Coordinates, and Game States

## 🎯 Learning Objectives

By the end of this lesson you will be able to:

- Read text input with `OS.read_string_from_stdin()`
- Preview Godot's real-time input system (`Input`, Input Map, `_input`)
- Model a 1D world on a number line: position, direction, distance, bounds
- Represent game modes with an enum + `match` state machine

This lesson has three parts that combine into the Stage 0 deliverable: a
turn-based game needs **input**, a **world** (even a 1D one), and **states**.

---

## ⌨️ Part 1: Input Handling

### Text input (used by the deliverable)

For console-style programs, Godot exposes stdin:

```gdscript
func _read_input() -> String:
    printraw("> ")                              # print without newline
    return OS.read_string_from_stdin().strip_edges().to_lower()
```

- `OS.read_string_from_stdin()` **blocks** until the user types a line and
  presses Enter — perfect for turn-based games.
- `.strip_edges().to_lower()` normalizes input so `"LEFT"` and `" left "` work.
- ⚠️ **Stdin only works from a real terminal.** Run the deliverable with
  `godot --headless --script main.gd`, not from inside the editor.

### Real-time input (preview — Stage 1+)

Real games don't wait for Enter. Godot polls input state every frame:

```gdscript
func _process(delta: float) -> void:
    if Input.is_action_pressed("ui_right"):
        position.x += SPEED * delta
    if Input.is_physical_key_pressed(KEY_SPACE):
        jump()
        # Note: prefer is_physical_key_pressed (physical position on the
        # keyboard) over is_key_pressed (layout-dependent) in games.
```

Or reacts to discrete events:

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        confirm()
```

You'll define custom actions (`"jump"`, `"shoot"`) in
**Project → Project Settings → Input Map** starting in Stage 2. For now,
just know the two styles exist: **polling** (check every frame) vs.
**events** (react when something happens).

---

## 📏 Part 2: The 1D Coordinate System

Before 2D and 3D, we shrink the world to a **number line**. Every 1D game in
Stage 1 is built on these four ideas:

```
        direction -1                direction +1
             ←─────────────────────────────────→
    ─────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────
         0    1    2    3    4    5    6    7    8    9
         ↑                   ↑                        ↑
       player              sword                     exit
```

### Position

A single number. `var player_pos := 0` — the player is at index 0.

### Movement and direction

```gdscript
player_pos += 1        # move right
player_pos -= 1        # move left

# Or with a direction variable:
var direction := -1    # -1 = left, +1 = right
player_pos += direction
```

### Distance

```gdscript
var distance = abs(monster_pos - player_pos)
if distance <= 1:
    print("The monster is right next to you!")
```

`abs()` turns "difference" into "distance" — direction-agnostic.

### Boundaries — the world has edges

```gdscript
var target := player_pos + direction
if target < 0 or target >= CORRIDOR_SIZE:
    print("A wall blocks your way.")
else:
    player_pos = target
```

Or clamp instead of rejecting:

```gdscript
player_pos = clampi(player_pos + direction, 0, CORRIDOR_SIZE - 1)
```

That's it. **Everything in Stage 1 — catching, pong, endless runner — is these
four operations in different costumes.**

---

## 🚦 Part 3: Game States

From `01-What-Is-A-Game.md`: a game has *modes* — menu, playing, paused,
game over — each with different rules for input and update.

### The pattern: enum + match

```gdscript
enum State { MENU, PLAYING, PAUSED, GAME_OVER }
var state := State.MENU

func _process(delta: float) -> void:
    match state:
        State.MENU:
            _update_menu()
        State.PLAYING:
            _update_playing(delta)
        State.PAUSED:
            pass                            # frozen — no update
        State.GAME_OVER:
            _update_game_over()
```

### Transitions are explicit

```gdscript
func _on_player_died() -> void:
    state = State.GAME_OVER
    show_game_over_screen()
```

A state machine makes "what happens when" a *data question* instead of a pile
of `if` flags. Compare:

```gdscript
# ❌ Flag soup — bugs hide here
if playing and not paused and not dead and not in_menu:
    update_game()

# ✅ One variable, one source of truth
if state == State.PLAYING:
    update_game()
```

### TextAdventure's simpler version

The deliverable uses two booleans instead of a full enum:

```gdscript
var game_running := true
var won := false
```

That's fine for two states — but notice how quickly it would get ugly with a
third (a pause? a second phase?). Stage 1's games graduate to the enum version.

---

## 🧪 Thought Exercises

1. **Distance** — player at 2, monster at 7. What's `abs(monster_pos - player_pos)`?
   What about `abs(player_pos - monster_pos)`?

   <details><summary>Answer</summary>
   Both are <code>5</code> — distance is symmetric because <code>abs</code>
   removes direction.
   </details>

2. **Boundary bug** — corridor size is 10 (valid cells 0–9). This check passes
   but crashes later. Why?

   ```gdscript
   if target <= CORRIDOR_SIZE:
       player_pos = target
   ```

   <details><summary>Answer</summary>
   <code>target == 10</code> slips through (<code>10 <= 10</code>) but cell 10
   doesn't exist — valid indices are 0–9. Must be
   <code>target < CORRIDOR_SIZE</code> (plus a lower-bound check).
   </details>

3. **State design** — you add a "settings" screen reachable from the menu and
   from pause. Sketch the enum and transitions.

   <details><summary>Answer</summary>
   <code>enum State { MENU, SETTINGS, PLAYING, PAUSED, GAME_OVER }</code> —
   transitions: MENU→SETTINGS, PAUSED→SETTINGS, SETTINGS→(back where you came
   from — you'll want to remember the previous state, or use a stack).
   This is why real games sometimes use a *stack* of states instead of one
   variable!
   </details>

---

## ✅ Self-Assessment

- [ ] I can read a line of text input and normalize it
- [ ] I know the difference between polled input and input events
- [ ] I can represent 1D position, direction, distance, and bounds
- [ ] I can write an enum + `match` state machine
- [ ] I understand why one state variable beats many flags

---

## 🏆 You're Ready for the Deliverable

Open `TextAdventure/README.md`, run the game, and find all three lessons
living inside ~150 lines of code. Then try the exercises in `Exercises.md`.
