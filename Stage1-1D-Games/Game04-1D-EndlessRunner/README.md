# Game 4: 1D Endless Runner — Dustline

**Stage 1 — 1D Games** | Difficulty: Medium  
**Concepts**: spawning systems, timers/cooldowns, difficulty curves, game-over states, swept collision, fairness constraints, seeded RNG, replay/ghost data

---

## 🎯 The Game

An endless runner flattened onto a number line. You stand on a fixed
column (`player_cell`) while the road scrolls left on its own — **every
input is one tick of road**, whether you jump or just keep running. Three
things come at you from the right edge:

- **`#` rocks** roll along the ground row. One kills you only if your
  feet are **down** when it crosses your column.
- **`v` birds** fly along the air row. One kills you only if you're
  **airborne** when it crosses — jumping into a bird is the *only* way
  to die to a bird.
- **`H` walls** fill **both** rows — past `wall_min_m` meters. A wall
  clears only if you cross it exactly at your jump's **apex**: the tick
  where `air_left` reads `ceil(jump_ticks / 2)`. Too early or too late
  and you smack into it; never jump and it stops you cold.

The decision space: **when to leave the ground, and how hard.** A full
jump (`j`) covers `jump_ticks` ticks; a short hop (`s`) covers
`hop_ticks` — smaller window, but also the only way to apex a wall on
the very tick it arrives. No double-jump, no early landing — except
`grace_ticks` of *landing grace*: the tick(s) right after touchdown, a
rock still forgives you. You skid over it instead of dying.

There is no winning — the run ends when something hits you. The score is
`distance`: meters survived, which is also what drives the **difficulty
curve**:

- **Scroll speed** climbs `speed_growth` per meter, capped at
  `max_speed`. Faster obstacles mean less warning and wider jumps
  (you cover more ground in the same airtime).
- **Spawn spacing** shrinks `gap_shrink` per meter toward `min_gap`.
  Denser obstacles mean tighter sequences of jump/don't-jump reads.
- Every `milestone_m` meters a banner marks the pace lifting.

One rule keeps the curve honest: the spawn gap is never allowed below
`jump_ticks × speed` — or `jump_ticks + apex_offset` ticks for a wall,
which needs room for the apex approach. Two crossings closer than one
jump's airtime would be *impossible*, not hard — so the spawner raises
the floor itself. Every pattern the game produces is survivable; dying
is always your read, not the curve's cheat.

**Seeded runs** (`run_seed`): leave it `0` for a fresh road every
attempt, or set a number for an identical, replayable course — race a
friend on the same seed or drill one pattern until you own it.

**Ghost replay**: your best run's per-tick air/ground record is saved in
`[scores]` and replayed as a faint `p` on your column — visible only
where the ghost *diverges* from what you're doing. It's ignored if the
tuning it was recorded under changes (checked via a config signature).
Career best distance and totals persist in `settings.cfg` under
`[scores]` too.

---

## ⚙️ Configuration: `settings.cfg`

Rules are read from `settings.cfg` at startup. If the file is missing,
the game **creates it with defaults** — run once, edit, rerun.

```ini
[game]
track_length = 24
player_cell = 4
jump_ticks = 3
hop_ticks = 2
grace_ticks = 1
start_speed = 1.0
speed_growth = 0.02
max_speed = 2.5
start_gap = 9.0
min_gap = 5.0
gap_shrink = 0.03
flyer_chance = 0.25
wall_chance = 0.15
wall_min_m = 40
spawn_delay = 4
milestone_m = 50
run_seed = 0

[ui]
use_color = true
clear_screen = true
show_ghost = true
```

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `track_length` | int | `24` | Cells `0` to `track_length - 1`; obstacles spawn at the right edge |
| `player_cell` | int | `4` | Your fixed column — closer to the left = more warning time |
| `jump_ticks` | int | `3` | Ticks a full jump keeps you airborne — longer covers more crossings but locks out re-jumps longer |
| `hop_ticks` | int | `2` | Ticks a short hop covers — and the last-second way to hit a wall's apex |
| `grace_ticks` | int | `1` | Landing grace: rocks forgive this many grounded ticks after touchdown (0 = off) |
| `start_speed` | float | `1.0` | Scroll speed in cells/tick at the start of a run |
| `speed_growth` | float | `0.02` | Added to scroll speed per meter run — the "gets faster" knob |
| `max_speed` | float | `2.5` | Hard cap on scroll speed |
| `start_gap` | float | `9.0` | Cells between consecutive spawns at distance 0 |
| `min_gap` | float | `5.0` | The spacing floor the *curve* wants — the fairness floor may raise it further |
| `gap_shrink` | float | `0.03` | Cells the spawn gap loses per meter run — the "gets denser" knob |
| `flyer_chance` | float | `0.25` | Chance each spawn is a bird (stay low) |
| `wall_chance` | float | `0.15` | Chance each spawn is a wall (apex only) — checked *after* the bird roll |
| `wall_min_m` | int | `40` | Walls can't spawn before this distance — mechanics unlock as the run deepens |
| `spawn_delay` | int | `4` | Ticks of clear track before the first obstacle |
| `milestone_m` | int | `50` | Pace banner every this many meters (0 = off) |
| `run_seed` | int | `0` | 0 = fresh road each run; any other value makes every attempt identical |
| `use_color` / `clear_screen` / `show_ghost` | bool | `true` | ANSI colors / redraw the HUD each tick / replay the best-run ghost |

