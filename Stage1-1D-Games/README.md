# Stage 1: 1D Games

**Focus**: Game logic and state — a complete game loop, real rules, real
win/lose conditions — with zero graphics to hide behind
**Games**: 4 (`Game01`–`Game04`) | **Prerequisite**: Stage 0 complete
**Deliverable**: Four complete, playable console games

---

## 🎯 Why 1D?

Every Stage 1 game lives on a **number line**: one integer position, a
direction that is a sign, a distance that is a subtraction. That
constraint is the point — stripped of rendering, animation, and physics
engines, what's left is *the actual game*: rules, state, feedback, and
the decisions a player makes because of them.

| What 1D removes | What it forces you to learn |
|-----------------|-----------------------------|
| Sprites, scenes, the editor | The game loop is *yours*: `input → update → render` |
| Physics engines | Collision is a rule you write and can defend |
| Mouse/touch | The whole decision space fits in `l`/`r`/`w` |
| Frame timing | Every input is one tick — cause and effect stay visible |

The reward: when Stage 2 gives you a second axis and a frame loop, you'll
recognize every mechanic in these games wearing new clothes — velocity,
cooldowns, fairness floors, landing grace, all of it.

### The shared skeleton

Every game in this stage is a single-file console program with the same
shape. Once you've read one, the structure of the other three is free:

- `extends SceneTree` — the script *is* the engine's main loop
- `_initialize()` — where the session loop lives (**not** `_init`, so
  `test_main.gd` can instantiate the game without starting a session)
- `enum State` + `match` dispatch — the state machine from Stage 0,
  extended per game
- `settings.cfg` — rules read at startup, file created with defaults if
  missing, values validated and clamped
- `[scores]` section — persistence via `ConfigFile.save()`
- ANSI colors + screen clearing, **auto-disabled when piped** or when
  `NO_COLOR` is set (`FORCE_COLOR=1` overrides for tests)

---

## 📁 Per-Game Layout

Each `GameNN-*` folder is its own Godot project:

```
GameNN-Name/
├── README.md          ← how to run, code tour, checklist, improvements
├── main.gd            ← the whole game (extends SceneTree)
├── test_main.gd       ← automated checks, micro test framework
├── project.godot
├── settings.cfg       ← generated on first run, then yours to edit
├── run.bat            ← double-click runner (honors the GODOT var)
└── run_tests.bat      ← double-click test runner
```

- **Run**: `run.bat`, or `godot --headless --script main.gd` in a
  terminal — with the **console** Godot build (`*_console.exe`), the only
  one that can do interactive stdin on Windows.
- **Not from the editor**: the script runner only supports
  `@tool`/`EditorScript` scripts, and these games need a real terminal.
- **Test**: `run_tests.bat`, or `godot --headless --script test_main.gd`.
  Tests poke the logic functions directly — the automated half of each
  README's manual checklist.
- **Template**: `Resources/Templates/console-game-template.gd` +
  `test-main-template.gd` are the skeletons these games share.

---

## 🎮 The Four Games (Order Matters)

Each game adds **one new idea** to the machine the previous game built.
Played in order, no step is more than one concept long.

### Game 1: Number Guessing — the loop, the file, the lie detector

**Exists to teach**: the complete game-loop skeleton plus everything
around it — config, validation, persistence, CLI args — with the simplest
possible core.

- **The game**: guess a number in a range with limited attempts and
  temperature hints — or flip it in **reverse mode**, where the computer
  binary-searches *your* number and calls you out for contradicting
  yourself.
- **New concepts**: `enum` states, `ConfigFile` (read + write), config
  validation, dictionaries (difficulty presets, score tables), CLI
  overrides via `OS.get_cmdline_user_args()`, `[scores]` persistence.
- **The hidden math**: `7 = ceil(log2(101))` — the attempt budget *is*
  the depth of the binary-search tree. Reverse mode shows you the
  optimal strategy you'd already discovered.
- **README**: `Game01-NumberGuessing/README.md`

### Game 2: 1D Catch — the number line becomes a board

**Exists to teach**: position, distance, and boundaries — and the first
whiff of AI.

- **The game**: `P` chases a firefly `<`/`>` that drifts and bounces —
  and **dodges one cell away whenever you get adjacent**. It's only
  catchable pinned against a wall. A `max_turns` budget is the clock.
- **New concepts**: 1D position/movement, boundaries as *reject* (you)
  vs. *bounce* (firefly) vs. *mechanic* (the wall deletes its escape
  cell), distance-driven rules (`absi(a - b) == 1`), a reactive dodge
  (`signi(target - player)` — one `if` that reads like prey), uniform
  tick cost.
- **The design lesson**: every round is winnable *by construction* — the
  real game is catching it *fast*. "Is it beatable?" and "is it fun?"
  are different questions.
