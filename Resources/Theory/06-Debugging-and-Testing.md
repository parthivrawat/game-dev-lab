# Lesson: Debugging and Testing

## 🎯 Learning Objectives

By the end of this lesson, you will understand:
- The debugging loop: reproduce → isolate → fix → verify
- How to read a GDScript error message
- Print debugging done *well* (it's a skill, not a hack)
- Breakpoints and Godot's debugger
- How to write a manual test checklist for a game

---

## 🔁 The Debugging Loop

Every bug fix is the same four steps:

```
1. REPRODUCE — make the bug happen on purpose, reliably
2. ISOLATE   — shrink it: which line, which value, which frame?
3. FIX       — address the root cause, not the symptom
4. VERIFY    — replay the repro; also check you didn't break neighbors
```

**The #1 beginner mistake is skipping to step 3.** Editing code before
you can make the bug happen on demand is guessing. A bug you can
reproduce is a bug that's already half-fixed.

### Reproduce first

"Sometimes the ball flies through the paddle" is not a bug report — it's
a rumor. Turn it into: *"At speed ≥ 2.0, when the ball's landing cell
skips my coverage, it passes through."* Now it's fixable — and it turns
out to be the *point* of Game 3's landing-rule design.

### Isolate by bisecting

If you don't know which of 200 lines is wrong, don't read all 200 —
cut the space in half. Comment out half the update logic. Still broken?
The bug is in the half you kept. Repeat. Binary search beats staring.

---

## 📖 Reading GDScript Errors

An error message has three parts — read all three:

```
Invalid get index 'velocty' (on base: 'Node (main.gd)').
    at: _update (res://main.gd:88)
    ↑ what went wrong          ↑ where
```

| Error pattern | Usually means | First thing to check |
|---------------|---------------|----------------------|
| `Invalid get index 'x' (on base: 'Nil')` | You're using a variable that was never set | Where is it assigned? Is `@onready` needed? |
| `Identifier not declared` | Typo or scope issue | Spelling; is it inside the function? |
| `Expected ':' / ')' / indent` | Syntax structure broken | Missing colon, mixing tabs/spaces |
| `Cannot call non-static function` | Calling instance method on the class | Call it on an *instance* |
| `Node not found` | `get_node`/`$Path` doesn't match the tree | Print the tree; check names/spelling |
| `Invalid call. Nonexistent function` | Method name wrong or wrong type | Check the object's actual class |

**Tabs vs. spaces**: GDScript requires consistent indentation. The
games in this lab use **tabs**. One stray space-indent = parser error.

### Read the FIRST error, not the last

One real bug often produces a cascade of follow-on errors. Fix the top
of the list first — the rest may evaporate.

---

## 🖨️ Print Debugging — Done Properly

`print()` is the world's oldest debugger and still the fastest way to
answer "what is this value *right now*?"

```gdscript
# Vague — useless when several values scroll by:
print(pos)

# Labeled — you can actually read the output:
print("ball_pos=%.2f vel=%.2f cell=%d" % [ball_pos, ball_vel, cell])
```

Rules that make it work:

- **Label every print** — `"player_pos"` not just the value
- **Print where the decision is made**, not where you notice the symptom.
  Ball tunneling? Print `prev_pos`, `ball_pos`, and the coverage check —
  *before* the response code runs.
- **Print the boundary frame** — if a bug happens "sometimes", log every
  frame and diff the last good vs. first bad output
- **Remove or gate debug prints before finishing** — a `DEBUG` constant
  or your game's config flag keeps them available but silent

```gdscript
const DEBUG := false

func _dbg(msg: String) -> void:
    if DEBUG:
        print("[dbg] ", msg)
```

---

## 🛑 The Real Debugger (scene projects)

In Stage 2+ you'll have the full editor debugger:

- **Breakpoint**: click in the gutter left of a line number — execution
  pauses there
- **Step over / step into**: advance one line, or dive into a call
- **Inspect**: hover variables or use the debugger panel to see live values
- **Remote scene tree**: while running, inspect the *live* node tree —
  is that enemy actually where the code thinks it is?

Breakpoint = a `print` that also freezes time. When print debugging
becomes a scrolling wall of text, switch to breakpoints.

---

## ✅ Manual Testing: The Checklist Method

You can't automate play-feel — so test systematically. Every game README
in this lab has a Test Checklist section; here's how to write one.

### Test the contract, not just the code

For every feature, ask: *what exactly did I promise?* Then test that.

| Feature | Promises | Test cases |
|---------|----------|------------|
| Paddle movement | "l/r move one cell, blocked at mid" | move left, move right, hit the boundary |
| Scoring | "first to N wins" | score at 0-0, at match point, past the line |
| Config file | "missing file → defaults" | delete it, corrupt it, set absurd values |

### Always test the edges

Bugs live at boundaries, not in the middle:

- **Empty/zero**: 0 health, 0 enemies, empty inventory, score = 0
- **Boundaries**: position = 0 and = max; first/last list element
- **Overflow**: score beyond display width, rally counter past shrink
- **Rapid input**: hammering keys, holding vs. tapping, input mid-state-change
- **State transitions**: pause during countdown, quit mid-match,
  restart while animating
- **Fresh run vs. restart**: state that should reset but doesn't is the
  most common game bug class there is

### The repro → regression habit

When you fix a bug, add its repro steps to the checklist *as a permanent
item*. Bugs you already shipped are the ones most likely to return.
Your checklist becomes the game's immune system — see Game 3's checklist
for a working example (21 items, each one playable).

---

## 🧯 When You're Really Stuck

1. **Rubber duck it** — explain the code line by line, out loud, as if
   to someone who doesn't know it. You will hear yourself say the wrong
   assumption.
2. **Minimal repro** — copy the suspicious code into a fresh
   `--headless --script` file with just enough context to run. If it
   works there, the bug is in the *context*, not the code.
3. **Undo to working** — `git diff` against the last working state. The
   bug is *in that diff*, guaranteed.
4. **Change ONE thing at a time** — two simultaneous edits means two
   candidate causes.
5. **Walk away** — the bug description you write for a question is often
   the debugging step that solves it.

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Reproduce** | Make a bug happen on purpose, reliably |
| **Isolate** | Narrow the bug to one line/value/frame |
| **Regression** | A bug that returns after being fixed |
| **Breakpoint** | A marker that pauses execution at a line |
| **Edge case** | Input/state at the extreme of allowed values |
| **Bisect** | Halve the suspect code until the bug is cornered |
| **Rubber duck debugging** | Explaining the code aloud to find the flaw |

---

## 🧪 Thought Exercises

1. **The cascade**: you changed one line and got 12 errors. Which do you
   read first?

   <details>
   <summary>Answer</summary>
   The first — the rest are often the first error's fallout.
   </details>

2. **The flaky bug**: "the game sometimes crashes when two enemies die
   the same frame." What's step one?

   <details>
   <summary>Answer</summary>
   Reproduce: spawn two enemies with 1 HP overlapping and hit both.
   &quot;Sometimes&quot; bugs are usually &quot;always under these exact
   conditions&quot; bugs you haven't found yet.
   </details>

3. **Restart bug**: the second run of your game starts with the score
   from the first. Where do you look?

   <details>
   <summary>Answer</summary>
   Wherever restart resets state — some variable isn't being reset. This
   is the classic &quot;fresh run vs. restart&quot; edge case.
   </details>

---

## ✅ Self-Check

- [ ] Name the four steps of the debugging loop
- [ ] Explain why reproduction comes before fixing
- [ ] Read a GDScript error and find the file + line it names
- [ ] Write a labeled debug print
- [ ] Set a breakpoint and inspect a variable
- [ ] Write a 5-item test checklist for a feature
- [ ] Name three edge cases worth testing in any game

---

## 🚀 What's Next?

- Apply the checklist habit to every game README
- When a bug costs you real effort, log it in `PROGRESS.md` → Bugs Solved
- **Templates/** (`Resources/Templates/`): the README template includes
  a ready-made Test Checklist section

---

**Debugging isn't the part where you're bad at programming — it's the part where you're doing it. 🔍**