Color and screen-clearing are **automatically disabled** when output is
piped or `NO_COLOR` is set. (`FORCE_COLOR=1` overrides for testing.)
**Validation is built in**: absurd values are clamped, and the fairness
floor (`jump_ticks × speed`, more for walls) always wins over `min_gap`.

Suggested variants: `flyer_chance = 0.5` for a reading-comprehension
nightmare; `hop_ticks = 1` + `wall_chance = 0.4` for a precision-apex
gauntlet; `run_seed = 7` to drill a fixed course; `grace_ticks = 0` for
purist rules.

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
| `jump` / `j` | Leave the ground for `jump_ticks` ticks (costs the tick) |
| `hop` / `s` | Short hop for `hop_ticks` ticks — sniper jump for wall apexes |
| `wait` / `w` / `run` / *(just Enter)* | Keep running for one tick |
| `help` / `h` / `?` | Show the move list |
| `quit` / `q` | Step off the trail — meters earned still count |
| `y` / `n` | At run end: go again or exit |

**Every action is one tick** — jumping, waiting, even a wasted
double-jump press. The road never pauses. Wall timing: press `j` when
the wall's countdown reads `apex_air` (`2` by default), or `s` when it
reads `hop_ticks - apex_air + 1` (`1` by default — hop on the tick
itself). The HUD warns `JUMP NOW` / `HOP NOW` at exactly those moments.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Spawning | `_spawn_obstacle` | The spawner is a *cooldown timer* (`spawn_cd`) reset from a distance gap — spawn logic is "when", not "what" |
| Gap → time | `ceil(_spawn_gap / speed)` | Cells between obstacles converted to ticks at current speed — spacing stays constant while density reads as pressure |
| Difficulty curve | `_current_speed`, `_curve_gap` | Both are **pure functions of `distance`** — the difficulty is a curve the player can watch in the HUD, not dice rolls behind a screen |
| Fairness floor | `_spawn_gap` | Per-kind constraint: `jump_ticks` ticks of crossing spacing for rocks/birds, `+ apex_off` for walls. The game refuses to produce unsolvable patterns |
| Swept collision | `was > player_cell and now < player_cell` | Game 3's tunneling lesson, applied: at speed > 1 an obstacle can skip your cell between checks — so the check asks "did it occupy the column this tick" |
| Lingering collision | `now == player_cell` re-checked every tick | At `start_speed < 1` an obstacle can sit on your cell for two ticks — touch down on a rock still under you and it still wins |
| Kind-based adjudication | `_adjudicate` | One `match`, three rules: rock wants air, bird wants ground, wall wants `air_left == apex_air`. New obstacle types plug into the same crossing pipeline |
| Apex as arithmetic | `_apex_air` | "Mid-jump" is just `air_left` equality — no arc simulation needed when jump is a countdown |
| Two jump sizes | `hop` in `_take_turn` | The hop isn't a smaller *force* — it's a shorter *timer*. Same mechanic, different window |
| Coyote time | `grace_left` | The industry term for landing grace — one more countdown timer next to `air_left` |
| Seeded RNG | `run_seed` in `_start_run` | Re-seeding *per run* is what makes attempts replayable — `randomize()` at startup alone would still drift between runs |
| Replay/ghost data | `run_log`, `career_ghost`, `_ghost_sig` | A recording is just per-tick state (`a`/`g`); a **signature** of the tuning it was made under keeps stale ghosts from lying to you |
| Milestones | `next_milestone` | Difficulty pacing made *visible* — the player hears the curve bend |
| Game-over state | `enum State { PLAYING, RUN_OVER }` | The two-state skeleton again — this time the second state is "try for a better score" |

### The tick, annotated

