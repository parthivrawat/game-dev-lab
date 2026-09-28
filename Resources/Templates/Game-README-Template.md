# Game <N>: <Name> — <Tagline>

**Stage <N> — <stage name>** | Difficulty: <Easy / Medium / Hard>
**Concepts**: <comma-separated list of what this game teaches>

---

## 🎯 The Game

<2–4 paragraphs. What is it, what does the player do, and what makes the
mechanics interesting? Lead with the rule that defines the game — the
one sentence a player must understand. Mention the standout mechanic and
the twist that keeps it from being trivial.>

---

## ⚙️ Configuration: `settings.cfg`

<If the game reads a config file, document every key. Delete this
section if the game has no config.>

```ini
[game]
<key> = <default>

[ui]
use_color = true
clear_screen = true
```

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `<key>` | int | `<default>` | <what it changes, including edge cases> |
| `use_color` | bool | `true` | ANSI colors (auto-disabled when piped) |

---

## ▶️ How to Run

**Easiest**: double-click `run.bat` in this folder.

Or open a terminal in this folder and run:

```cmd
godot --headless --script main.gd
```

Use the **console** Godot build (`*_console.exe`) — the regular exe
detaches from the console on Windows and can't do interactive stdin.
If `godot` isn't on PATH, either invoke the console exe by its full
path, or set it in the `GODOT` variable at the top of `run.bat`.

> ⚠️ **Do NOT run it from the Godot editor** — the editor's script
> runner only supports `@tool`/`EditorScript` utility scripts. A game
> that `extends SceneTree` needs a real terminal anyway.

*(For scene-based games, replace this section with: open the folder as a
Godot project, press F5.)*

---

## 🎮 Commands

| Input | Effect |
|-------|--------|
| `<command/key>` | <what it does> |
| `help` / `h` | Show the move list |
| `quit` / `q` | Leave the game |

<Note anything non-obvious: "every action is one tick", "the world
doesn't pause between points", combined two-player inputs, etc.>

---

## 🔍 Code Tour — What This Game Teaches

<The heart of the README: map each curriculum concept to the code that
implements it. This is what makes the game a lesson instead of just a
program.>

| Concept | Where | What to notice |
|---------|-------|----------------|
| <concept> | `<var/func>` | <the insight — what should a reader understand?> |

### The tick/frame, annotated

```
update():
    <step>   # why it happens HERE in the order
```

<Call out check ordering — the order of guards is almost always a
design decision worth narrating.>

---

## ✅ Test Checklist

Verify each of these by actually playing:

- [ ] <one checkable behavior per line — concrete, observable>
- [ ] <boundary: what happens at the edge of the map/score/timer?>
- [ ] <invalid input: warns but costs nothing / or whatever is true>
- [ ] quit exits cleanly mid-game
- [ ] restart resets all state (score, positions, timers)
- [ ] <the "weird" case this game specifically has>

---

## 🛠️ Improvement Ideas

<If you implemented the obvious improvements already, strike them
through and say what happened — a README that records *outcomes* is
better than a stale wishlist. Then rank what's left by difficulty.>

1. ~~<done idea>~~ — **done.** <where / how>
2. <easy improvement>
3. <medium improvement>
4. <stretch>

---

## 💭 Reflection

Before moving on, be able to answer:

- <3–6 questions a reader should genuinely be able to answer after
  understanding this game — design *why*s, not trivia>
- Then update `PROGRESS.md` and move on to **<next game>**.

---

*Template lives at `Resources/Templates/Game-README-Template.md` — copy it into your game folder as `README.md`.*
