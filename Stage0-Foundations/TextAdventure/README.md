# Dungeon Corridor — Stage 0 Deliverable

A complete 1D text adventure in ~510 lines of GDScript. Every concept from
Stage 0 lives in this file — the point is that you can hold the whole game in
your head.

**Each delve generates a random corridor** (10–16 cells, +4 per depth) — and
you spawn in the **middle**, not at an end:

- The exit `E` is at a random end; the opposite end is a **gold vault**
- A gate goblin `M` always guards the exit route; a second sometimes guards
  the vault — and **deeper delves add extra hunters**
- The sword `s` always spawns in your **reachable zone** — cells you can walk
  to without crossing a living goblin
- Potions `p` heal 10 HP (one per delve, more deeper down)

Every map is **completable by construction** — you can always reach the sword
first, then every goblin goes down in one sword hit at a cost of 2 HP each
(you have 20). But there's a catch: **goblins chase you**, one cell per tick,
and claw you when adjacent. Bait them off their posts, or fight through.

**Escape and you descend**: each successful delve takes you one depth deeper —
longer corridor, more goblins, more potions. Dying or fleeing sends you back
to depth 1. How deep can you get?

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

## 🎮 How to Play

You spawn mid-corridor. The exit `E` is at one end (check the map), gold
piles wait at the other end and scattered about. Find the `s`word first —
it's always somewhere you can reach without a fight — then slay the goblins
`M` blocking your way and escape.

**The goblins hunt you**: every move you make, every goblin steps one cell
toward you — and claws you when it gets adjacent. They move at your speed,
so they can't catch a player who keeps moving — but they block paths, and
standing still lets them close in.

| Command | Effect |
|---------|--------|
| `left` / `l` | Move one cell left ⏱️ |
| `right` / `r` | Move one cell right ⏱️ |
| `wait` / `w` / *(Enter)* | Hold still — goblins keep coming ⏱️ |
| `attack` / `a` | Attack an adjacent goblin ⏱️ |
| `look` | Describe what's nearby — **free** |
| `map` | Show the cell legend — **free** |
| `status` | Show HP, gold, position, depth — **free** |
| `help` | Command list — **free** |
| `quit` / `q` | Leave the dungeon |

⏱️ = passes time: goblins chase, the turn counter ticks. Everything else is
free — scout as much as you like.

**Win**: reach the `E` cell → descend to a deeper corridor. **Lose**: HP hits
0 → back to depth 1. **Quit**: abandon the delve → back to depth 1.

---

## 🔍 Code Tour — Where Each Concept Lives

| Concept | Where | What to notice |
|---------|-------|----------------|
| Game loop (Theory 01) | `_init` | Literal `input → update → render` in a `while` |
| Game state | Top-of-file `var`s | The whole world is ~10 variables |
| **Enum state machine (D4)** | `State`, `_update`, `_print_round_result` | `PLAYING/WON/LOST/QUIT` — one variable replaces the old `won`/`game_running` flags, `match` on it at round end |
| Constants (L1) | `const` block | Rules as data — damage, heals, corridor growth, caps |
| Random generation | `_generate_map` | Random exit end, mid-third spawn, gate + vault + hunter goblins |
| **Depth scaling (D5)** | `_generate_map`, `_print_round_result` | `depth` grows on escape: `+CORRIDOR_GROWTH` cells and a hunter per depth, capped so the map still fits |
| Reachability | `_reachable_cells` | Walk both directions, stop at goblins — the sword is always reachable **at spawn** (chasers may cut you off later — that's the pressure, and it's why the guarantee is "reachable now") |
| Constraint solving | `_free_cells`, `_random_lair_cell` | Collect valid cells before picking — the simplest "don't overlap" pattern, now also used for hunter lairs |
| **Chasing AI (D3)** | `_chase_monsters` | `step = pos + signi(player_pos - pos)` — one line of pursuit logic; claw when adjacent, don't stack on other goblins |
| **Action ticks vs free commands** | `_update`, `_world_tick` | Only `l`/`r`/`w`/`attack` advance the world — look/status/map/help cost nothing. With a chase on, that's a fairness rule, not just bookkeeping |
| **Potions (D1)** | `_resolve_cell`, `_free_cells`, `_print_hud` | Mirrors the gold pickup — add the spawn, the exclusion, the pickup, the map symbol |
| **Wait command (D2+)** | `_update` | Holding still is a real action now — it costs a tick, and sometimes that's the right play |
| Match (L1) | `_update` | Command parsing with aliases (`"left", "l"`) |
| Arrays (L1) | `_print_hud`, `monsters`, `potions` | Corridor built as an array of cell symbols; entity positions as int arrays |
| Functions (L2) | Everywhere | Each phase/verb is its own small function |
| 1D coordinates (L3) | `player_pos`, `_try_move`, `_chase_monsters` | Direction `±1`, bounds check, `absi()` distance, `signi()` pursuit step |
| Terminal UI | `_detect_terminal`, `_c`, `_tone`, `_clear_screen` | ANSI colors + clear-screen HUD; auto-disabled when piped or `NO_COLOR` is set |

---

## ✅ Implemented Modifications

All of `../Exercises.md` Part D is in the game now:

- [x] **D1** — Potion `p` cells heal 10 HP (spawned via `_free_cells`, clamped
  to `START_HEALTH`)
- [x] **D2** — `map` command reprints the cell legend (mostly useful in
  scrollback mode)
- [x] **D3** — Goblins chase the player one cell per action tick and claw
  when adjacent. *Does the reachable-sword rule still guarantee completable
  maps?* — it guarantees the sword is reachable **at spawn**; chasers can
  still intercept you on the way. The new rule of thumb: grab the sword
  early, bait goblins off the route you need.
- [x] **D4** — `enum State { PLAYING, WON, LOST, QUIT }` replaced the
  `won`/`game_running` flags; `_print_round_result` matches on it
- [x] **D5** — Winning descends to a longer corridor with extra goblins
  (depth counter, growth + hunter caps, session "deepest" score)

## 🛠️ New Modification Ideas

The game changed — so did the exercise list:

1. **Guard goblins** — give vault goblins a `guard_pos` they won't leave
   (chase only within N cells of it). Two AI behaviors in one array — how
   do you tell them apart? (Struct per goblin, or two arrays?)
2. **Torch light** — only render cells within 3 of the player; everything
   else shows `?`. One line in `_print_hud`, huge atmosphere change.
3. **Goblin HP** — goblins take two sword hits. `monsters` becomes an array
   of dictionaries — your first real data structure upgrade.
4. **Fleeing potion** — the potion scoots away once when you step next to
   it (borrow the Game02 dodge rule). Silly, but it teaches rule reuse.
5. **High score file** — save `best_depth`/`total_gold` into a
   `settings.cfg`-style `ConfigFile` (Game01 already writes one — crib it).

See `../Exercises.md` Part D for the original list and solution guidance.

---

## ✅ When You're Done

Tick the deliverable box in `../../PROGRESS.md` (Stage 0 → "Simple text-based
interactive program") and record anything you built yourself in the
**Independent Implementations** table.
