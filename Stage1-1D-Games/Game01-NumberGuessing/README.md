# Game 1: Number Guessing

**Stage 1 — 1D Games** | Difficulty: Very Easy  
**Concepts**: variables, random numbers, conditions, loops, user input, enum game states, config files, CLI args, persistence

---

## 🎯 The Game

Two modes:

- **Normal** — the computer picks a number in the configured range
  (default 1–100). You have limited attempts (default **7**) — after each
  guess you hear "higher"/"lower" plus a temperature hint (freezing → cool →
  warm → hot → blazing!). Win it, and your best score for that difficulty
  **persists between sessions**.
- **Reverse** — *you* think of a number; the computer hunts it with binary
  search. Answer `(h)igher`, `(l)ower`, `(c)orrect` and watch the search
  window shrink each guess. Answer inconsistently and it calls you out.

### Why 7 attempts?

`7 = ceil(log2(101))` — the worst-case depth of the binary-search decision
tree. (Strictly it's `ceil(log2(N+1))`: range 2 needs 2 guesses, range 4
needs 3.) If you guess the middle of the remaining range each time
(50 → 75 → 88 → …), you **always** win. Play **reverse mode** and the game
does it for you — watch it.

---

## ⚙️ Configuration: `settings.cfg`

Read at startup; created with defaults if missing.

```ini
[game]
min_number = 1
max_number = 100
max_attempts = 7
proximity_hints = true
mode = "normal"        # normal | reverse
difficulty = "custom"  # custom | easy | normal | hard

[difficulty]
easy_min = 1
easy_max = 50
easy_attempts = 7
normal_min = 1
normal_max = 100
normal_attempts = 7
hard_min = 1
hard_max = 500
hard_attempts = 10
```

| Key | Effect |
|-----|--------|
| `mode` | `normal` = you guess · `reverse` = computer guesses |
| `difficulty` | `custom` uses the `[game]` values · a preset name overrides them from the `[difficulty]` table |
| `min_number`/`max_number`/`max_attempts` | The custom-mode rules (swapped if reversed, attempts clamped ≥ 1) |
| `proximity_hints` | Temperature words after each wrong guess |
| `use_color` / `clear_screen` | ANSI colors + HUD redraw (auto-off when piped or `NO_COLOR`; `FORCE_COLOR=1` for tests) |

**Command-line overrides** beat the config for one run — everything after
`--` is parsed by `OS.get_cmdline_user_args()`:

```cmd
godot --headless --script main.gd -- --difficulty hard --attempts 5
godot --headless --script main.gd -- --mode reverse --max 1000
godot --headless --script main.gd -- --no-hints
```

`--difficulty` applies *before* numeric overrides, so
`--difficulty hard --attempts 5` means "hard preset, but only 5 tries".

**Persistent bests**: winning a round writes `[scores] best_<difficulty>` to
`settings.cfg` — check the file after a win. Caveat: `ConfigFile.save()`
rewrites the whole file, so hand-written comments in it are not preserved.

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

> ⚠️ **Do NOT run it from the Godot editor** — the script runner only supports
> `@tool`/`EditorScript` scripts; this game `extends SceneTree` and needs a
> real terminal for stdin.

## 🎮 Commands

| Input | Effect |
|-------|--------|
| `min_number`–`max_number` | Normal mode: make a guess |
| `h` / `l` / `c` | Reverse mode: your number is higher / lower / correct |
| `quit` / `q` | Give up mid-round |
| `y` / `n` | At round end: play again or exit |

Invalid input (non-numbers, out-of-range, wrong letters) is caught and costs
nothing.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Game loop | `_init` | Same `input → update → render` skeleton as Stage 0 — it really is *the* pattern |
| `enum` state machine | `State`, `_update` | `match state:` dispatches to a per-state handler — and PLAYING now dispatches *again* on `mode`. Two axes of state, still readable |
| Config files | `_load_config` → `ConfigFile` | `get_value(section, key, default)` per key — presets are just a section whose keys get read into a Dictionary |
| **Dictionaries** | `presets`, `best_scores` | First look at `{key: value}` — a difficulty table and a score table, both read/written as data |
| Config validation | `_validate_config` | Swap reversed bounds, clamp attempts, fall back on unknown `mode`/`difficulty` |
| **CLI overrides** | `_parse_cli_overrides` | `OS.get_cmdline_user_args()` — args after `--`. Two passes so `--difficulty` lands before `--attempts` can override it |
| **Binary search, run by the computer** | `_reverse_guess`, `_update_reverse` | `guess = (lo + hi) / 2`, then shrink the window — plus contradiction detection when `lo > hi` |
| **Writing files** | `_save_scores` | `ConfigFile` writes as easily as it reads — the skeleton of every save system |
| Temperature hints | `_update_guessing` | Graded `if/elif` ladder on `absi(guess - secret)` |
| Persistent vs session state | `best_scores` vs `attempts_used` | One survives process restarts, one resets per round — three lifetimes in one file |

### The game loop, annotated

```
_init:
    load config → apply CLI overrides → intro → start round
    while game_running:          # session loop
        _read_input()            # INPUT    — "what did the player type?"
        _update(input)           # UPDATE   — "what does it change?"
        _render()                # RENDER   — "what does the player see?"
    save scores → outro → quit
```

---

## ✅ Implemented Improvements

All five ideas from the original list are in:

- [x] **Difficulty presets** — `difficulty = easy|normal|hard` in
  `settings.cfg` swaps in a preset row; `custom` (default) keeps `[game]` keys
- [x] **Temperature words** — freezing / cool / warm / hot / blazing tiers
  behind `proximity_hints`
- [x] **CLI overrides** — `--min --max --attempts --mode --difficulty
  --no-hints` parsed from `OS.get_cmdline_user_args()`
- [x] **Reverse mode** — computer guesses via binary search with a visible
  shrinking window and fib detection
- [x] **Persistent best score** — `[scores] best_<difficulty>` saved to
  `settings.cfg` on exit

## 🛠️ New Modification Ideas

1. **Timer mode** — score by seconds instead of attempts
   (`Time.get_ticks_msec()` at round start/end).
2. **Two-player mode** — a human types the secret first (hot-seat).
3. **Lie budget** — reverse mode where the player may fib *once* — how does
   the computer detect-and-recover?
4. **Adaptive temperature** — scale the hint thresholds to the range so
   `1-500` doesn't freeze at distance 40.
5. **Score history** — keep a per-difficulty *list* of attempt counts and
   show a mini chart in the outro.

---

## ✅ Test Checklist

Verify each of these by actually playing:

- [ ] A correct guess wins and reports attempt count
- [ ] Wrong guesses say "Higher!"/"Lower!" with the right temperature word
- [ ] `abc` or out-of-range input shows an error and costs nothing
- [ ] `y`/`n` replay works; `quit` mid-round reveals the number
- [ ] `--attempts 3` (or any `--` flag) applies for one run only — restart shows the cfg value again
- [ ] `difficulty = "hard"` in cfg → next run uses 1–500 / 10 attempts
- [ ] Reverse mode: honest answers always get found in ≤ optimal attempts
- [ ] Reverse mode: contradicting yourself gets the "fibbed" message
- [ ] After any win, `settings.cfg` gains `[scores] best_*` and the outro lists it
- [ ] Editing `settings.cfg` still changes the rules next run

Then update `PROGRESS.md` (Game 1 → completed) and move on to
**Game 2: 1D Catch the Target** — where the number line becomes a real game board.
