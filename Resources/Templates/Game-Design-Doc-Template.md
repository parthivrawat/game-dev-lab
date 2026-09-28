# Design Doc: <Game Name>

**Stage**: <Stage N — stage name> | **Planned Difficulty**: <Easy / Medium / Hard>
**Status**: Draft | **Date**: <YYYY-MM-DD>

> Fill this in during the **Plan** step, before writing code. One page is
> enough — a design doc exists to make decisions *before* they're
> expensive, not to predict the future. Delete sections that don't apply.

---

## 🎯 Concept

<One paragraph: what is the game? What does the player DO? What is the
fantasy or hook? If you can't describe it in three sentences, the idea
isn't ready yet.>

**Example**: *Pong flattened onto a number line — defend your wall by
standing where the ball will land.*

---

## 🧠 Core Loop

<What does the player repeat? Write it as a cycle.>

```
<see threat → position → react → score/miss → threat escalates → repeat>
```

---

## 🕹️ Controls & Input

| Input | Effect |
|-------|--------|
| `<key/click>` | `<what it does>` |
| `quit` | Leave the game |

---

## 🗺️ World & Rules

- **Space**: <1D line of N cells / 2D screen / grid / 3D area>
- **Entities**: <player, ball, enemies, pickups — one line each>
- **Core rules**: <the 2–4 rules that define the game. For Game 3 this
  was "ball returns only if it LANDS on covered cell" + "returns add
  speed".>

---

## 🚦 Game States

<Which modes exist and how do they connect? Draw it.>

```
MENU → PLAYING → PAUSED → PLAYING
              ↘ GAME_OVER → MENU
```

| State | What runs | What input does |
|-------|-----------|-----------------|
| `PLAYING` | full update | game commands |
| `GAME_OVER` | nothing | restart / quit |

---

## 🏆 Win / Lose Conditions

- **Win**: <score threshold / survive timer / reach exit>
- **Lose**: <miss the ball / HP = 0 / time out>
- **Between points**: <does the world keep ticking? who serves next?>

---

## ⚙️ Configuration (`settings.cfg`)

<What should be tunable without editing code? Rules of thumb: anything
you'd want to tweak while playtesting.>

| Key | Type | Default | Effect |
|-----|------|---------|--------|
| `<name>` | int/float/bool | `<value>` | <what it changes> |

---

## 📐 Concepts This Game Teaches

<Map the game to the curriculum — what should be true after finishing it?>

- <e.g., float velocity + landing-based collision>
- <e.g., difficulty curve via shrinking coverage>

---

## 🔨 Scope

### MVP (must have to call it a game)
- [ ] <core mechanic working end-to-end>
- [ ] win/lose + restart
- [ ] basic UI/HUD

### Improvements (ranked by difficulty)
1. <easy polish>
2. <medium feature>
3. <stretch goal>

**Anti-scope**: <name what you will NOT build this time — writing it
down is how it stays out.>

---

## ❓ Open Questions

- <Anything you can't decide yet? Park it here, not in the code.>

---

## ✅ Definition of Done

- [ ] MVP checklist complete
- [ ] Test checklist in README passes
- [ ] README written (run instructions, code tour, improvements)
- [ ] `PROGRESS.md` updated

---

*Template lives at `Resources/Templates/Game-Design-Doc-Template.md` — copy it into your game folder as `DESIGN.md`.*
