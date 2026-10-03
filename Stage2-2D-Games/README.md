# Stage 2: 2D Games

**Focus**: 2D coordinate systems, real-time gameplay, and visual games
built inside the Godot editor
**Games**: 6 (`Game05`–`Game10`) | **Prerequisite**: Stage 1 complete
**Deliverable**: Six complete, playable windowed games

---

## 🔄 What Changes in Stage 2

Stage 1 games were console programs: `extends SceneTree`, a loop you
controlled, one tick per typed command, ASCII for graphics. Stage 2
moves into the **real engine**:

| Stage 1 (console) | Stage 2 (real-time) |
|-------------------|---------------------|
| `extends SceneTree`, `--headless --script` | `extends Node2D` scene, run with F5 |
| One tick per line of input | `_process(delta)` runs ~60×/second, input is *held keys and clicks* |
| `pos` is a float on a number line | `position` is a `Vector2` in pixels |
| ASCII grid redrawn each tick | `Sprite2D` / `draw_*` rendered every frame |
| `sleep` between frames impossible | `delta` makes speed frame-rate independent |
| `match` on typed commands | `Input.get_vector`, `_unhandled_input`, `InputEventMouseButton` |
| Direct function calls | **Signals**: `body_entered`, `timeout`, `pressed` |

The game-loop lesson from Stage 0 doesn't change — input → update →
render — but now the engine owns the loop and calls *you*. That's the
single biggest mental shift of this stage.

### New engine pieces you'll meet

`Node2D`, `Sprite2D`, `CharacterBody2D`, `Area2D`, `CollisionShape2D`,
`StaticBody2D`, `Timer`, `Camera2D`, `TileMapLayer`, `CanvasLayer` +
`Control` for HUD. All are in `QUICK-REFERENCE.md`.

---

## 📖 Read First (Theory)

Before the games, in this order:

| When | Read | Why |
|------|------|-----|
| Before Game 5 | `Resources/Theory/03-Coordinates-and-Vectors.md` | Position becomes a *pair* of numbers; `pos += vel * delta`; Y grows **down** |
| Before Game 6 | `Resources/Theory/04-Collision-Detection.md` | Overlap tests, tunneling (you met this in Game 3), physics bodies |
| Before Game 6 | `Resources/Theory/05-Signals-and-Events.md` | `body_entered` and `timeout` replace manual polling |
| Throughout | `Resources/Theory/06-Debugging-and-Testing.md` | Debugger, breakpoints, error reading |

---

## 📁 Per-Game Setup

Each `GameNN-*` folder is **its own Godot project**:

```
GameNN-Name/
├── DESIGN.md         ← copy Game-Design-Doc-Template.md, fill during Plan step
├── README.md         ← copy Game-README-Template.md when the game is done
├── project.godot
├── main.tscn         ← root Node2D + HUD labels
├── main.gd           ← starts from scene-game-template.gd
└── (scenes/ scripts/ as the game grows — Game 8+)
```

- **Template**: start `main.gd` from `Resources/Templates/scene-game-template.gd`
  (`MENU / PLAYING / PAUSED / GAME_OVER` states, `Input.get_vector`
  movement, `draw_circle` placeholder rendering — all working out of
  the box with the default `ui_*` actions).
- **Run**: open the folder in the Godot editor, press **F5**. No
  `run.bat` needed for windowed games — that's a Stage 1 console
  convention.
- **Window**: pick one viewport size per game and document it in
  `DESIGN.md` (640×360 scaled up, or 1280×720, are good defaults).
- **Assets**: `Resources/Assets/placeholders/` has drop-in SVG shapes
  (player, ball, paddle, coin, enemy, tile). Use them; real art is a
  later problem.
- **`settings.cfg` becomes optional**: `@export` vars and the Input Map
  now cover most of what it did. Keep it only where a game genuinely
  wants player-tunable rules — decide per `DESIGN.md`.
- **Tests**: `test_main.gd` still works for *pure logic* (Snake's grid
  rules are very testable headless). Don't force it on physics code —
  the README checklist is the real test for feel-based games.

---

## 🎮 The Six Games (Build Order)

Difficulty and scope ramp deliberately. Each entry lists the one skill
the game *exists to teach* — everything else is carried practice.

### Game 5: 2D Clicker — first contact with the editor

**Exists to teach**: the editor itself — scenes, nodes, signals, UI —
with near-zero game-logic risk.

- **The game**: targets pop up at random positions; click them before
  they expire. 30-second round, score, best score.
- **New concepts**: `InputEventMouseButton` / `Button.pressed`, `Control`
  nodes, `Timer` node + `timeout` signal, random `Vector2` positions,
  spawning/despawning nodes at runtime.
- **Builds on**: Game 4's spawn cooldowns — now they're a real `Timer`
  node instead of a counter you decrement.
- **MVP**: spawn → click → score, round timer, restart.
- **Anti-scope**: no physics bodies, no movement. This game is about
  the *editor*, not the gameplay.

### Game 6: 2D Pong — vectors arrive

**Exists to teach**: `Vector2` velocity and real-time collision — the
direct port of Game 3.

- **The game**: two paddles, one ball, first to N. Player vs CPU or
  two-player.
- **New concepts**: `position += velocity * delta`, delta time, AABB /
  `move_and_collide`, reflect bounces, wall boundaries.
- **The port**: Game 3's `edge_bonus` (speed per cell of edge) becomes a
  real *angle* — where the ball hits the paddle changes the bounce
  direction. Game 3's tunneling experiment (`swept_collision`) is now
  simply *correct physics* — the paddle is a real barrier and the second
  axis provides escape angles, exactly as predicted in its README.
- **MVP**: paddles + ball + walls + score + serve + speed-up on return.
- **Improvements**: CPU difficulty knobs, paddle spin, screen shake.

