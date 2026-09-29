# Game 3: 1D Pong — First to Five

**Stage 1 — 1D Games** | Difficulty: Medium  
**Concepts**: velocity (float position *and* speed), collision detection, tunneling, scoring, game states, a CPU opponent, difficulty curves — plus two-player mode and best-of-N series

---

## 🎯 The Game

Pong flattened onto a number line. You defend cell `0` (left wall); the
CPU defends cell `track_length - 1` (right wall). The ball `o` flies back
and forth — but this time it has **real velocity**: a float position and a
speed in *cells per tick*. At speed `1.5` it skips half the cells. At `3.0`
it only touches down every third cell.

That's the whole game, because of the return rule: **a ball comes back
only if it LANDS on a cell your paddle covers** (`P` ± coverage, shown as
`-`). The ball can sail straight over your head between landings —
positioning isn't about being close, it's about standing where it will
*touch down*. The `*` marker shows the next landing cell.

Every return adds `speed_up` to the ball, so rallies accelerate. The
mechanics that keep it interesting:

- **Edge hits = paddle angle.** Meeting the ball on the mid-court edge of
  your reach is a *drive* (`+edge_bonus` per cell — drives can exceed
  `max_speed`). Scooping it off your wall line is a weak *dig*. In real
  Pong, where on the paddle you hit changes the angle; in 1D, it changes
  the speed — which changes every landing cell after it.
- **Smash.** Move *toward* the incoming ball on the exact tick it lands on
  you and it comes back `+smash_bonus` faster. Aggression is a mechanic.
- **The ball gets "hot".** Effective coverage shrinks by 1 every
  `shrink_every` returns, down to dead-center hits only (coverage ±0).
  Watch the `-` marks vanish — and the ball's color shift yellow →
  magenta → red. Past a certain rally length, the sparse landings *must*
  slip through — no point lasts forever. A tiny per-return speed `jitter`
  also guarantees it: dead-center orbits on commensurate landing lattices
  can't survive perturbed phases.
- **Serve choice.** `1` = lob (slow, safe), `2`/Enter = standard, `3` =
  flat (fast, pressures the receiver — but might beat your own read too).
- **Best-of-N series** (`series_length`, default 3 → first to 2 matches).
- **Two players** (`players = 2`): P1 on `a`/`d`, P2 on `,`/`.`, both
  moves typed on one line.

First to `points_to_win` takes the match. The CPU plays by identical
rules: it predicts landing cells, moves one cell per tick like you, but
freezes for `reaction_delay` ticks after you shoot and sometimes commits
to the wrong read (`error_rate`). Career record and best rally persist in
`settings.cfg` under `[scores]`.

---

## ⚙️ Configuration: `settings.cfg`

Rules are read from `settings.cfg` at startup. If the file is missing,
the game **creates it with defaults** — run once, edit, rerun.

