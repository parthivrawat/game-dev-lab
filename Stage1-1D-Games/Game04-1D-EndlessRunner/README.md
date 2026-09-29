# Game 4: 1D Endless Runner — Dustline

**Stage 1 — 1D Games** | Difficulty: Medium  
**Concepts**: spawning systems, timers/cooldowns, difficulty curves, game-over states, swept collision, fairness constraints

---

## 🎯 The Game

An endless runner flattened onto a number line. You stand on a fixed
column (`player_cell`) while the road scrolls left on its own — **every
input is one tick of road**, whether you jump or just keep running. Two
things come at you from the right edge:

- **`#` rocks** roll along the ground row. One kills you only if your
  feet are **down** on the tick it crosses your column.
- **`v` birds** fly along the air row. One kills you only if you're
  **airborne** when it crosses — jumping into a bird is the *only* way
  to die to a bird.

That's the whole decision space: **when to leave the ground, and for how
long.** A jump (`j`) keeps you airborne for `jump_ticks` ticks — no
double-jump, no early landing. Press `j` the same tick a rock arrives
and you're already off the ground when it gets there; press it too early
for a bird behind the rock and you're stuck in the air when it crosses.

There is no winning — the run ends when something hits you. The score is
`distance`: meters survived, which is also what drives the **difficulty
curve**:

- **Scroll speed** climbs `speed_growth` per meter, capped at
  `max_speed`. Faster obstacles mean less warning and wider jumps
  (you cover more ground in the same `jump_ticks`).
- **Spawn spacing** shrinks `gap_shrink` per meter toward `min_gap`.
  Denser obstacles mean tighter sequences of jump/don't-jump reads.

One rule keeps the curve honest: the spawn gap is never allowed below
`jump_ticks × speed`. Two crossings closer than one jump's airtime would
be *impossible*, not hard — so the spawner raises the floor itself. Every
pattern the game can produce is survivable; dying is always your read,
not the curve's cheat. Career best distance and totals persist in
`settings.cfg` under `[scores]`.

---

## ⚙️ Configuration: `settings.cfg`

Rules are read from `settings.cfg` at startup. If the file is missing,
the game **creates it with defaults** — run once, edit, rerun.

```ini
[game]
track_length = 24
player_cell = 4
jump_ticks = 3
start_speed = 1.0
speed_growth = 0.02
max_speed = 2.5
start_gap = 9.0
min_gap = 5.0
gap_shrink = 0.03
flyer_chance = 0.25
spawn_delay = 4

[ui]
use_color = true
clear_screen = true
```

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `track_length` | int | `24` | Cells `0` to `track_length - 1`; obstacles spawn at the right edge |
| `player_cell` | int | `4` | Your fixed column — closer to the left = more warning time |
| `jump_ticks` | int | `3` | Ticks one jump keeps you airborne — longer covers more crossings but locks out re-jumps longer |
| `start_speed` | float | `1.0` | Scroll speed in cells/tick at the start of a run |
| `speed_growth` | float | `0.02` | Added to scroll speed per meter run — the "gets faster" knob |
| `max_speed` | float | `2.5` | Hard cap on scroll speed |
| `start_gap` | float | `9.0` | Cells between consecutive spawns at distance 0 |
| `min_gap` | float | `5.0` | The spacing floor the *curve* wants — the fairness floor may raise it further |
| `gap_shrink` | float | `0.03` | Cells the spawn gap loses per meter run — the "gets denser" knob |
| `flyer_chance` | float | `0.25` | Chance each spawn is a bird (stay low) instead of a rock (jump) |
| `spawn_delay` | int | `4` | Ticks of clear track before the first obstacle |
| `use_color` / `clear_screen` | bool | `true` | ANSI colors / redraw the HUD each tick |

Color and screen-clearing are **automatically disabled** when output is
piped or `NO_COLOR` is set. (`FORCE_COLOR=1` overrides for testing.)
**Validation is built in**: absurd values are clamped, and the fairness
floor (`jump_ticks × speed`) always wins over `min_gap`.

Suggested variants: `flyer_chance = 0.5` for a reading-comprehension
nightmare; `jump_ticks = 2` + `min_gap = 4` for twitchier, shorter hops;
`speed_growth = 0` for a flat-speed endurance test where only density
ramps.

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
| `wait` / `w` / `run` / *(just Enter)* | Keep running for one tick |
| `help` / `h` / `?` | Show the move list |
| `quit` / `q` | Step off the trail — meters earned still count |
| `y` / `n` | At run end: go again or exit |

