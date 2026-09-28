# Lesson: Signals and Events

## 🎯 Learning Objectives

By the end of this lesson, you will understand:
- What an event/callback is and why games are built on them
- How Godot's signal system works: declare, emit, connect
- The built-in signals you'll use constantly (`timeout`, `body_entered`, `pressed`)
- How to connect signals in code vs. in the editor
- When a signal is right — and when a plain function call is simpler

---

## 📢 The Problem: "Tell Me When It Happens"

Your Stage 1 games run a loop you control: read input → update → render.
But real games are full of things that happen **at unpredictable times**:

- A Timer finishes counting down
- The player walks into a coin
- A button gets clicked
- A physics body hits a wall

You *could* check every possibility every frame ("is the timer done yet?
is it done now? now?"), but that's wasteful and messy. Instead, Godot
lets objects **announce** that something happened — and anyone
interested can **listen**.

```
Coin:  "body_entered!"  ──►  Player: "I'll collect it."
Timer: "timeout!"       ──►  Spawner: "I'll make an enemy."
Button:"pressed!"       ──►  Game:    "I'll start."
```

The announcer doesn't know or care who's listening. The listeners don't
care who announced. That's **decoupling** — and it's the whole point.

---

## 🔌 Signals in Godot

A **signal** is a named event a node can emit. Connecting a signal to a
function means: *when this happens, call that*.

### Built-in signals (you'll use these constantly)

| Signal | Emitted by | When |
|--------|-----------|------|
| `timeout` | `Timer` | Countdown reaches zero |
| `body_entered(body)` | `Area2D` | A physics body enters the area |
| `body_exited(body)` | `Area2D` | A physics body leaves |
| `pressed` | `Button` | Button clicked |
| `tree_exiting` | any `Node` | Node is being removed |

### Connecting in code

```gdscript
func _ready() -> void:
    # "When the timer finishes, call _on_timer_timeout"
    timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
    print("Time's up!")
```

The naming convention is `_on_<who>_<what>` → `_on_timer_timeout`,
`_on_coin_body_entered`, `_on_start_button_pressed`. Follow it —
Godot's editor auto-generates these names.

### Signals with arguments

Some signals carry data. `body_entered` tells you **who** entered:

```gdscript
func _ready() -> void:
    pickup_area.body_entered.connect(_on_pickup_body_entered)

func _on_pickup_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.collect_coin()
        queue_free()
```

The connected function must accept the signal's arguments — check the
signal's signature in the docs (F1 in the editor).

### Connecting in the editor

1. Select the node (e.g., the Timer)
2. Open the **Node** dock (next to Inspector)
3. Double-click the signal
4. Pick the node that should receive it
5. Godot writes the `_on_...` function for you

Editor connections and `connect()` calls do exactly the same thing —
use whichever is clearer. Code connections work on nodes created at
runtime (which editor connections can't see).

---

## 📣 Custom Signals

You can declare your own events on any script:

```gdscript
extends Node2D

signal health_changed(new_health: int)
signal died

var health := 100:
    set(value):
        health = value
        health_changed.emit(health)
        if health <= 0:
            died.emit()
```

Now a health bar, a sound effect, and a game-over screen can all listen
to the player independently:

```gdscript
player.health_changed.connect(health_bar.set_value)
player.died.connect(_on_player_died)
```

The player script never mentions health bars or game-over screens — it
just reports facts. **UI listens; the game object stays ignorant.**
That's clean architecture in one pattern.

### A powerful trick: connect as a variable setter

```gdscript
player.health_changed.connect(func(v): bar.value = v)
```

Inline lambda connections keep tiny glue code out of your method list —
use them when the handler is one line.

---

## ⚖️ Signal vs. Direct Call

| Use a signal when... | Use a function call when... |
|----------------------|------------------------------|
| The sender shouldn't know the receiver (coin → player) | You need an immediate return value |
| Multiple things react to one event | The relationship is fixed and obvious |
| The receiver might not exist yet/anymore | You're inside one object's own logic |

**Rule of thumb**: "something happened" → signal. "do this now" → call.

Anti-pattern to avoid: connecting everything to everything. Signals make
*events* loose — your *structure* should still be deliberate. If you
can't trace who emits a signal and who hears it, you've built spaghetti
with extra steps.

---

## 🔍 Real Example: Spawn Timer

```gdscript
extends Node2D

var spawn_timer: Timer

func _ready() -> void:
    spawn_timer = Timer.new()
    spawn_timer.wait_time = 2.0
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(_spawn_enemy)
    add_child(spawn_timer)

func _spawn_enemy() -> void:
    var enemy := EnemyScene.instantiate()
    enemy.position = _random_spawn_point()
    add_child(enemy)
```

No polling, no `if time_left <= 0` checks in `_process` — the Timer
announces, the spawner reacts. This is the same pattern as the spawn
timers in Game 4 (Endless Runner), moved into the engine.

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Signal** | A named event a node can emit |
| **Emit** | Fire a signal: `my_signal.emit()` |
| **Connect** | Subscribe a function to a signal |
| **Callback** | The function called when the signal fires |
| **Decoupling** | Sender and receiver not knowing about each other |
| **Lambda** | An inline anonymous function |
| **`body_entered`** | Area2D signal: something overlapped me |
| **`timeout`** | Timer signal: countdown finished |

---

## 🧪 Thought Exercises

1. **Who knows whom?** A coin calls `player.collect_coin()` directly vs.
   emitting `body_entered` that the player handles. Which keeps the coin
   simpler? Which keeps the *player* simpler?

   <details>
   <summary>Answer</summary>
   Direct call: coin must know the player's API. Signal version (as
   written in the pickup example): the coin knows its signal, and whoever
   connects decides what happens. Neither is wrong — the signal version
   scales better when ten systems want to react to "coin collected".
   </details>

2. **Missing function**: You connect `timer.timeout` to
   `_on_timer_done`, but the function is named `_on_timer_timeout`.
   What happens?

   <details>
   <summary>Answer</summary>
   The connect fails at runtime with an error (in Godot 4, connecting to
   a nonexistent Callable errors immediately — check the Output panel).
   </details>

3. **Design check**: Your enemy script directly calls
   `get_parent().get_node("UI/HealthBar").hide()`. Why is this fragile,
   and what's the signal-based fix?

   <details>
   <summary>Answer</summary>
   It hard-codes the scene tree layout — rename or move HealthBar and the
   enemy breaks. Better: emit <code>died</code> and let whoever owns the
   UI connect it.
   </details>

---

## ✅ Self-Check

- [ ] Explain what a signal is in one sentence
- [ ] Connect a Timer's `timeout` to a function in code
- [ ] Explain why signals decouple sender from receiver
- [ ] Name three built-in signals and when they fire
- [ ] Declare and emit a custom signal with an argument
- [ ] Decide signal vs. direct call for a given situation
- [ ] Know where editor connections are made (Node dock)

---

## 🚀 What's Next?

- **Stage 2 games** (Clicker onward) run inside the real scene tree —
  buttons, timers, and areas all talk via signals
- **Debugging** (`06-Debugging-and-Testing.md`): what to do when a signal
  never fires or fires twice

---

**Signals are how independent objects stay independent while still cooperating. 📡**
