# Game 2: 1D Catch — Catch the Firefly

**Stage 1 — 1D Games** | Difficulty: Easy  
**Concepts**: 1D position, movement, boundaries, distance, turn-based ticks, a first "AI" that reacts to the player

---

## 🎯 The Game

A firefly drifts back and forth along a track of cells (default **20**),
bouncing off the walls. You are `P`; the firefly is `<` or `>` — its symbol
is also its drift direction. Each turn you move one cell left, one cell
right, or hold still.

The catch (literally): **it darts one cell away whenever you end up next to
it.** In the open it's uncatchable — the only place it can't dodge is
against a wall. Pin it, then step onto its cell. You have `max_turns` ticks
(default **40**) before it slips away for good. Rounds repeat; your best
(fewest-turns) catch is tracked across the session.

### Is every round winnable?

Yes — by construction. Once you're adjacent, each of your moves keeps you
adjacent and forces it one cell toward the wall it's fleeing to. After at
most `track_length - 1` dodges it has nowhere to run, and one more step
lands on it. The budget is generous on purpose: **the real game is catching
it fast** — your score is turns used, and "just chase it" is never the
fastest line. Read the drift, approach from the right side, choose the
nearer wall.

This is also the first design lesson hiding in the code: a rule as small as
"if adjacent → move away" turns a drifting sprite into something that feels
like prey. That's the seed of game AI.

---

## ⚙️ Configuration: `settings.cfg`

Game rules are read from `settings.cfg` at startup. If the file is missing,
the game **creates it with defaults** — so just run once, edit, rerun.

```ini
[game]
track_length = 20
max_turns = 40
min_spawn_distance = 4

[ui]
use_color = true
clear_screen = true
```

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `track_length` | int | `20` | Number of cells, `0` to `track_length - 1` (clamped to ≥ 3) |
| `max_turns` | int | `40` | Turn budget per round — lower it for real pressure |
| `min_spawn_distance` | int | `4` | How far from you the firefly can spawn (clamped to 2..`track_length-1`) |
| `use_color` | bool | `true` | ANSI colors in output |
| `clear_screen` | bool | `true` | Redraw a fixed HUD each turn |

Color and screen-clearing are **automatically disabled** when output is piped
or `NO_COLOR` is set — the game behaves like a proper CLI tool.
(`FORCE_COLOR=1` overrides for testing.)

**Validation is built in**: absurd values are clamped rather than trusted.
Try `track_length = 5` and `max_turns = 8` for a knife-fight version — or
`track_length = 60` to feel how the wall distance changes the game.

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

> ⚠️ **Do NOT run it from the Godot editor** (Script Editor → Run). The editor's
> script runner only supports `@tool`/`EditorScript` utility scripts and will
> fail with "doesn't extend EditorScript". Our game `extends SceneTree` — it's
> the whole engine main loop — and needs a real terminal for stdin anyway.

## 🎮 Commands

| Input | Effect |
|-------|--------|
| `left` / `l` | Move one cell left |
| `right` / `r` | Move one cell right |
| `wait` / `w` / *(just Enter)* | Hold still for a tick |
| `help` / `h` / `?` | Show the move list |
| `quit` / `q` | Give up the chase (reveals its position) |
| `y` / `n` | At round end: chase again or exit |

**Waiting and wall-bumps still cost a turn** — the world ticks whether or not
your move succeeds. Only invalid input (typos, unknown commands) is free.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Game loop | `_init` | Same `input → update → render` skeleton as Game 1 — three games in, it's always this shape |
| Position | `player_pos`, `target_pos` | The entire world is two integers on a number line |
| Direction / proto-velocity | `target_dir` | `+1`/`-1` is a 1D velocity — `pos += dir` per tick is exactly what `_process(delta)` will do in Game 3 |
| Boundaries (reject) | `_take_turn` | Player move is bounds-checked *before* applying — invalid move = stay put |
| Boundaries (bounce) | `_take_turn` | The firefly's wall-hit clamps the position **and** flips `target_dir` — two ops, one event |
| Boundaries as mechanics | the dodge branch | The pin rule *is* the game: the wall deletes the firefly's escape cell. Level design via geometry |
| Distance | `absi(target_pos - player_pos)` | One expression drives the dodge trigger, the HUD readout, and the closing/pulling-away trend |
| Adjacency | `absi(...) == 1` | "Next to" is just distance 1 — grid games run on this check |
| Reactive AI | the dodge branch | `signi(target_pos - player_pos)` picks the flee direction — an entity that reads player state |
| Tick uniformity | `_take_turn` | Every accepted input is one tick, including `wait` and wall-bumps — the world doesn't pause for you |
| `enum` state machine | `State`, `_update` | Same two-state PLAYING/ROUND_OVER skeleton as Game 1 — reuse is the point |
| Spawn constraints | `_start_round` | Collect valid cells, pick one — with a fallback when the config leaves none |
| Config validation | `_validate_config` | `clampi` instead of trust — `min_spawn_distance ≥ 2` also prevents adjacent spawns |
| Turn budget | `turns_used`, `max_turns` | A countdown is the lose condition — same slot as Game 1's attempt counter |

