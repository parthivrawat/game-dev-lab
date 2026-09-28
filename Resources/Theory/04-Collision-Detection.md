# Lesson: Collision Detection

## 🎯 Learning Objectives

By the end of this lesson, you will understand:
- The two halves of collision: *detection* (did we hit?) and *response* (now what?)
- Why fast objects tunnel through thin obstacles — and when it matters
- The standard overlap tests: 1D range, circle-circle, AABB
- How Godot handles collision for you: physics bodies, shapes, layers, signals
- When to write your own check vs. use the engine

---

## 💥 Detection vs. Response

Every collision system has two jobs:

1. **Detection** — *did two things overlap this frame?*
2. **Response** — *what happens because they did?* (bounce, damage,
   pickup, game over)

Game 3 (1D Pong) already did both:

```
Detection:  does the ball's landing cell fall inside paddle coverage?
Response:   flip velocity, add speed, apply edge/smash bonuses
```

Keep them as separate questions in your code — detection asks "if",
response decides "then what".

---

## 🕳️ Tunneling: The Classic Failure

Collision checks happen **once per frame/tick** at the object's *end*
position — not everywhere it passed through.

```
Tick 1:   ball at x=2  ─────►
Tick 2:                    ball at x=9
                     wall at x=5 — never touched a checked position!
```

A ball moving 7 units/check sails over a wall at x=5 without ever
"landing" on it. This is **tunneling**.

**Game 3 turned tunneling into gameplay**: the ball only returns if it
*lands* on your coverage, so positioning means predicting landing cells.
In most games, though, tunneling is a bug.

### Fixes for tunneling

| Approach | Idea | Cost |
|----------|------|------|
| Cap speed | Never move more than the obstacle's thickness per tick | Free, but limits design |
| Swept test | Check the whole *path* segment, not just the endpoint | More math |
| Smaller steps | Subdivide one big move into several small ones | More CPU |
| Continuous physics | Let the engine do it (`move_and_collide`, CCD) | Free — Godot has it |

Game 3 even ships `swept_collision` as an experiment — the README
explains why it makes *that* game worse. Rules ≠ simulation.

---

## 📐 The Three Overlap Tests You'll Write

### 1. 1D range overlap (your Stage 1 games)

```gdscript
# Do two points sit within reach of each other?
if absi(ball_cell - paddle_pos) <= coverage:
    return_ball()
```

### 2. Circle-circle (coins, explosions, pickups)

Two circles overlap when center distance < combined radii:

```gdscript
func circles_overlap(a_pos: Vector2, a_r: float,
                     b_pos: Vector2, b_r: float) -> bool:
    return a_pos.distance_to(b_pos) < a_r + b_r
```

No square roots needed if you compare squared distances —
`distance_squared_to()` is the cheap version for hot loops.

### 3. AABB — axis-aligned boxes (sprites, platforms, UI)

Two rectangles overlap when they overlap on **both** axes:

```gdscript
func aabb_overlap(a: Rect2, b: Rect2) -> bool:
    return a.position.x < b.position.x + b.size.x and \
           a.position.x + a.size.x > b.position.x and \
           a.position.y < b.position.y + b.size.y and \
           a.position.y + a.size.y > b.position.y
```

The trick: it's easier to check for *separation* — if A is fully left,
right, above, or below B, no overlap. Invert that and you get the test
above. (Godot's `Rect2` already has `intersects(b)` — the manual version
is for understanding.)

---

## 🧱 Godot's Physics Bodies (Stage 2+)

In scene-based games you rarely write overlap tests — Godot does them.
The three 2D body types:

| Node | Moves? | Collides? | Use for |
|------|--------|-----------|---------|
| `StaticBody2D` | No | Yes | Walls, floors, platforms |
| `CharacterBody2D` | By your code | Yes | Player, enemies |
| `RigidBody2D` | By physics | Yes | Crates, debris, physics props |
| `Area2D` | Optional | Detects only | Pickups, triggers, hitboxes |

Every body needs a **`CollisionShape2D`** child that defines its shape
(rectangle, circle, capsule…). A body without a shape can't collide.

### The standard player pattern

```gdscript
extends CharacterBody2D

const SPEED := 300.0

func _physics_process(delta: float) -> void:
    var dir := Input.get_vector("ui_left", "ui_right",
                                "ui_up", "ui_down")
    velocity = dir * SPEED
    move_and_slide()   # moves, collides, slides along walls
```

`move_and_slide()` is the whole collision engine in one call: move,
detect, stop/slide along surfaces. For a bounce instead of a slide,
`move_and_collide()` returns the collision so you can reflect velocity.

### Triggers: Area2D + signals

Pickups don't block movement — they *notice* it:

```gdscript
# Coin.gd — Area2D with a CollisionShape2D child
func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.collect_coin()
        queue_free()
```

### Layers and masks

Every body has a **collision layer** (what it IS) and a **collision
mask** (what it checks against). This is how "bullets hit enemies but
not the player" works — put bullets on layer 4, give them a mask that
excludes layer 1 (player). Configure it in the Inspector; no code needed.

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Collision detection** | Deciding whether two shapes overlap |
| **Collision response** | What happens when they do |
| **Tunneling** | A fast object skipping past an obstacle between checks |
| **Swept collision** | Checking the whole path, not just the endpoint |
| **AABB** | Axis-aligned bounding box — the rectangle around a sprite |
| **Physics body** | A node that participates in collisions |
| **Area2D** | A detection zone that reports overlaps without blocking |
| **Collision layer/mask** | Filters controlling what can hit what |
| **`move_and_slide()`** | CharacterBody's built-in move + collide + slide |

---

## 🧪 Thought Exercises

1. **Pick which node**: a spike trap that damages the player but doesn't
   block movement — `StaticBody2D` or `Area2D`?

   <details>
   <summary>Answer</summary>
   <b>Area2D</b> — it must detect overlap but not push the player back.
   </details>

2. **The order matters**: Game 3 checks "ball past the goal line" BEFORE
   "ball on a covered cell". Why?

   <details>
   <summary>Answer</summary>
   Otherwise a paddle standing on its wall cell could "cover" cells that
   are already out of bounds — goals first, returns second.
   </details>

3. **Cheap distance**: why is `distance_squared_to()` preferred in a
   loop that runs for 500 enemies?

   <details>
   <summary>Answer</summary>
   <code>distance_to()</code> computes a square root — relatively expensive.
   Comparing squared distances against squared radius gives the same
   true/false answer without it.
   </details>

---

## ✅ Self-Check

- [ ] Explain the difference between detection and response
- [ ] Explain tunneling and name two ways to prevent it
- [ ] Write the circle-circle overlap test from memory
- [ ] Name the three physics body types and when to use each
- [ ] Explain what a `CollisionShape2D` does
- [ ] Explain layer vs. mask
- [ ] Know when `Area2D` is the right choice over a physics body

---

## 🚀 What's Next?

- **2D Pong** (Game 6): `move_and_collide` + velocity reflection
- **Breakout** (Game 8): many colliders, different responses per target
- **Signals and Events** (`05-Signals-and-Events.md`): the
  `body_entered` connection above, explained properly

---

**Collision is where "things in the world" becomes "things in the game". 💥**
