# Lesson: Coordinates and Vectors

## 🎯 Learning Objectives

By the end of this lesson, you will understand:
- How game worlds are measured: 1D number lines, 2D grids, 3D space
- Why screen coordinates are "upside down" (Y grows downward)
- What a vector is and how it stores position *and* direction
- The core vector operations: add, subtract, length, normalize
- What `delta` is and why every movement uses `velocity * delta`

---

## 📏 One Dimension: The Number Line

You already know this world — every Stage 1 game lives on it.

```
0    1    2    3    4    5    6    7
[ ][ ][ ][P][ ][ ][o][ ][ ]
         ↑        ↑
      paddle    ball
```

- A **position** is a single number: `ball_pos = 6`
- A **direction** is a sign: `-1` (left) or `+1` (right)
- A **distance** is a subtraction: `abs(ball_pos - paddle_pos)`
- **Bounds** are two numbers: `0` and `track_length - 1`

Everything in 2D and 3D is this same math with more components.

---

## 🗺️ Two Dimensions: The Grid

2D position needs **two** numbers: `(x, y)`.

### The Big Surprise: Y Points DOWN

In math class, Y grows upward. On screens, **Y grows downward**:

```
(0,0) ──────── +x ────────►
  │
  │
 +y    (100, 50) is 100 right, 50 DOWN
  │
  ▼
```

**Why?** Screens scan top-to-bottom. The first pixel drawn is top-left.
Every 2D game engine (Godot included) follows this convention.

**Consequence**: in Godot 2D, *up* is **negative** Y. Jumping subtracts
from `position.y`. This trips up everyone once — now it's out of the way.

### Example

```gdscript
var player_pos := Vector2(100, 50)   # 100 right, 50 down from top-left
var enemy_pos := Vector2(300, 200)
```

---

## 📦 Three Dimensions: Depth

3D adds a **z** axis. Godot uses a **right-handed, Y-up** system:

```
        +y (up)
         │
         │
         └─────── +x (right)
        /
       /
      +z (toward viewer)
```

- `+y` is up (opposite of 2D!)
- `-z` points "into" the screen (the default forward direction)
- A position is `Vector3(x, y, z)`

Stage 4 covers this in depth — for now just know the pattern: each
dimension adds one more number, and the math stays the same.

---

## ➡️ What is a Vector?

A **vector** is an arrow: a direction and a length, stored as numbers.

```
Vector2(3, 1) means "3 right, 1 down":

(0,0)
  • ─ ─ ─ •
          ╱
         ╱  ← the vector (3, 1)
        •
```

### Two Ways to Use the Same Type

`Vector2` serves two roles — keep them mentally separate:

| Role | Meaning | Example |
|------|---------|---------|
| **Position** | A point in space | `player_pos = Vector2(100, 50)` |
| **Velocity/Offset** | A direction × speed | `velocity = Vector2(200, 0)` |

The *vector from A to B* is `B - A` — subtraction turns two points into
an arrow:

```gdscript
var to_enemy := enemy_pos - player_pos   # arrow: player → enemy
```

---

## 🧮 The Four Vector Operations You Actually Use

### 1. Add — combine movements

```gdscript
position += velocity * delta   # THE movement line. Memorize it.
```

### 2. Subtract — get the arrow between two things

```gdscript
var offset := target_pos - position      # "which way is the target?"
```

### 3. Length / Distance — "how far?"

```gdscript
var d := position.distance_to(target_pos)   # absolute distance
var len := offset.length()                  # same thing for an arrow
```

### 4. Normalized — "which way?" (direction without speed)

```gdscript
var dir := offset.normalized()   # length-1 arrow, pure direction
position += dir * SPEED * delta  # move at exactly SPEED toward target
```

**Why normalize?** `Vector2(1,1).length()` is ≈1.41, not 1 — diagonal
movement would be 41% faster if you didn't normalize. This is the famous
"diagonal speed bug" every beginner ships once.

---

## ⏱️ Delta Time: The Most Important Detail

### The Problem