```ini
[game]
track_length = 20
points_to_win = 5
series_length = 3
start_speed = 1.5
serve_lob = 0.9
serve_flat = 2.2
speed_up = 0.25
edge_bonus = 0.15
smash_bonus = 0.4
jitter = 0.06
max_speed = 3.0
swept_collision = false
paddle_radius = 1
shrink_every = 6
players = 1

[ai]
reaction_delay = 2
error_rate = 0.1

[ui]
aim_assist = true
use_color = true
clear_screen = true
```

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `track_length` | int | `20` | Cells `0` to `track_length - 1`; halves split at `track_length / 2` (clamped ≥ 8) |
| `points_to_win` | int | `5` | Points needed to take a match |
| `series_length` | int | `3` | Matches per series — forced odd; `1` = single-match mode |
| `start_speed` | float | `1.5` | Standard serve speed — keep it **> 1** or every cell lands and the game is trivial |
| `serve_lob` / `serve_flat` | float | `0.9` / `2.2` | Alternate serve speeds (keys `1`/`3`) |
| `speed_up` | float | `0.25` | Added to ball speed on every return |
| `edge_bonus` | float | `0.15` | Extra return speed per cell of edge — the "angle" knob |
| `smash_bonus` | float | `0.4` | Extra speed when you move *toward* the ball on its landing tick |
| `jitter` | float | `0.06` | Random ± speed perturbation per return — breaks perfect orbits; `0` = fully deterministic |
| `max_speed` | float | `3.0` | Soft cap; edge+smash can exceed it up to `max_speed × 1.25` |
| `swept_collision` | bool | `false` | Experimental: ball can't skip *through* coverage. **Try it — then read why it's off** (below) |
| `paddle_radius` | int | `1` | Base coverage on each side of the paddle (0 = dead-center only, brutal) |
| `shrink_every` | int | `6` | Coverage shrinks by 1 every this many returns — set huge to disable |
| `players` | int | `1` | `2` = two humans share the keyboard |
| `reaction_delay` | int | `2` | Ticks the CPU is frozen after the ball turns its way — the difficulty knob |
| `error_rate` | float | `0.1` | Chance per incoming shot the CPU commits to a wrong landing read |
| `aim_assist` | bool | `true` | Show `*` on the next landing cell — turn off when you can predict it yourself |
| `use_color` / `clear_screen` | bool | `true` | ANSI colors / redraw the HUD each tick |

Color and screen-clearing are **automatically disabled** when output is
piped or `NO_COLOR` is set. (`FORCE_COLOR=1` overrides for testing.)
**Validation is built in**: absurd values are clamped, `series_length` is
forced odd, `players` clamps to 1–2.

### On `swept_collision = true` — the honest result

The improvement suggestion asked: does swept collision make the game
*better* or just *easier*? We implemented it — flip the flag and play.
**Easier. Much worse.** With swept checks the paddle's coverage becomes an
impenetrable wall segment: the ball can never tunnel between landings, so
covering any cell the path crosses always returns it. Park on your wall
cell and you are literally unbeatable — no point can ever end against you.
That experiment is exactly why the landing rule exists: in 1D, *tunneling
is the gameplay*. In 2D Pong, swept collision is correct because the
paddle is a real barrier and the second axis provides escape angles.

Suggested variants: `shrink_every = 4` + `start_speed = 2.0` for lightning
rounds; `paddle_radius = 0` once you've mastered the landing math;
`players = 2` to settle arguments.

---

## ▶️ How to Run

**Easiest**: double-click `run.bat` in this folder.

Or open a terminal in this folder and run:

```cmd
godot --headless --script main.gd
```

Use the **console** Godot build (`*_console.exe`) — the regular
`Godot_v4.x_win64.exe` detaches from the console on Windows and can't do
interactive stdin. If `godot` isn't on PATH, either invoke the console exe
by its full path, or set it in the `GODOT` variable at the top of `run.bat`.

> ⚠️ **Do NOT run it from the Godot editor** (Script Editor → Run). The
> editor's script runner only supports `@tool`/`EditorScript` utility
> scripts. Our game `extends SceneTree` — it's the whole engine main
> loop — and needs a real terminal for stdin anyway.

## 🎮 Commands

**Single-player:**

| Input | Effect |
|-------|--------|
| `left` / `l` / `a` | Move one cell toward your wall |
| `right` / `r` / `d` | Move one cell toward mid-court |
| `wait` / `w` / *(just Enter)* | Hold position for a tick |
| `help` / `h` / `?` | Show the move list |
| `quit` / `q` | Walk off the court |
| `1` / `2` / `3` / `s` / Enter | Serve: lob, standard, hard (when ball is dead) |
| `y` / `n` | At match/series end: continue or exit |

**Two-player** (`players = 2`): one line per tick, first char moves P1,
second moves P2 — `a`/`d` (or `l`/`r`) for P1, `,`/`.` for P2. `a,` = P1
left + P2 left. A lone `,` or `.` moves only P2. `w` = both wait.

