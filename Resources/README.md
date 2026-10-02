# Resources

Shared theory, templates, references, and assets for the whole lab.
Nothing here is stage-specific — dip in when a lesson points you at a
file, or browse in the order below.

---

## 📖 Suggested Reading Order

| # | File | Read when |
|---|------|-----------|
| 0 | `Theory/00-Setup-Guide.md` | Before anything else — install Godot (grab the `*_console.exe` too) |
| 1 | `Theory/01-What-Is-A-Game.md` | Before the Stage 0 lessons — the game loop |
| 2 | `Theory/02-What-Is-RenPy.md` | Before the VN track (skippable until then) |
| 3 | `Theory/03-Coordinates-and-Vectors.md` | During/after Stage 1 — required for Stage 2 |
| 4 | `Theory/04-Collision-Detection.md` | After Game 3 (1D Pong) — required for Stage 2 |
| 5 | `Theory/05-Signals-and-Events.md` | Before Stage 2 — how engine objects talk |
| 6 | `Theory/06-Debugging-and-Testing.md` | Anytime — sooner is better |

---

## 📁 Structure

| Folder | Contents |
|--------|----------|
| `Theory/` | Concept explanations, numbered in rough curriculum order |
| `Templates/` | Copy-and-fill starter files: design doc, game README, GDScript skeletons, test harness, Ren'Py script, run scripts |
| `References/` | Lookup material — doc links, glossary, asset sources & licensing |
| `Assets/` | Shared art/audio/fonts, including `placeholders/` SVGs you can drop into any Godot project today |

---

## 🔁 How these get used

- **Lessons** in `Stage0-Foundations/` cite the theory docs
- **Every new game** starts by *copying* a template — never edit files
  inside `Templates/` directly
- **Stuck?** `References/Documentation-Links.md` → official docs;
  `Theory/06-Debugging-and-Testing.md` → the debugging loop
- **Need art?** `Assets/placeholders/` first, `References/Asset-Sources.md`
  for the real thing (and the licensing rules)
