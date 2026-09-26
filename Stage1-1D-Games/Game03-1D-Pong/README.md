# Game 3: 1D Pong — First to Five

**Stage 1 — 1D Games** | Difficulty: Medium  
**Concepts**: velocity (float position *and* speed), collision detection, tunneling, scoring, match states, a CPU opponent, difficulty curves

---

## 🎯 The Game

Pong flattened onto a number line. You defend cell `0` (left wall); the
CPU defends cell `track_length - 1` (right wall). The ball `o` flies back
and forth — but this time it has **real velocity**: a float position and a
speed in *cells per tick*. At speed `1.5` it skips half the cells. At `3.0`
it only touches down every third cell.

That's the whole game, because of the return rule: **a ball comes back
only if it LANDS on a cell your paddle covers** (`P` ± `paddle_radius`,
shown as `-`). The ball can sail straight over your head between landings —
positioning isn't about being close, it's about standing where it will
*touch down*. The `*` marker shows the next landing cell.

Every return adds `speed_up` to the ball, so rallies accelerate. Two rules
keep a rally from becoming an orbit:

- **Edge hits = paddle angle.** Meeting the ball on the mid-court edge of
  your reach is a *drive* (`+edge_bonus` per cell — drives can exceed
  `max_speed`). Scooping it off your wall line is a weak *dig*. In real
  Pong, where on the paddle you hit changes the angle; in 1D, it changes
  the speed — which changes every landing cell after it.
- **The ball gets "hot".** Effective coverage shrinks by 1 every
  `shrink_every` returns, down to dead-center hits only (radius 0). Watch
  the `-` marks vanish. Past a certain rally length, the sparse landings
  *must* slip through — no point lasts forever.

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
start_speed = 1.5
speed_up = 0.25
edge_bonus = 0.15
max_speed = 3.0
paddle_radius = 1
shrink_every = 6

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
| `start_speed` | float | `1.5` | Serve speed in cells/tick — keep it **> 1** or every cell lands and the game is trivial |
| `speed_up` | float | `0.25` | Added to ball speed on every return |
| `edge_bonus` | float | `0.15` | Extra return speed per cell you meet the ball ahead of your paddle — the "angle" knob |
| `max_speed` | float | `3.0` | Soft cap; drives can exceed it up to `max_speed × 1.25` |
| `paddle_radius` | int | `1` | Coverage on each side of the paddle (0 = dead-center hits only, brutal) |
| `shrink_every` | int | `6` | Coverage shrinks by 1 every this many returns — set huge to disable |
| `reaction_delay` | int | `2` | Ticks the CPU is frozen after the ball turns its way — the difficulty knob |
| `error_rate` | float | `0.1` | Chance per incoming shot the CPU commits to a wrong landing read |
| `aim_assist` | bool | `true` | Show `*` on the next landing cell — turn off when you can predict it yourself |
| `use_color` / `clear_screen` | bool | `true` | ANSI colors / redraw the HUD each tick |

Color and screen-clearing are **automatically disabled** when output is
piped or `NO_COLOR` is set. (`FORCE_COLOR=1` overrides for testing.)
**Validation is built in**: absurd values are clamped, including
`max_speed ≥ start_speed`.

Suggested variants: `shrink_every = 4` + `start_speed = 2.0` for lightning
rounds; `paddle_radius = 0` once you've mastered the landing math.

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

| Input | Effect |
|-------|--------|
| `left` / `l` | Move one cell toward your wall |
| `right` / `r` | Move one cell toward mid-court |
| `wait` / `w` / *(just Enter)* | Hold position for a tick |
| `help` / `h` / `?` | Show the move list |
| `quit` / `q` | Walk off the court |
| `s` / Enter | Serve when the ball is dead |
| `y` / `n` | At match end: rematch or exit |