### Game 7: Snake — the grid inside the screen

**Exists to teach**: arrays as a live data structure, and how a
*discrete* game lives inside a continuous engine.

- **The game**: the classic — eat, grow, don't hit walls or yourself.
- **New concepts**: an `Array` of `Vector2i` cells *is* the body, the
  grid↔pixel mapping (`cell * cell_size`), **input buffering** (queue the
  direction so a 180° turn within one step can't suicide you), stepping
  on a `Timer` instead of every frame.
- **Key insight**: Snake does *not* update in `_process` — it's a
  turn-based game on a fast clock. You already know this loop; the grid
  is `track_length` squared.
- **MVP**: grid move, food spawn (never on the body), grow, wall +
  self collision, score.
- **Improvements**: wrap-around walls mode, obstacles, speed ramp.
  *Strong candidate for headless `test_main.gd` — the rules are pure
  logic.*

### Game 8: Breakout — many objects, one loop

**Exists to teach**: managing collections — dozens of bricks, one ball,
three lives.

- **The game**: paddle, ball, brick wall. Clear the bricks to win;
  lose the ball, lose a life.
- **New concepts**: scene instancing (`preload` + `instantiate`),
  per-type collision response (wall bounces, brick dies, floor kills),
  lives vs. score, **level design as data** (a brick layout is an array
  of strings, not 60 hand-placed nodes).
- **Builds on**: Game 6's bounce math, Game 7's grid thinking for the
  brick layout.
- **MVP**: paddle + ball + one brick grid + 3 lives + win/lose.
- **Improvements**: multiple levels, powerups (wide paddle, multi-ball),
  brick HP tiers.

### Game 9: Top-Down Collect-and-Escape — worlds made of tiles

**Exists to teach**: `TileMapLayer`, `Camera2D`, and your first enemy AI.

- **The game**: explore a tiled maze, collect every coin, reach the exit
  while enemies patrol or chase.
- **New concepts**: `TileMapLayer` (painted levels with collision),
  `Camera2D` follow, `Area2D` pickups via `body_entered` signals,
  chase AI = normalize(`player_pos - enemy_pos`) × speed — Game 2's
  "move toward the target" with a second axis.
- **Builds on**: everything — signals (Game 5), vectors (Game 6), grid
  (Game 7), collections (Game 8).
- **MVP**: one tilemap level, 8-direction movement, N coins, one enemy
  type, exit opens on full collection.
- **Improvements**: patrol/chase/flee enemy states, keys and doors,
  level transitions.

### Game 10: 2D Platformer — the stage capstone

**Exists to teach**: gravity and game feel — the hardest 2D skill.

- **The game**: run, jump, avoid hazards, reach the flag.
- **New concepts**: `CharacterBody2D` + `move_and_slide()`, gravity
  (`velocity.y += g * delta`), `is_on_floor()`, **coyote time and jump
  buffering** — the direct descendants of Game 4's `grace_ticks` and
  landing grace, now industry-standard feel mechanics. Animation states.
- **Why it's last**: it combines physics (Game 6), tilemaps (Game 9),
  timers (Game 4/5), and feel tuning — a bad platformer proves nothing,
  a good-feeling one proves everything.
- **MVP**: tight run/jump, one tilemap level, spikes/hazards, goal flag,
  collectible.
- **Improvements**: double jump, moving platforms, stompable enemies,
  parallax background.

---

## 🗺️ Progression Map

| Game | One skill it teaches | Carried forward from |
|------|---------------------|----------------------|
| 5 — Clicker | Editor, nodes, signals, UI | Game 4 timers → `Timer` node |
| 6 — Pong | `Vector2` + delta + collision | Game 3 wholesale (edge→angle, tunneling→physics) |
| 7 — Snake | Arrays, grid↔pixel, input buffering | Game 2 boundaries, Stage 1 tick loop |
| 8 — Breakout | Instancing, collections, lives | Games 6 + 7 |
| 9 — Collect | Tilemap, camera, Area2D, chase AI | Games 5–8 + Game 2 pursuit math |
| 10 — Platformer | Gravity, `move_and_slide`, game feel | All of Stage 2 + Game 4 grace |

Each game's **Plan** step is where its `DESIGN.md` gets written — copy
`Resources/Templates/Game-Design-Doc-Template.md` and fill it in *before*
code, especially the states diagram and the anti-scope line.

---

## ⏱️ Suggested Pace

1–3 hours/week, advanced programming experience:

- **Games 5–6** (engine on-ramp): ~1–2 sessions each — session A:
  `DESIGN.md` + MVP; session B: improvements + README checklist.
- **Games 7–9**: ~2 sessions each.
- **Game 10**: 3–4 sessions — physics feel takes real iteration, and
  that's the point.

Rough total: 12–16 sessions.

---

## ✅ Stage Completion Checklist

You're done with Stage 2 when you can:

- [ ] Explain why `position += velocity * delta` replaces `pos += vel`
- [ ] Explain why screen Y grows downward and normalize a direction vector
- [ ] Build a scene in the editor: nodes, scripts, signals — not just code
- [ ] Use `Timer`, `Area2D`, `CharacterBody2D`, `TileMapLayer`, `Camera2D`
- [ ] Explain when to write your own overlap check vs. use physics bodies
- [ ] Implement coyote time and jump buffering from memory
- [ ] Describe one thing Game 3's 1D Pong taught you that made Game 6 trivial
- [ ] All six games: MVP complete, README written, test checklist passed
- [ ] `PROGRESS.md` updated → Stage 3 unlocks (Space Shooter)

---

*When Stage 2 is complete, head to `Stage3-2D-Advanced/` — where vectors
start rotating and systems start compounding.*