`_process` runs once per frame — but frames aren't guaranteed to be
evenly spaced. 60 FPS and 30 FPS machines would run your game at
different speeds if you wrote:

```gdscript
position.x += 5   # BAD: 5 px/frame = 300 px/s @60fps, 150 px/s @30fps
```

### The Fix

`delta` is the **elapsed time since the last frame**, in seconds.
Multiply by it and movement becomes per-*second*, not per-*frame*:

```gdscript
const SPEED := 300.0   # pixels per SECOND

func _process(delta: float) -> void:
    position.x += SPEED * delta   # 300 px/s on EVERY machine
```

| Frame rate | delta | Distance/frame | Distance/second |
|-----------|-------|----------------|-----------------|
| 60 FPS | ~0.0167 s | 5 px | 300 px |
| 30 FPS | ~0.0333 s | 10 px | 300 px |

Same speed, different frame rates. **Rule**: if a value is "per second,"
multiply it by `delta`. If it's per-frame instant (a teleport, a toggle),
don't.

### `_process` vs `_physics_process`

- `_process(delta)` — every rendered frame; delta varies
- `_physics_process(delta)` — fixed rate (default 60 Hz); delta is
  constant. **Physics and movement belong here** for consistency.

---

## 🍳 Recipes You'll Reuse

```gdscript
# Move toward a target at fixed speed, stop on arrival
func _physics_process(delta: float) -> void:
    var to_target := target_pos - position
    if to_target.length() <= SPEED * delta:
        position = target_pos                       # arrived
    else:
        position += to_target.normalized() * SPEED * delta

# "Is the player in pickup range?"
if position.distance_to(coin_pos) < PICKUP_RADIUS:
    collect()

# Smooth-follow (camera, floating UI) — lerp = linear interpolation
position = position.lerp(target_pos, 5.0 * delta)

# Bounce off walls in 1D (Pong thinking)
if pos < 0 or pos > LIMIT:
    vel = -vel
```

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Coordinate** | A number locating a point on one axis |
| **Vector** | Direction + magnitude stored as `(x, y)` / `(x, y, z)` |
| **Origin** | `(0, 0)` — top-left in 2D screen space |
| **Magnitude/Length** | How long a vector is: `v.length()` |
| **Normalized** | Scaled to length 1 — pure direction |
| **Delta** | Seconds since the last frame |
| **Lerp** | Linear interpolation — blend between two values |
| **Frame-rate independent** | Same speed on any machine (thanks, delta) |

---

## 🧪 Thought Exercises

1. **Screen position**: A sprite is at `Vector2(50, 400)` in a 800×600
   window. Is it near the top or bottom?

   <details>
   <summary>Answer</summary>
   Bottom — Y grows downward, and 400 out of 600 is in the lower half.
   </details>

2. **Diagonal speed**: `velocity = Vector2(1, 1)` unnormalized vs.
   normalized — which moves faster?

   <details>
   <summary>Answer</summary>
   Unnormalized — its length is √2 ≈ 1.41, so it moves ~41% faster than
   intended. Normalize to fix.
   </details>

3. **Delta**: You forget `* delta` and test at 60 FPS. A friend runs the
   game at 144 FPS. What happens?

   <details>
   <summary>Answer</summary>
   Everything moves 2.4× faster — 144 updates/sec × same per-frame step.
   This is why delta exists.
   </details>

---

## ✅ Self-Check

- [ ] Explain why Y grows downward in 2D screen space
- [ ] Write `B - A` and say what the resulting vector means
- [ ] Explain what `normalized()` does and when you need it
- [ ] Explain `delta` in one sentence
- [ ] Explain why `position += velocity * delta` appears in every game
- [ ] Name the difference between `_process` and `_physics_process`

---

## 🚀 What's Next?

- **Stage 1**: you used 1D positions and speeds — this is the same math
  with a second component
- **Stage 2, Game 6 (2D Pong)**: velocity becomes `Vector2`, bouncing
  flips one component at a time
- **Collision Detection** (`04-Collision-Detection.md`): what happens
  when two vectors' positions overlap

---

**Vectors are the single most reused idea in game development. Learn them once, use them forever. 📐**
