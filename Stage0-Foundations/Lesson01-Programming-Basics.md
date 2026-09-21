# Lesson 1: Programming Basics in GDScript

## 🎯 Learning Objectives

By the end of this lesson you will be able to:

- Declare variables and constants in GDScript
- Use the core data types: `int`, `float`, `String`, `bool`, `Array`, `Dictionary`
- Write conditions (`if`/`elif`/`else`, `match`)
- Write loops (`for`, `while`, `break`, `continue`)
- Spot the differences between GDScript and Python/C-style languages

> **You already know how to program.** This lesson is a *translation guide* —
> the concepts are familiar, the syntax has quirks worth knowing.

---

## 📦 Variables and Constants

```gdscript
var player_name = "Hero"       # mutable variable, type inferred
var health = 100
var speed = 4.5
var is_alive = true

const MAX_HEALTH = 100          # constant — cannot be reassigned
const GRAVITY = 9.8
```

### Optional Static Typing

GDScript is dynamically typed by default, but you can (and should) add type
hints. They catch bugs early and make the editor's autocomplete much better:

```gdscript
var health: int = 100
var speed: float = 4.5
var name_text: String = "Hero"

# Inference with typed assignment — same thing, shorter:
var gold := 0            # int, inferred from the literal
var ratio := 0.5         # float
```

**Rule of thumb for this lab**: use `:=` (typed inference) or explicit types for
everything except quick experiments.

### The `null` Value

```gdscript
var target = null        # no value yet
if target == null:
    target = "goblin"
```

---

## 🔢 Core Data Types

### Numbers

```gdscript
var whole = 42           # int
var fraction = 3.14      # float
var big = 1_000_000      # underscores for readability

# ⚠️ Division: int / int does INTEGER division (C-style, NOT like Python!)
print(7 / 2)             # 3     (truncated)
print(7.0 / 2)           # 3.5   (a float operand gives real division)
print(float(7) / 2)      # 3.5   (or cast explicitly)
print(7 % 2)             # 1     (modulo works as expected)
print(2 ** 10)           # 1024  (power operator — pow(2, 10) also works)
```

### Strings

```gdscript
var greeting = "Hello"
var multiline = """
Line one
Line two
"""

# Formatting — two common styles:
print("Health: %d / %d" % [health, MAX_HEALTH])
print("Score: {0}".format([score]))   # placeholder needs a key/index;
                                    # bare "{}" only works if you pass "{}" as
                                    # the 2nd arg — default placeholder is "{_}"

# Useful methods
var s = "  Goblin  "
print(s.strip_edges())   # "Goblin"
print(s.to_upper())      # "  GOBLIN  "
print(s.length())        # 10
print("abc".contains("b"))  # true
```

### Booleans and Nil-Safety

```gdscript
var ready = true
var done = false

# Ternary (note the order — value first!)
var label_text = "Ready" if ready else "Not ready"
```

---

## 📋 Arrays and Dictionaries

### Arrays — ordered lists

```gdscript
var inventory = ["sword", "potion", "key"]

inventory.append("shield")      # add
inventory.erase("potion")       # remove by value
inventory.remove_at(0)          # remove by index
print(inventory.size())         # 2
print(inventory[0])             # "key"
print(inventory.has("shield"))  # true

for item in inventory:
    print(item)
```

### Dictionaries — key/value maps

```gdscript
var player = {
    "name": "Hero",
    "health": 100,
    "level": 5,
}

print(player["name"])        # "Hero"
player["health"] = 80        # update
player["gold"] = 250         # add new key
print(player.has("mana"))    # false

# Dot access also works for string keys:
print(player.name)           # "Hero"

for key in player:
    print(key, " = ", player[key])
```

> **Gotcha**: Arrays and Dictionaries are **passed by reference**. Assigning
> `var b = a` makes `b` point at the same data. Use `a.duplicate()` for a copy.

### Vectors — coming in Stage 2

You'll meet `Vector2` and `Vector3` soon; they're built-in types, not arrays:

```gdscript
var pos = Vector2(100, 200)   # 2D position
print(pos.x, " ", pos.y)
```

---

## 🔀 Conditions

```gdscript
if health <= 0:
    die()
elif health < 25:
    show_warning()
else:
    keep_playing()

# Blocks use indentation (like Python) — no braces, no end keywords
if has_key and at_door:
    open_door()

if not is_alive or health <= 0:
    game_over()
```

### `match` — pattern matching (like `switch`, but better)

```gdscript
match command:
    "left", "l":                    # multiple patterns share a block
        move(-1)
    "right", "r":
        move(1)
    "quit":
        game_running = false
    _:                              # default case
        print("Unknown command")
```

`match` can also match numbers, arrays, and wildcard/bind patterns — we'll use
the simple form for now.

---

## 🔁 Loops

```gdscript
# Range-based for (0..4)
for i in 5:
    print(i)

for i in range(1, 11):        # 1..10
    print(i)

for i in range(0, 20, 3):     # 0, 3, 6, ... 18
    print(i)

# Iterate collections directly
for item in inventory:
    print(item)

# While loop
var attempts = 0
while attempts < 3:
    attempts += 1

# break / continue work as you'd expect
for n in 100:
    if n > 10:
        break
    if n % 2 == 0:
        continue
    print(n)                   # odd numbers 1..9
```

---

## ⚖️ GDScript vs. Languages You Know

| Feature | GDScript | Python | C-family |
|---------|----------|--------|----------|
| Blocks | Indentation | Indentation | `{ }` |
| Booleans | `true` / `false` | `True` / `False` | `true` / `false` |
| Null | `null` | `None` | `null` |
| Ternary | `a if c else b` | same | `c ? a : b` |
| `7 / 2` | `3` (int div) | `3.5` (Py3) | `3` (int div) |
| Power | `2 ** 10` | `2 ** 10` | `pow(2,10)` |
| `++` / `--` | ❌ use `+= 1` | ❌ | ✅ |
| Semicolons | Optional, unused | Optional | Required |
| Type hints | `var x: int` | `x: int` | `int x` |

---

## 🧪 Thought Exercises

1. **Division surprise** — what does `print(10 / 4)` output in Godot 4?

   <details><summary>Answer</summary>
   <code>2</code> — both operands are ints, so GDScript does integer division
   (C-style truncation), <em>not</em> Python-style float division.
   For <code>2.5</code> you'd write <code>10.0 / 4</code> or
   <code>float(10) / 4</code>.
   </details>

2. **Reference trap** — after this code, what is `b[0]`?

   ```gdscript
   var a = [1, 2, 3]
   var b = a
   b[0] = 99
   print(a[0])
   ```

   <details><summary>Answer</summary>
   <code>99</code> — arrays are references. Both variables point to the same
   array. Use <code>var b = a.duplicate()</code> to copy.
   </details>

3. **Match fallthrough?** — does `match` fall through to the next case like C's
   `switch` without `break`?

   <details><summary>Answer</summary>
   No. Only the first matching branch runs — no <code>break</code> needed.
   </details>

---

## ✅ Self-Assessment

- [ ] I can declare typed and untyped variables
- [ ] I know `int / int` truncates, and how to get float division
- [ ] I can write `if`/`elif`/`else` and `match`
- [ ] I can loop with `for` (ranges and collections) and `while`
- [ ] I know arrays/dictionaries are reference types
- [ ] I can format strings with `%` and `.format()`

---

## 🚀 What's Next?

Variables and loops are the raw materials — next we organize them into
**functions**, and see the special functions Godot calls for you.

→ `Lesson02-Functions.md`
