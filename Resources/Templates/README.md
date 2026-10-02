# Templates

Starter files for new games and documents. **Copy** a template into your
project folder and rename it — never edit the files in this directory
directly (or the next game loses its clean starting point).

| Template | Copy as | When to use |
|----------|---------|-------------|
| `Game-Design-Doc-Template.md` | `DESIGN.md` | The **Plan** step — before writing any code |
| `Game-README-Template.md` | `README.md` | Every finished game (matches the lab's quality checklist) |
| `console-game-template.gd` | `main.gd` | Turn-based terminal games — Stage 0–1 (`extends SceneTree`) |
| `scene-game-template.gd` | `main.gd` | Real-time scene games — Stage 2+ (`extends Node2D`) |
| `renpy-template.rpy` | `game/script.rpy` | Ren'Py visual novels — the VN track |
| `test-main-template.gd` | `test_main.gd` | Automated checks for console games — pairs with `run_tests.bat` |
| `run.bat` | `run.bat` | Any console game — edit the `GODOT` path once |
| `run_tests.bat` | `run_tests.bat` | Any console game with a `test_main.gd` |

---

## 🧭 Which game template?

| If your game... | Use |
|-----------------|-----|
| Reads typed commands, updates on Enter (Number Guessing, 1D Pong) | `console-game-template.gd` |
| Runs live in a window with sprites and `_process` (2D Pong, Snake) | `scene-game-template.gd` |
| Is mostly dialogue and choices | `renpy-template.rpy` |

### Console template (`console-game-template.gd`)

The same skeleton the Stage 1 games are built on:

- `extends SceneTree` + `_initialize` game loop (`input → update → render`)
- stdin guard (won't spin when there's no terminal)
- `settings.cfg` load/create/validate pattern
- Piped-stdin safe input reader (queued lines, EOF → quit)
- ANSI color tones that auto-disable when piped (`NO_COLOR` honored)
- `enum State` + `match` dispatch — extend it like Game 3 did
- All output routes through `_say()` so it survives the screen clear

### Test harness (`test-main-template.gd`)

The same micro-framework every Stage 1 game's `test_main.gd` uses:

- Discovers and runs every `test_*` method alphabetically
- `expect` / `expect_eq` / `expect_near` assertions with labeled failures
- Instantiates the game *without* starting a session (that's why the
  loop lives in `_initialize`, not `_init`), so tests poke the logic
  functions directly — the automated version of the README checklist

### Scene template (`scene-game-template.gd`)

A minimal real-time skeleton for Stage 2+:

- `enum State { MENU, PLAYING, PAUSED, GAME_OVER }` with full transitions
- `_unhandled_input` for menu/pause/restart, `_process` for gameplay
- `Input.get_vector` movement with `delta` and screen-edge clamping
- `draw_circle` placeholder rendering — swap for real sprites
- Works with Godot's default `ui_*` input actions (no Input Map setup)

### Ren'Py template (`renpy-template.rpy`)

- `define` characters, `default` save-safe variables
- `label` flow with `jump`, `menu:` choices that set variables
- Three endings picked by accumulated state — the whole VN trick

---

## 🔁 Workflow reminder

Each game follows the lab's standard process (see `README.md`):

1. **Understand** → 2. **Plan** (`DESIGN.md`) → 3. **Build** (template → MVP)
→ 4. **Learn** → 5. **Practice** → 6. **Test** (checklist) → 7. **Improve**
→ 8. **Reflect** (README + PROGRESS.md)