### The tick, annotated

```
_take_turn(direction):
    turns_used += 1                    # every action is one tick
    player moves (bounds-rejected)     # INPUT applied to state
    player_pos == target_pos? → WIN    # landing on it — only possible if pinned
    adjacent? → dodge or pinned        # the firefly reacts to you
    else → drift one cell, bounce      # the world moves on its own
    turns_used >= max_turns? → LOSE    # the budget is the clock
    report distance + trend            # feedback for next decision
```

Note where the win check sits: *after* your move, *before* its dodge. You can
only land on it when last tick left it pinned — which is why cornering is the
whole game.

---

## ✅ Test Checklist

Verify each of these by actually playing:

- [ ] `l`/`r` move you one cell; `w`/Enter holds you still
- [ ] Moving into a wall says "A wall stops you." — and **still costs a turn**
- [ ] Typing `xyz` warns you and does **not** advance the firefly
- [ ] Getting adjacent makes it dart away — watch the `<`/`>` flip
- [ ] Driving it to a wall prints "pinned against the wall — nowhere to run!"
- [ ] Stepping onto a pinned firefly wins the round and shows turn count
- [ ] Letting it drift adjacent to a *waiting* you still triggers the dodge
- [ ] 40 turns without a catch: "Out of time" — escape counted, not a catch
- [ ] `y` spawns a fresh firefly (never adjacent, never on you); `n` exits
- [ ] Catching twice shows "Best: N turns" improving
- [ ] `quit` mid-round reveals its position and exits cleanly
- [ ] The distance readout always matches counting cells on the map
- [ ] `max_turns = 8` in `settings.cfg` makes the round genuinely tense
- [ ] Deleting `settings.cfg` regenerates it on next run
- [ ] Prove it's always winnable: herd it to either wall every round

---

## 🛠️ Improvement Ideas

Ordered by difficulty — pick one and implement it yourself:

1. **Dodge stamina** — it can only dodge `max_dodges` times in a row before
   it must "rest" a tick (catchable mid-track!). One counter, one extra `if`,
   and suddenly herding has a timing element.
2. **Dash** — accept `l2`/`r3` style input (`input.trim_prefix("l").to_int()`)
   to move several cells in one tick. Now you can outrun the dodge — how does
   that change the balance?
3. **Wrap-around track** — cell `track_length` wraps to `0`. No walls at
   all… so how can it ever be caught? (Think before coding — this mod
   *breaks* the game unless you also add a new mechanic. That's the lesson.)
4. **Two fireflies** — catch either one. Positions become an `Array`; the
   dodge rule now needs "which one is adjacent". First taste of managing
   multiple entities — previews Game 3 and 4.
5. **Persistent best score** — save `best_turns` into `settings.cfg`
   (`ConfigFile.save()` works — Game 1 already writes the file).

---

## 💭 Reflection

Before moving to Game 3, be able to answer:

- Why is the win check placed *between* your move and the firefly's dodge?
- Trace `target_dir` through a bounce and a dodge — what does it mean in each
  case, and why does updating it on a dodge matter for the next tick?
- Why does a wall-bump or a `wait` still cost a turn? What breaks if
  `turns_used += 1` only runs on successful moves?
- The dodge check is `absi(...) == 1` — why `== 1` and not `<= 1`?
- This firefly "dodges" without any memory or planning — just one `if`.
  What would you add to make it feel smarter?

Then update `PROGRESS.md` (Game 2 → completed) and move on to
**Game 3: 1D Pong** — where `target_dir` grows up into real velocity, and the
bounce you met here becomes the core mechanic.
