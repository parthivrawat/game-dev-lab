# Stage 0: Exercises

Work through these after reading the three lessons. Every exercise has a
collapsible solution — **try before you peek**. Struggling with a problem for
a few minutes is where the learning happens.

You can test your answers in the Godot script editor, or by running
`godot --headless --script your_file.gd` on a script that `extends SceneTree`.

---

## Part A: Programming Basics (Lesson 1)

### A1. Predict the output

```gdscript
var a := 7
var b := 2
print(a / b)
print(a % b)
print(a / b + a % b)
```

<details><summary>Solution</summary>

```
3
1
4
```

`/` on two ints does **integer division** (truncates), like C++ — *not* like
Python 3. `%` is integer remainder. So `7 / 2 = 3`, `7 % 2 = 1`,
`3 + 1 = 4`. For real division you'd need `a / 2.0` or `float(a) / b`.

</details>

### A2. Fix the bug

This code is supposed to give the player a copy of the starter inventory that
they can modify without changing the original. It doesn't work — why?

```gdscript
var starter_items = ["torch", "rope"]
var player_items = starter_items
player_items.append("sword")
print(starter_items.size())    # expected 2, prints 3
```

<details><summary>Solution</summary>

Arrays are reference types — `player_items` and `starter_items` point to the
same array. Fix:

```gdscript
var player_items = starter_items.duplicate()
```

</details>

### A3. Write it

Write a `match` statement that converts a number grade (0–100) to a letter:
90+ → "A", 80+ → "B", 70+ → "C", below → "F". (Hint: match on a boolean
expression, or use `if`/`elif` — both are fine.)

<details><summary>Solution</summary>

```gdscript
func letter_grade(score: int) -> String:
    if score >= 90:
        return "A"
    elif score >= 80:
        return "B"
    elif score >= 70:
        return "C"
    return "F"
```

A `match` version needs pattern ranges, which GDScript expresses via
`match` on an int won't do ranges directly — `if`/`elif` is the idiomatic
choice here. (If you wrote `match`, you probably discovered this!)

</details>

---

## Part B: Functions (Lesson 2)

### B1. Spot the shadowing bug

```gdscript
var health := 100

func take_damage(amount: int) -> void:
    var health := health - amount
    print("Health is now ", health)

func _ready() -> void:
    take_damage(30)
    print("Member health: ", health)
```

What prints, and why is it wrong?

<details><summary>Solution</summary>

```
Health is now 70
Member health: 100
```

`var health := ...` inside the function creates a **local** variable that
shadows the member. The member never changes. Fix:

```gdscript
func take_damage(amount: int) -> void:
    health -= amount
```

</details>

### B2. Write it

Write a function `clamp_health` that takes a raw health value and returns it
clamped to 0–`MAX_HEALTH`. Then refactor `take_damage`/`heal` to use it.

<details><summary>Solution</summary>

```gdscript
const MAX_HEALTH := 100
var health := MAX_HEALTH

func clamp_health(raw: int) -> int:
    return clampi(raw, 0, MAX_HEALTH)

func take_damage(amount: int) -> void:
    health = clamp_health(health - amount)

func heal(amount: int) -> void:
    health = clamp_health(health + amount)
```

</details>

### B3. Frame-rate reasoning

A ship moves `position.x += 300 * delta` per frame. Machine A runs at 30 FPS,
machine B at 120 FPS. After one real second, how far has the ship moved on
each machine?

<details><summary>Solution</summary>

The same distance — **300 pixels** — on both. `delta` is seconds-per-frame:
at 30 FPS it's ~0.0333 (30 frames × 0.0333 × 300 = 300), at 120 FPS it's
~0.0083 (120 × 0.0083 × 300 = 300). That's the whole point of `delta`.

</details>

---

## Part C: Input, Coordinates, States (Lesson 3)

### C1. Distance and bounds

Corridor cells are 0–9. Player at 3, ghost at 8.
- a) What's the distance?
- b) Player moves `-4`. Where do they end up if moves outside bounds are
  **rejected**? What if they're **clamped**?

<details><summary>Solution</summary>

- a) `abs(8 - 3) = 5`
- b) Rejected: stays at 3 (3 − 4 = −1 is out of bounds). Clamped:
  `clampi(-1, 0, 9) = 0`.

</details>

### C2. Design a state machine

You're building Pong. List the states and the transitions. Then write the
`enum` and a `_process` skeleton.

<details><summary>Solution</summary>

States: `SERVING` (ball held, waiting for launch), `PLAYING`, `SCORED`
(brief pause after a point), `GAME_OVER`.

```gdscript
enum State { SERVING, PLAYING, SCORED, GAME_OVER }
var state := State.SERVING

func _process(delta: float) -> void:
    match state:
        State.SERVING:
            _update_serving()
        State.PLAYING:
            _update_playing(delta)
        State.SCORED:
            _update_scored()
        State.GAME_OVER:
            _update_game_over()
```

Transitions: SERVING→PLAYING (launch input), PLAYING→SCORED (ball passes a
paddle), SCORED→SERVING or GAME_OVER (timer / score limit reached).

</details>

### C3. Command parser

Write `_parse_command(input: String) -> String` that maps user text to
canonical commands: `"l"`, `"left"`, `"go left"` → `"left"`; same for
right/attack/quit. Return `"unknown"` otherwise.

<details><summary>Solution</summary>

```gdscript
func _parse_command(input: String) -> String:
    match input.strip_edges().to_lower():
        "l", "left", "go left":
            return "left"
        "r", "right", "go right":
            return "right"
        "a", "attack", "fight":
            return "attack"
        "q", "quit", "exit":
            return "quit"
        _:
            return "unknown"
```

</details>

---

## Part D: Study the Deliverable's Improvements (hands-on)

`TextAdventure/main.gd` is the *improved* edition — everything below is
already implemented. Don't just read the answers: find each feature in
the code, then run `run_tests.bat` to watch the automated checks prove
it works. Reimplementing one on a copy of the file is excellent practice.

- **D1 (potions)** — `p` cells heal 10 HP when picked up.
  → `_resolve_cell`, `_free_cells`, `_generate_map`, `_print_hud`
- **D2 (map command)** — `map` reprints the cell legend, free of charge.
  → `_update`
- **D3 (chasing monsters)** — every action tick, each goblin steps one
  cell toward you and claws when adjacent.
  → `_chase_monsters`, `_world_tick`. *Does the reachable-sword rule
  still guarantee completable maps?* — it guarantees the sword is
  reachable **at spawn**; chasers can intercept you on the way, so grab
  it early.
- **D4 (enum state machine)** — `enum State { PLAYING, WON, LOST, QUIT }`
  replaced the `won`/`game_running` flags.
  → `_update`, `_world_tick`, `_print_round_result`
- **D5 (depth progression)** — escaping descends to a longer corridor
  with extra hunters; dying or fleeing resets to depth 1.
  → `depth`, `_generate_map`, `_print_round_result`

**Fresh modifications** live in `TextAdventure/README.md` → *New
Modification Ideas* (guard goblins, torch light, goblin HP, fleeing
potions, a high-score file) — those are the open exercises now.

After building one yourself, update `PROGRESS.md` — that's genuine game
logic you wrote. Then it's on to **Stage 1, Game 1: Number Guessing**.