**Every action while the ball is live is one tick** — paddle, CPU, and
ball all move. Between points the world doesn't tick: `l`/`r` repositions
you for free before the serve. Whoever conceded the last point receives
the next serve.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Velocity | `ball_pos`, `ball_vel` | Game 2's `pos`/`dir` grown up: position is a **float**, speed is cells-per-tick with sign — one variable, two facts |
| Integration | `ball_pos += ball_vel` | The one line every physics engine shares. `pos += vel * delta` is next (2D games) |
| Landing-based collision | `_take_turn` | The ball is checked where it **ends** the tick — `floori(ball_pos)` — not where it passed |
| Tunneling | the same line | At speed > 1 the ball can skip over the paddle between checks — the classic reason fast objects escape collision. The fix (swept checks) is improvement idea #2 |
| Collision response | `_return_ball` | Velocity flips sign, magnitude grows — `vel = dir * new_speed` |
| The angle analog | `edge` in `_return_ball` | Where in your coverage you intercept changes the return speed — Pong's paddle-angle rule, translated to 1D |
| Difficulty curve | `_coverage()` | Effective radius shrinks with rally length — a parametric version of Game 4's spawn timers |
| Scoring & states | `_point_to`, `enum State` | Point → serve → point → `MATCH_OVER` — the same two-state skeleton, now with a `ball_live` sub-state for the serve |
| Simple AI | `_update_ai`, `_ai_pick_target` | Simulate future landings, pick the first reachable one — prediction as strategy. `ai_delay` + `ai_misread` make it beatable |
| Symmetric rules | `_coverage()` everywhere | The CPU's returns use the *same* checks and shrinkage as yours — fairness by construction, one code path |
| Config validation | `_validate_config` | `mid = track_length / 2` is derived once, after clamping — invariants belong to validation |
| Persistence | `[scores]` section | Career record survives sessions — same `ConfigFile` pattern as Game 1 |

### The tick, annotated

```
_take_turn(direction):
    player_pos += direction (clamped to your half)   # INPUT applied
    _update_ai()                                     # CPU reacts / drifts home
    ball_pos += ball_vel                             # the ball flies
    cell = floori(ball_pos)
    cell < 0      → CPU scores                       # goal lines checked
    cell >= N     → you score                        # BEFORE returns,
    cell covered? → return, speed up, maybe shrink   # else it slips through
    else → report next landing                       # feedback for next tick
```

Check order matters, same lesson as Game 2's win check: out-of-bounds is
tested **before** the return rule, so a paddle's coverage can't extend
past the goal line.

---

## ✅ Test Checklist

Verify each of these by actually playing:

- [ ] `l`/`r` move you one cell inside your half; you can't cross mid-court
- [ ] `w`/Enter holds you still — and the ball still flies
- [ ] The `*` marker correctly predicts the next landing cell
- [ ] A ball landing on a `-` cell comes back; landing elsewhere keeps going
- [ ] At speed ≥ 2, watch the ball visibly **skip** cells it "should" have hit
- [ ] Serving into your covered cells returns instantly — net play works
- [ ] Meeting the ball on the mid-court edge says "driven back!" and beats `max_speed`
- [ ] Around rally `shrink_every`, the `-` marks shrink and a warning prints
- [ ] A long rally *must* end — at coverage 0, dead-center or bust
- [ ] Ball past cell 0 / past cell 19 scores for the opponent of that wall
- [ ] The CPU freezes visibly after your return (`reaction_delay`)
- [ ] Reaching `points_to_win` ends the match with a record line; `y` rematches
- [ ] `l`/`r` between points repositions you for free; Enter serves
- [ ] `quit` mid-match exits cleanly; invalid input warns and costs no tick
- [ ] Re-run: `[scores]` in `settings.cfg` shows your career record
- [ ] `reaction_delay = 0` + `error_rate = 0` makes the CPU nearly unbeatable
- [ ] `start_speed = 1.0` proves why speed must exceed 1 (every cell lands)

---

## 🛠️ Improvement Ideas

Ordered by difficulty — pick one and implement it yourself:

1. **Lobber** — serve with `l`/`r` held to choose a shallow or steep serve
   speed (`l` = slow & safe, `r` = fast & risky). One `if` in `_serve()`.
2. **Swept collision** — the tunneling fix: check whether the ball's
   *path* this tick crossed any covered cell, not just its landing cell.
   `for c in range(old_cell, new_cell)` — does it make the game better or
   just easier? Argue both ways first.
3. **Smash charge** — moving *toward* the incoming ball on the tick it
   lands on you adds an extra speed bonus. Now aggression has a mechanic.
4. **Best-of-N matches** — wrap `matches` in a series (first to win 2).
   You'll need a third state — watch how cleanly the `enum` extends.
5. **Two-player mode** — second paddle on `a`/`d` instead of the CPU.
   `_update_ai` becomes `_read` for player 2 — the code barely changes,
   which is the point of symmetric rules.
6. **Heat as UI** — color the ball by speed tier (slow/⚠/🔥) so the HUD
   reads the difficulty curve at a glance.

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
- The CPU "predicts" by simulating landings — the same math you do in
  your head. Why is a misread of ±2 cells often harmless to it? (Hint:
  landings are ~3 cells apart and coverage is 3 wide.)
- Edge hits are 1D "paddle angle". What would the *2D* version of the
  landing rule be — and why does real Pong not need it?

Then update `PROGRESS.md` (Game 3 → completed) and move on to
**Game 4: 1D Endless Runner** — where the spawning timers you met as
`shrink_every` become the whole game, and the difficulty curve gets a name.
