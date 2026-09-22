# Game 1: Number Guessing

**Stage 1 — 1D Games** | Difficulty: Very Easy  
**Concepts**: variables, random numbers, conditions, loops, user input, enum game states

---

## 🎯 The Game

The computer picks a number in a configurable range (default 1–100). You have
a configurable number of attempts (default **7**) to find it — after each
guess you're told "higher" or "lower", plus a proximity hint when you're
close. Guess it in time and you win the round; run out of attempts and the
number is revealed. Then you can play again — your best score (fewest
attempts) is tracked across rounds.

### Why 7 attempts?

`7 = ceil(log2(101))` — the worst-case depth of the binary-search decision
tree. (Strictly it's `ceil(log2(N+1))`: range 2 needs 2 guesses, range 4
needs 3.) If you guess the middle of the remaining range each time
(50 → 75 → 88 → …), you **always** win. This is binary search — the first
algorithm that shows up in real game code (and interviews). Try it!

---

## ⚙️ Configuration: `settings.cfg`

Game rules are read from `settings.cfg` at startup. If the file is missing,
the game **creates it with defaults** — so just run once, edit, rerun.

```ini
[game]
min_number = 1
max_number = 100
max_attempts = 7
proximity_hints = true

[ui]
use_color = true
clear_screen = true
```

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `min_number` | int | `1` | Lowest possible secret |
| `max_number` | int | `100` | Highest possible secret |
| `max_attempts` | int | `7` | Guesses per round (clamped to ≥ 1) |
| `proximity_hints` | bool | `true` | Show "(very close!)/(close)" feedback |
| `use_color` | bool | `true` | ANSI colors in output |
| `clear_screen` | bool | `true` | Redraw a fixed HUD each turn |

Color and screen-clearing are **automatically disabled** when output is piped
or `NO_COLOR` is set — the game behaves like a proper CLI tool.
(`FORCE_COLOR=1` overrides for testing.)

**Validation is built in**: if `min_number > max_number` they're swapped;
if `max_attempts` is below the binary-search optimum for your range, the
intro warns you the game is unwinnable — set `max_number = 1000` and
`max_attempts = 5` to see it.

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
| `min_number`–`max_number` | Make a guess (default range: 1–100) |
| `quit` / `q` | Give up (reveals the number) |
| `y` / `n` | At round end: play again or exit |

Invalid input (non-numbers, out-of-range values) is caught and doesn't consume
an attempt.

---

## 🔍 Code Tour — What This Game Teaches

| Concept | Where | What to notice |
|---------|-------|----------------|
| Game loop | `_init` | Same `input → update → render` skeleton as Stage 0 — it really is *the* pattern |
| `enum` state machine | `State`, `_update` | Replaces Stage 0's bool flags — `match state:` dispatches to a per-state handler. Two states now; this scales to menus, pause, etc. |
| Random numbers | `_start_round` → `randi_range()` | One call, one line — Godot's global RNG |
| Config files | `_load_config` → `ConfigFile` | Godot's INI handler — `get_value(section, key, default)`, `set_value`, `save`. The same class real games use for settings and saves |
| Config validation | `_validate_config`, `_optimal_attempts` | Never trust a file the user can edit — swap reversed bounds, clamp attempts, warn on unwinnable configs |
| Terminal UI | `_detect_terminal`, `_c`, `_tone`, `_clear_screen` | ANSI colors + clear-screen HUD, auto-disabled when piped or `NO_COLOR` is set — how real CLI tools behave |
| Input validation | `_update_playing` | `is_valid_int()` + range check *before* the guess counts — bad input never costs an attempt |
| Conditions | `higher/lower`, proximity hint | Layered `if`/`elif` — win check, attempts check, then graded feedback |
| Loops | `while game_running` | The whole session is one loop; rounds restart via `_start_round()` |
| Persistent state | `best_attempts`, `rounds_won` | Member vars survive across rounds — unlike the per-round `secret`/`attempts_used` which reset in `_start_round()` |
| EOF safety | `_read_input` | Returns `"quit"` on piped-stdin EOF — same guard as Stage 0 |

### The game loop, annotated

```
_init:
    intro → start round
    while game_running:          # session loop
        _read_input()            # INPUT    — "what did the player type?"
        _update(input)           # UPDATE   — "what does it change?"
        _render()                # RENDER   — "what does the player see?"
    outro → quit
```

Every real game you'll build keeps this skeleton — only the internals grow.

---

## ✅ Test Checklist

Verify each of these by actually playing:

- [ ] A correct guess wins the round and reports attempt count
- [ ] Wrong guesses say "Higher!" or "Lower!" correctly
- [ ] Guesses within 5 of the secret show "(very close!)"
- [ ] Attempt counter decrements only on valid in-range guesses
- [ ] Typing `abc` or `150` shows an error and costs nothing
- [ ] After 7 wrong guesses: round lost, number revealed
- [ ] `y` starts a fresh round with a new secret; `n` exits cleanly
- [ ] Winning twice shows "Best: N attempts" improving
- [ ] `quit` mid-round reveals the number and exits
- [ ] Binary search strategy (50, 75, 88…) always wins — prove it!
- [ ] Editing `settings.cfg` changes the range/attempts next run
- [ ] `min_number > max_number` in the cfg gets auto-corrected
- [ ] `max_attempts = 3` with default range shows the unwinnable warning
- [ ] `proximity_hints = false` removes the "(very close!)" hints
- [ ] Deleting `settings.cfg` regenerates it on next run

---

## 🛠️ Improvement Ideas

Ordered by difficulty — pick one and implement it yourself:

1. **Difficulty presets** — add a `[difficulty]` section to settings.cfg
   (easy/normal/hard) that sets range + attempts in one line.
2. **Temperature words** — more proximity tiers ("freezing/warm/hot") behind
   `proximity_hints`, or make the thresholds configurable too.
3. **CLI overrides** — read `OS.get_cmdline_user_args()` so
   `-- --attempts 3` overrides the cfg for one run.
4. **Reverse mode** — *you* pick a number, the computer guesses with binary
   search. This is the payoff for understanding the algorithm.
5. **Persistent best score** — save `best_attempts` into `settings.cfg`
   (ConfigFile can write!) so it survives between runs.

---

## 💭 Reflection

Before moving to Game 2, be able to answer:

- Why does invalid input get rejected *before* `attempts_used += 1`?
- What breaks if `_start_round` forgot to reset `attempts_used`?
- Why is `best_attempts` a member variable but `secret` resets each round?
- How would the enum state machine grow if you added a SETTINGS state?

Then update `PROGRESS.md` (Game 1 → completed) and move on to
**Game 2: 1D Catch the Target** — where the number line becomes a real game board.