```
_take_turn(want_jump, hop):
    want_jump & grounded  → air_left = jump_ticks/hop_ticks  # INPUT applied
    tick += 1; distance += speed                             # score first —
    speed = _current_speed()                                 # then difficulty
    milestone hit? → banner                                  # pacing feedback
    spawn_cd -= 1; spawn? reset from _spawn_gap(kind)        # spawner timer
    each obstacle: x -= speed                                # world scrolls
        on/crossing your column → _adjudicate(kind)          # rock/bird/wall
    run_log += air? 'a' : 'g'                                # ghost records
    air_left -= 1 → 0? touchdown: grace_left = grace_ticks   # timers tick
    report nearest threat + ticks-to-crossing                # feedback
```

Check order matters again: your jump is applied **before** the world
moves, so pressing `j` on the crossing tick still saves you — input first,
physics second, judgement last.

---

## ✅ Test Checklist

**Automated**: `test_main.gd` covers the mechanics below — run `run_tests.bat`
or `godot --headless --script test_main.gd`. It instantiates the game without
a session, which is why the loop lives in `_initialize()`, not `_init()`.

Verify each of these by actually playing:

- [ ] `j` keeps you up `jump_ticks` ticks; `s` keeps you up `hop_ticks`; Enter/`w` runs one tick
- [ ] A rock crossing while grounded (past grace) ends the run; airborne, it passes under
- [ ] Touch down one tick before a rock crosses → **landing grace** skids you over it
- [ ] A bird crossing while airborne ends the run; grounded, it whips overhead
- [ ] A wall kills you grounded *and* off-apex airborne; `j` at countdown `apex_air` or `s` at countdown `hop_ticks - apex_air + 1` crests it
- [ ] `j`/`s` while airborne is rejected — and the world still ticks
- [ ] `^` shows on the air row, `|` marks your column; `(apex)` appears on the Feet line when `air_left` hits the wall value
- [ ] Milestone banners print every `milestone_m` meters
- [ ] The `spawn gap` HUD value shrinks and `speed` climbs as distance grows; walls only spawn past `wall_min_m`
- [ ] Set `run_seed` — two runs produce identical obstacle sequences; clear it for fresh roads
- [ ] After a best run, a faint `p` replays where that run was airborne/grounded — and vanishes when you match it
- [ ] Change a tuning key — the old ghost is ignored (signature mismatch) until you set a new best
- [ ] Death ends the run with a score line; `y` restarts clean from 0 m
- [ ] `quit` mid-run still banks the meters into career stats
- [ ] `min_gap = 2` can't produce impossible pairs — the fairness floor overrides it

---

## 🛠️ Improvement Ideas

The first six were implemented — hop, grace, milestones, walls, seeds,
and the ghost are all in the game now. Fresh ideas, ordered by
difficulty:

1. **Coin line** — spawn `o` pickups between obstacles worth +5 m of
   score; you collect them in whatever state they're on (ground coins
   reward *not* jumping). Reuses the spawner with a fourth `kind`.
2. **Wind gusts** — a rare event adds ±1 to `air_left` mid-jump,
   announced one tick ahead. External forces mutating your timers.
3. **Duck** — a `d` move plus a low-ceiling obstacle `=` on the air row
   that clears only if you're *ducking*. Now "grounded" has two flavors.
4. **Stricter walls** — a `wall_chance` roll that also picks a height:
   taller walls demand `air_left` within a narrower band around the
   apex. The adjudication math is already there.
5. **Ghost race UI** — render the ghost as a second *position* marker
   that drifts ahead when it survived where you died. Needs the ghost's
   tick-aligned log you already record.
6. **Daily seed** — default `run_seed` to today's date (`Time.get_date_string_from_system`)
   so everyone shares one course per day. One line in `_start_run`.

---

## 💭 Reflection

Before moving to Stage 2, be able to answer:

- Why is the spawn gap measured in *cells* but stored as a *tick
  countdown*? What would break if `spawn_cd` were just a fixed tick count?
- The fairness floor for a wall is `jump_ticks + apex_off` ticks of
  crossing spacing — derive why the extra `apex_off` is needed. (Hint:
  where must your feet be when you press `j` for the wall?)
- Swept collision checks "was right of you, now at/left of you". Game 3
  deliberately used landing-only collision. Argue for each in its own
  game — what does each rule do to *feel*?
- The ghost only diverges visually when it disagrees with your current
  state — why is that the *useful* part of a shadow? What would drawing
  it unconditionally obscure?
- Re-seeding happens in `_start_run`, not `_init`. Trace what the RNG
  state looks like on a second `y` run under each choice.
- A bird behind a rock is the classic trap (jump for one, get clipped
  by the other). Add a wall *before* the bird — is the sequence still
  survivable, and which floor rule decides?

Then update `PROGRESS.md` (Game 4 → completed — and Stage 1 done!) and
move on to **Stage 2, Game 5: 2D Clicker** — where position becomes a
*pair* of numbers and the mouse joins the keyboard.
