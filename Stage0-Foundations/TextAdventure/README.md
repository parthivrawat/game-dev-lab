# Dungeon Corridor — Stage 0 Deliverable

A complete 1D text adventure in ~360 lines of GDScript. Every concept from
Stage 0 lives in this file — the point is that you can hold the whole game in
your head.

**Each delve generates a random corridor** (10–16 cells) — and you spawn in
the **middle**, not at an end:

- The exit `E` is at a random end; the opposite end is a **gold vault**
- 1–2 goblins `M` block paths — one always guards the exit route, and a
  second sometimes guards the vault
- The sword `s` always spawns in your **reachable zone** — cells you can walk
  to without crossing a living monster

Every map is **guaranteed completable** by construction: you can always reach
the sword first, then every goblin is killable (2 HP each vs your 20 HP).
After each delve you can play again on a fresh map — escapes are tracked per
session.

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

| Command | Effect |
|---------|--------|
| `left` / `l` | Move one cell left |
| `right` / `r` | Move one cell right |
| `attack` / `a` | Attack (works when adjacent to the monster) |
| `look` | Describe what's nearby |
| `status` | Show HP, gold, position |
| `help` | Command list |
| `quit` / `q` | Leave the dungeon |

**Win**: reach the `E` cell (whichever end the generator picked). **Lose**:
HP hits 0 (fighting bare-handed hurts).

---

## 🔍 Code Tour — Where Each Concept Lives

| Concept (lesson) | Where | What to notice |
|------------------|-------|----------------|
| Game loop (Theory 01) | `_init` | Literal `input → update → render` in a `while` |
| Game state | Top-of-file `var`s | The whole world is 8 variables |
| Constants (L1) | `const` block | Rules as data — damage, health, corridor size range |
| Random generation | `_generate_map` | Random exit end, mid-third spawn, gate + vault monsters |
| Reachability | `_reachable_cells` | Walk both directions, stop at monsters — the completeness guarantee |
| Constraint solving | `_free_cells` | Collecting valid cells before picking — the simplest "don't overlap" pattern |
| Match (L1) | `_update` | Command parsing with aliases (`"left", "l"`) |
| Arrays (L1) | `_render` | Corridor built as an array of cell symbols |
| Functions (L2) | Everywhere | Each phase/verb is its own small function |
| Member vs local (L2) | `target` in `_try_move` | Local computed value vs. persistent member state |
| 1D coordinates (L3) | `player_pos`, `_try_move`, `_describe_cell` | Direction `±1`, bounds check, `absi()` distance |
| Terminal UI | `_detect_terminal`, `_c`, `_tone`, `_clear_screen` | ANSI colors + clear-screen HUD; auto-disabled when piped or `NO_COLOR` is set |
| Game states (L3) | `game_running` / `won` | Simple 2-state version; exercise D4 upgrades it |

---

## 🛠️ Suggested Modifications

Do these in order — each one teaches something:

1. **Tweak the generator** — change `MIN_CORRIDOR`/`MAX_CORRIDOR` or
   `VAULT_MONSTER_CHANCE` and play a few delves to feel the difference.
2. **Add a potion** — a `p` cell that heals 10 HP (mirrors the gold pickup;
   add it to `_free_cells` exclusion).
3. **Three monsters** — allow a second gate monster. Does the sword rule
   still guarantee completable maps? (Yes — why?)
4. **Make monsters chase you** — each turn they move one cell toward the
   player. Now generation constraints change — think about why.
5. **Upgrade the state machine** — replace `won`/`game_running` with
   `enum State { PLAYING, WON, LOST, QUIT }`.

See `../Exercises.md` Part D for the full list including solutions guidance.

---

## ✅ When You're Done

Tick the deliverable box in `../../PROGRESS.md` (Stage 0 → "Simple text-based
interactive program") and record anything you built yourself in the
**Independent Implementations** table.