**Every action is one tick** — jumping, waiting, even a wasted
double-jump press. The road never pauses. Between runs the world doesn't
tick: `y` starts fresh from distance 0.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Spawning | `_spawn_obstacle` | The spawner is a *cooldown timer* (`spawn_cd`) reset from a distance gap — spawn logic is "when", not "what" |
| Gap → time | `ceil(_current_gap() / speed)` | Cells between obstacles converted to ticks at current speed — spacing stays constant while density reads as pressure |
| Difficulty curve | `_current_speed`, `_current_gap` | Both are **pure functions of `distance`** — the difficulty is a curve the player can watch in the HUD, not dice rolls behind a screen |
| Fairness floor | `jump_ticks * speed` in `_current_gap` | A constraint the game refuses to violate: patterns that *can't* be survived are never produced. Design rule worth stealing |
| Swept collision | `was > player_cell and now < player_cell` | Game 3's tunneling lesson, applied: at speed > 1 an obstacle can skip your cell between checks — so the check asks "did it occupy the column this tick", not "did it land there" |
| Lingering collision | `now == player_cell` re-checked every tick | At `start_speed < 1` an obstacle can sit on your cell for two ticks — touch down on a rock still under you and it still wins |
| Fixed-duration jump | `air_left` countdown | A jump is a timer, not an arc: set it, adjudicate against it, decrement. Character-controller coyote-time and jump-buffers are this same pattern |
| Symmetric threats | `ob["flyer"] == airborne` | One line adjudicates both obstacle types: a rock wants air, a bird wants ground — the *opposite* of Game 3's symmetric paddles, same trick |
| Entity flags | `"met"` / `"passed"` in the obstacle dict | First-safe-crossing gets the message, first-fall-behind gets the point — minimal per-entity state tracking |
| One status line | `_escalate` + `_tick_tone` | Several events per tick compete for one message color: worst tone wins |
| Game-over state | `enum State { PLAYING, RUN_OVER }` | The two-state skeleton again — this time the second state is "try for a better score", not a rematch |

### The tick, annotated

```
_take_turn(want_jump):
    want_jump & grounded  → air_left = jump_ticks       # INPUT applied
    distance += speed                                   # score first —
    speed = _current_speed()                            # then difficulty
    spawn_cd -= 1; spawn? reset from _current_gap()     # spawner timer
    each obstacle: x -= speed                           # world scrolls
        on/crossing your column → dead or cleared       # adjudication
    air_left -= 1                                       # jump timer
    report nearest threat + ticks-to-crossing           # feedback
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

- [ ] `j` makes you airborne for exactly `jump_ticks` ticks; Enter/`w` runs one tick
- [ ] A rock crossing while you're grounded ends the run; airborne, it passes under and `cleared` goes up
- [ ] A bird crossing while you're airborne ends the run; grounded, it whips overhead
- [ ] `j` while airborne is rejected — and the world still ticks
- [ ] The `^` shows on the air row and `|` marks your column while you're up
- [ ] "Jump window is OPEN" appears when a rock is `jump_ticks` ticks out
- [ ] "Stuck in the air" warns when a bird will arrive before you land
- [ ] The `spawn gap` HUD value shrinks and `speed` climbs as distance grows
- [ ] At high speed an obstacle can jump a cell in one tick — watch it skip, and verify it still can't skip *your* column
- [ ] Two obstacles can arrive back-to-back with only the fairness floor between them — tight but survivable
- [ ] Death ends the run with a score line; `y` restarts clean from 0 m
- [ ] `quit` mid-run still banks the meters into career stats
- [ ] Re-run: `[scores]` in `settings.cfg` shows best distance and total meters
- [ ] `min_gap = 2` can't actually produce impossible pairs — the fairness floor overrides it

---

## 🛠️ Improvement Ideas

Ordered by difficulty — pick one and implement it yourself:

1. **Short-hop** — `s` jumps for `jump_ticks - 1` ticks instead of the
   full hop. Now you choose the *size* of the window, not just when it
   opens. One extra branch in `_update_playing`.
2. **Landing grace** — a one-tick "coyote" buffer: a rock on your column
   the tick after touchdown counts as cleared. Adds a `grace_left`
   timer next to `air_left` — timers everywhere are the same pattern.
3. **Distance milestones** — every 100 m prints a banner ("speed +0.2!")
   and maybe a breather gap. A pure function of `distance`, same trick
   as the curve itself.
4. **Walls and valleys** — a third obstacle type: `H` tall wall must be
   *jumped over only at the apex* (arrives exactly mid-jump). Forces
   planning `jump_ticks` ahead instead of reacting.
5. **Seeded runs** — a `seed` config key passed to `seed()` so the same
   run is replayable for racing a friend. Find where `randomize()` is
   called and make it conditional.
6. **Ghost replay** — record your inputs (`j`/tick index) and replay the
   best run's decisions as a faint `p` marker — your own shadow to beat.

---

## 💭 Reflection

Before moving to Stage 2, be able to answer:

- Why is the spawn gap measured in *cells* but stored as a *tick
  countdown*? What would break if `spawn_cd` were just a fixed tick count?
- The fairness floor is `jump_ticks * speed` — derive it from the
  crossing-tick spacing. What pattern would `min_gap = 2` allow at speed
  2.5, and why is it unsurvivable?
- Swept collision checks "was right of you, now at/left of you". Game 3
  deliberately used landing-only collision. Argue for each in its own
  game — what does each rule do to *feel*?
- Both difficulty knobs are pure functions of `distance`. What changes —
  for the player and for debugging — if they were functions of `time`
  or dice rolls instead?
- A bird behind a rock is the only trap the game can spring (jump for
  one, get clipped by the other). What does `flyer_chance` need to be
  for that trap to dominate — and why does the fairness floor still
  keep it survivable?

Then update `PROGRESS.md` (Game 4 → completed — and Stage 1 done!) and
move on to **Stage 2, Game 5: 2D Clicker** — where position becomes a
*pair* of numbers and the mouse joins the keyboard.
