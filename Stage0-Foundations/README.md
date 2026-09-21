# Stage 0: Foundations

**Focus**: Programming and game development basics  
**Deliverable**: Simple text-based interactive program (see `TextAdventure/`)

---

## 🎯 What This Stage Covers

Before building real games, we need a shared foundation. Since you already have
programming experience, these lessons focus on **how things work in GDScript and
Godot specifically**, not on teaching programming from scratch.

| Lesson | File | Covers |
|--------|------|--------|
| 1 | `Lesson01-Programming-Basics.md` | Variables, data types, operators, conditions, loops |
| 2 | `Lesson02-Functions.md` | Functions, parameters, return values, Godot callbacks |
| 3 | `Lesson03-Input-Coordinates-States.md` | Input handling, 1D coordinates, game states |

Already covered in `Resources/Theory/`:

- `01-What-Is-A-Game.md` — what a game is, the game loop, frames
- `02-What-Is-RenPy.md` — visual novels and the Ren'Py engine

---

## 📁 Files in This Directory

```
Stage0-Foundations/
├── README.md                              ← You are here
├── Lesson01-Programming-Basics.md
├── Lesson02-Functions.md
├── Lesson03-Input-Coordinates-States.md
├── Exercises.md                           ← Practice problems + solutions
└── TextAdventure/                         ← Stage 0 deliverable
    ├── README.md                          ← How to run it
    ├── main.gd                            ← A complete 1D text adventure
    └── project.godot
```

---

## 🏆 The Deliverable: Dungeon Corridor

`TextAdventure/main.gd` is a complete, runnable text game. It deliberately uses
**every concept from this stage**:

| Concept | How the game uses it |
|---------|---------------------|
| Game loop | `input → update → render` once per turn |
| Variables & types | Position, health, gold, flags |
| Functions | One function per responsibility (`_update`, `_render`, ...) |
| Conditions | Command parsing, combat, pickups |
| 1D coordinates | The whole game is a corridor on a number line |
| Game states | Playing / won / lost |

**Read the code, run it, then modify it.** Suggested modifications are listed in
`TextAdventure/README.md` — breaking and fixing things is the fastest way to
lock these concepts in.

---

## ✅ Completion Checklist

You're done with Stage 0 when you can:

- [ ] Explain the three phases of the game loop
- [ ] Write GDScript variables, conditions, and loops without checking syntax
- [ ] Define and call functions with parameters and return values
- [ ] Explain what a 1D position, direction, and distance are
- [ ] Describe game states and sketch a state diagram
- [ ] Run `TextAdventure/main.gd` and win the game
- [ ] Modify the game (e.g., add a second monster or a new command)
- [ ] Complete the exercises in `Exercises.md`

When all boxes are ticked, update `PROGRESS.md` and move on to
**Stage 1 → Game 1: Number Guessing**.

---

## ⏱️ Suggested Pace

With 1–3 hours/week and advanced programming experience:

- **Session 1**: Lessons 1–2 + skim the TextAdventure code
- **Session 2**: Lesson 3 + run the game + exercises
- **Session 3**: Modify the game, tick the checklist, start Stage 1