- **README**: `Game02-1D-Catch/README.md`

### Game 3: 1D Pong — velocity, collision, and a real opponent

**Exists to teach**: float velocity and the collision question that
still matters in 2D — *where do you check?*

- **The game**: Pong on a number line. The ball has a float position and
  a speed in cells-per-tick; it returns only if it **lands** on a cell
  your paddle covers. Returns speed up, coverage shrinks, matches chain
  into best-of-N series, one or two players.
- **New concepts**: velocity (position + speed, one float each),
  landing-based collision, **tunneling** (at speed > 1 the ball skips
  cells between checks — implemented as a *feature*, plus a
  `swept_collision` flag so you can feel why the "correct" fix ruins this
  game), edge-hit speed bonus (Pong's paddle-angle rule in 1D), smash
  timing, jitter as orbit-breaker, a predictive CPU (`reaction_delay` +
  `error_rate` make it beatable).
- **The design lesson**: check order is design — goal lines are tested
  *before* returns so coverage can't extend past the wall.
- **README**: `Game03-1D-Pong/README.md`

### Game 4: 1D Endless Runner — systems that escalate

**Exists to teach**: spawning, timers, and the difficulty curve as a
*function the player can watch*.

- **The game**: the road scrolls at you — rocks on the ground row, birds
  on the air row, walls needing a jump's **apex**. Jump or hop; the score
  is meters survived; speed and density are pure functions of distance.
- **New concepts**: spawn cooldowns (a gap *in cells* stored as a *tick
  countdown*), parametric difficulty curves, the **fairness floor** (the
  spawner refuses gaps smaller than one jump's airtime — impossible ≠
  hard), swept collision done *right* this time (obstacles crossing your
  column mid-tick), landing grace (`grace_ticks` — the seed of coyote
  time), seeded runs, ghost replay with a config signature.
- **The design lesson**: `input first, physics second, judgement last` —
  your jump applies before the world moves, so pressing `j` on the
  crossing tick still saves you.
- **README**: `Game04-1D-EndlessRunner/README.md`

---

## 🗺️ Progression Map

| Game | One skill it teaches | Carried forward |
|------|---------------------|-----------------|
| 1 — Number Guessing | Loop + config + persistence | Stage 0's `enum` states, `_initialize` loop |
| 2 — 1D Catch | Position, distance, boundaries | Game 1's states, config, tick cost |
| 3 — 1D Pong | Float velocity, landing collision | Game 2's `pos += dir` becomes `pos += vel`; bounce becomes core |
| 4 — Endless Runner | Spawning, timers, difficulty curve | Game 3's tunneling lesson, applied; `shrink_every` becomes the whole game |

And forward into Stage 2:

| Stage 1 idea | Where it returns |
|--------------|------------------|
| `pos += vel` per tick | `position += velocity * delta` per frame |
| Landing vs. swept collision | `move_and_collide`, physics bodies — where swept is simply correct |
| `edge_bonus` per cell | A real bounce *angle* on a real paddle |
| `grace_ticks` landing grace | Coyote time + jump buffering in the platformer |
| Fairness floor | Spawn/level constraints in every game that generates content |
| `enum State` + `match` | `MENU / PLAYING / PAUSED / GAME_OVER` in the scene template |
| `settings.cfg` + `[scores]` | `@export` vars, Input Map, save files |

---

## 📖 Theory Connections

- `Resources/Theory/01-What-Is-A-Game.md` — the loop these games all share
- `Resources/Theory/03-Coordinates-and-Vectors.md` — the "one dimension"
  section is literally this stage's world
- `Resources/Theory/04-Collision-Detection.md` — Game 3's landing rule
  and Game 4's swept check are the two families it describes
- `Resources/Theory/06-Debugging-and-Testing.md` — why `test_main.gd`
  exists and how the loop stays in `_initialize`

---

## ✅ Stage Completion Checklist

You're done with Stage 1 when you can:

- [ ] Draw `input → update → render` and point at each phase in any game's `_take_turn`
- [ ] Explain why the game loop lives in `_initialize`, not `_init`
- [ ] Explain tick uniformity: why a wall-bump still costs a turn
- [ ] Argue both sides of landing vs. swept collision — and name which
      game wants which
- [ ] Explain why every Game 2 round is winnable but still interesting
- [ ] Trace a difficulty curve as `f(distance)` and state its fairness floor
- [ ] Read `settings.cfg` validation and say which invariants it protects
- [ ] Pass `run_tests.bat` on all four games, and the manual checklists too
- [ ] `PROGRESS.md` updated → Stage 2 unlocks (2D Clicker)

---

*When Stage 1 is complete, head to `Stage2-2D-Games/README.md` — where
position becomes a pair of numbers and the engine starts calling you.*
