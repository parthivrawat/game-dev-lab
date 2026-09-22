# Dungeon Corridor — Stage 0 Deliverable

A complete 1D text adventure in ~190 lines of GDScript. Every concept from
Stage 0 lives in this file — the point is that you can hold the whole game in
your head.

---

## ▶️ How to Run

**Easiest**: double-click `run.bat` in this folder (it already points at
`E:\Godot_v4.7.2-stable_win64_console.exe`).

Or from cmd/terminal:

```cmd
cd E:\Games\Custom\GameDevLab\Stage0-Foundations\TextAdventure
E:\Godot_v4.7.2-stable_win64_console.exe --headless --script main.gd
```

Use the **console** Godot build (`*_console.exe`) — the regular
`Godot_v4.x_win64.exe` detaches from the console on Windows and can't do
interactive stdin.

> ⚠️ **Do NOT run it from the Godot editor** (Script Editor → Run). The editor's
> script runner only supports `@tool`/`EditorScript` utility scripts and will
> fail with "doesn't extend EditorScript". Our game `extends SceneTree` — it's
> the whole engine main loop — and needs a real terminal for stdin anyway.

## 🎮 How to Play

You're at cell `0` of a 10-cell corridor. The exit `E` is at cell `9`, guarded
by a goblin `M` at cell `8`. Find the `s`word, grab the `g`old on the way,
fight the goblin, escape.

| Command | Effect |
|---------|--------|
| `left` / `l` | Move one cell left |
| `right` / `r` | Move one cell right |
| `attack` / `a` | Attack (works when adjacent to the monster) |
| `look` | Describe what's nearby |
| `status` | Show HP, gold, position |
| `help` | Command list |
| `quit` / `q` | Leave the dungeon |

**Win**: reach cell 9. **Lose**: HP hits 0 (fighting bare-handed hurts).

---

## 🔍 Code Tour — Where Each Concept Lives

| Concept (lesson) | Where | What to notice |
|------------------|-------|----------------|
| Game loop (Theory 01) | `_init` | Literal `input → update → render` in a `while` |
| Game state | Top-of-file `var`s | The whole world is 8 variables |
| Constants (L1) | `const` block | World layout as data — move the monster by editing one line |
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

1. **Move things around** — change `SWORD_POS`/`GOLD_POS`/`MONSTER_POS`.
   Notice the world is *data*, not code.
2. **Add a potion** at cell 5 that heals 10 HP (mirrors the gold pickup).
3. **Add a `map` command** that re-renders (easy — good warm-up).
4. **Make the monster chase you** — each turn it moves one cell toward the
   player. You now have a real enemy and real tension.
5. **Upgrade the state machine** — replace `won`/`game_running` with
   `enum State { PLAYING, WON, LOST, QUIT }`.

See `../Exercises.md` Part D for the full list including solutions guidance.

---

## ✅ When You're Done

Tick the deliverable box in `../../PROGRESS.md` (Stage 0 → "Simple text-based
interactive program") and record anything you built yourself in the
**Independent Implementations** table.