**Every action while the ball is live is one tick** — paddles and ball all
move. Between points the world doesn't tick: move freely before serving.
Whoever conceded the last point receives the next serve. **Smash**: move
toward the incoming ball on its landing tick for a faster return.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Velocity | `ball_pos`, `ball_vel` | Game 2's `pos`/`dir` grown up: position is a **float**, speed is cells-per-tick with sign — one variable, two facts |
| Integration | `ball_pos += ball_vel` | The one line every physics engine shares. `pos += vel * delta` is next (2D games) |
| Landing-based collision | `_take_turn`, `_hit_cell` | The ball is checked where it **ends** the tick — `floori(ball_pos)` — not where it passed |
| Tunneling | `_hit_cell` | At speed > 1 the ball skips over the paddle between checks — the classic reason fast objects escape collision |
| Swept alternative | `_hit_cell` (flag) | The "obvious fix" implemented so you can feel why it's wrong here — see the README section above |
| Collision response | `_return_ball` | Velocity flips sign, magnitude grows, edge + smash + jitter all feed one speed formula |
| The angle analog | `edge` in `_return_ball` | Where in your coverage you intercept changes the return speed — Pong's paddle-angle rule, translated to 1D |
| Momentum | `smashed` in `_return_ball` | `move_dir == direction` — stepping *into* the shot = smash. Movement this tick changes the collision outcome |
| Difficulty curve | `_coverage()` | Effective radius shrinks with rally length — a parametric version of Game 4's spawn timers |
| Orbit breaking | `jitter` | Tiny per-return speed noise guarantees no landing lattice survives — determinism is fragile on purpose |
| Scoring & states | `_point_to`, `enum State` | Point → serve → match → series: three states now — note how cleanly `MATCH_OVER`/`SERIES_OVER` extend the enum |
| Serve variety | `_serve(speed, label)` | One function, three calls — the serve types are just data |
| Simple AI | `_update_ai`, `_ai_pick_target` | Simulate future landings, pick the first reachable one — prediction as strategy. `ai_delay` + `ai_misread` make it beatable |
| Shared input | `_parse_moves` | Two players, one line: char 1 = P1, char 2 = P2 — a parse table instead of two input paths |
| Symmetric rules | `_coverage()` everywhere | CPU/P2 returns use the *same* checks and shrinkage — fairness by construction |
| Config validation | `_validate_config` | `mid` and `matches_needed` are derived once, after clamping — invariants belong to validation |
| Persistence | `[scores]` section | Career record survives sessions — same `ConfigFile` pattern as Game 1 |

### The tick, annotated

```
_take_turn(dir1, dir2):
    P1 moves (clamped to its half)     # INPUT applied
    P2 moves, or _update_ai()          # opponent reacts
    ball_pos += ball_vel               # the ball flies
    cell = floori(ball_pos)
    cell < 0      → right side scores  # goal lines checked
    cell >= N     → left side scores   # BEFORE returns,
    _hit_cell()   → return: speed, edge, smash, jitter, shrink
    else → report next landing         # feedback for next tick
```

Check order matters, same lesson as Game 2's win check: out-of-bounds is
tested **before** the return rule, so a paddle's coverage can't extend
past the goal line.

---

## ✅ Test Checklist

**Automated**: `test_main.gd` covers the mechanics below — run `run_tests.bat`
or `godot --headless --script test_main.gd`. It instantiates the game without
a session, which is why the loop lives in `_initialize()`, not `_init()`.

Verify each of these by actually playing:

- [ ] `l`/`r`/`a`/`d` move you one cell inside your half; mid-court blocks you
- [ ] `w`/Enter holds you still — and the ball still flies
- [ ] The `*` marker correctly predicts the next landing cell
- [ ] A ball landing on a `-` cell comes back; landing elsewhere keeps going
- [ ] At speed ≥ 2, watch the ball visibly **skip** cells
- [ ] Serves: `1` is slow, `3` is fast, Enter is standard — speeds differ
- [ ] Meeting the ball on the mid-court edge says "driven back!" — faster
- [ ] Move *toward* the ball on its landing tick → "SMASHED!" and a jump in speed
- [ ] Around rally `shrink_every`, the `-` marks shrink and a warning prints
- [ ] A long rally *must* end — at coverage ±0, dead-center or bust
- [ ] The ball's color heats up with speed (yellow → magenta → red)
- [ ] Ball past cell 0 / past cell 19 scores for the opponent of that wall
- [ ] The CPU freezes visibly after your return (`reaction_delay`)
- [ ] Match point → "Next match? (y/n)"; series decided → "New series?"
- [ ] `l`/`r` between points repositions you for free before the serve
- [ ] `players = 2`: `a,` moves P1 left AND P2 left on one tick; `.` alone moves P2 only
- [ ] `swept_collision = true`: park on cell 0 and you cannot lose — feel why it's off
- [ ] `jitter = 0` + parked paddles can orbit at coverage 0; jitter kills it
- [ ] `quit` mid-match exits cleanly; invalid input warns and costs no tick
- [ ] Re-run: `[scores]` in `settings.cfg` shows your career record
- [ ] `start_speed = 1.0` proves why speed must exceed 1 (every cell lands)

---

## 🛠️ Improvement Ideas

The original list — and what happened:

1. ~~**Lobber serve**~~ — **done.** `1`/`2`/`3` at the serve prompt.
2. ~~**Swept collision**~~ — **done, as an experiment.** `swept_collision`
   config flag; the README's "honest result" section is the finding: it
   makes the game worse by making wall-camping unbeatable. Worth keeping
   as a switchable lesson.
3. ~~**Smash charge**~~ — **done.** Step toward the incoming ball on its
   landing tick for `smash_bonus` speed. CPU/P2 can smash too.
4. ~~**Best-of-N matches**~~ — **done.** `series_length` config + a third
   game state (`SERIES_OVER`). Watch `_update` dispatch all three.
5. ~~**Two-player mode**~~ — **done.** `players = 2`; combined input lines.
   `_update_ai` is simply skipped — symmetric rules paid off.
6. ~~**Heat as UI**~~ — **done.** The ball's color is its speed tier.

If you want more, ranked by difficulty:

1. **Persistent series record** — `[scores]` tracks matches; extend it to
   series won/lost.
2. **Whiffed smash** — smashing when the ball *doesn't* land on you could
   cost you a positioning tick (stumble). Risk/reward for aggression.
3. **Replays** — log each point's landing cells and "replay" the rally as
   an animation after the match.
4. **Doubles of ourselves** — save the CPU's target prediction to the HUD
   (`aim_assist` for it too) and watch where it *thinks* the ball lands.

---

## 💭 Reflection

Before moving to Game 4, be able to answer:

- Why does `start_speed = 1.0` make the game trivial? What property of
  integer landings does a float speed break?
- The goal check runs **before** the return check — trace what happens if
  you swap them when a paddle stands on its wall cell.
- `_coverage()` shrinks with `rally_len` — why shrink *coverage* instead
  of just capping rally length? What does each do to the *feel* of a
  long point?
- Swept collision is the "correct" physics fix for tunneling — so why is
  it the wrong *design* fix here? What does this teach about rules vs.
  simulation?
- A ±0.06 jitter kills guaranteed orbits. Why does a tiny randomness beat
  a large deterministic change for this job?
- In `_parse_moves`, why is a lone `,` special-cased before the general
  char-pair parse? What would it mean otherwise?
- The CPU "predicts" by simulating landings — the same math you do in
  your head. When does a misread actually hurt it?

Then update `PROGRESS.md` (Game 3 → completed) and move on to
**Game 4: 1D Endless Runner** — where the spawning timers you met as
`shrink_every` become the whole game, and the difficulty curve gets a name.
