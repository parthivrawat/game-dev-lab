# Lesson: What is Ren'Py?

## 🎯 Learning Objectives

By the end of this lesson, you will understand:
- What Ren'Py is and what it's used for
- How it differs from Godot
- What a visual novel / narrative game is
- The basic structure of a Ren'Py project
- When to use Ren'Py vs. Godot

---

## 📖 What is Ren'Py?

**Ren'Py** is a free, open-source game engine designed specifically for **visual novels** and **story-driven games**.

### Definition

A **visual novel** is a type of game where:
- Most of the experience is **reading a story** with choices
- Characters are shown as **illustrations (sprites)**
- The **background and music** set the scene
- The player makes **choices** that change the story
- The focus is on **narrative, dialogue, and player decisions**

Famous examples of visual novels:
- *Doki Doki Literature Club!*
- *Clannad*
- *Fate/stay night*
- *Phoenix Wright: Ace Attorney* (similar style)

### What Does Ren'Py Provide?

Ren'Py gives you built-in tools for:
- Displaying dialogue and narration
- Showing character sprites
- Changing backgrounds
- Playing music and sound effects
- Creating branching choices
- Saving and loading progress
- Managing scenes and chapters
- Running a game loop for visual novels

### Why Ren'Py?

✅ **Beginner-friendly** - Very simple script syntax  
✅ **Python-based** - Uses Python-like code (easy to learn if you know GDScript or Python)  
✅ **Visual novel focused** - Built specifically for narrative games  
✅ **Free and open-source** - No cost, community-driven  
✅ **Powerful** - Supports complex branching, animations, mini-games, and more  
✅ **Great for stories** - Dialogue, choices, relationships, multiple endings  
✅ **Active community** - Lots of tutorials and resources  

### Ren'Py vs. Godot

| Feature | Ren'Py | Godot |
|---------|--------|-------|
| **Best For** | Visual novels, story games, interactive fiction | Action, platformers, arcade, 3D games |
| **Game Loop** | Built for narrative flow | Real-time input/update/render |
| **Primary Code** | Ren'Py script (Python-like) | GDScript (Python-like) |
| **Animation** | Simple sprite/background changes | Complex 2D/3D animation |
| **Physics** | None built-in | Full 2D and 3D physics |
| **Input** | Mouse clicks, choices, simple key presses | Full real-time controls |
| **Art** | 2D images and character sprites | 2D sprites, 3D models, particles |
| **Scenes** | Dialogue screens and menus | Complex game levels |

---

## 🎮 When to Use Ren'Py vs. Godot

### Use **Ren'Py** when your game is mostly:
- Story and dialogue
- Choices and branching
- Character relationships
- Multiple endings
- Visual novels
- Dating sims
- Mystery/investigation games (text-heavy)

### Use **Godot** when your game is mostly:
- Real-time action
- Physics-based movement
- Platforming
- Shooting
- Puzzles with real-time mechanics
- 3D exploration
- Fast gameplay

### Can You Combine Them?

**Yes!** Many modern games mix both:
- Use **Godot** for the main gameplay (exploration, combat, puzzles)
- Use **Ren'Py-style narrative** for story scenes
- Or build a **visual novel in Ren'Py** with simple mini-games

For this learning lab, we will mainly keep them **separate projects** so you can learn each engine clearly. Later, in the **capstone project**, you can decide which one fits your game idea best, or even combine ideas from both.

---

## 🏗️ Basic Structure of a Ren'Py Game

A Ren'Py game is made of **script files** (`.rpy`) that tell the story.

### Example Ren'Py Script

```renpy
# This is a label — like a scene or chapter
label start:
    
    # Set the background
    scene bg room
    
    # Show a character
    show eileen happy
    
    # Character speaks
    e "Hello! Welcome to your first visual novel."
    
    # Narrator text
    "You find yourself in a small room."
    
    # Player makes a choice
    menu:
        "What do you do?"
        
        "Say hello back."
            e "Nice to meet you!"
        
        "Stay silent."
            e "Oh... you don't talk much, do you?"
    
    # Continue story
    "The adventure begins."
    
    return
```

### Key Parts

| Element | Meaning | Example |
|---------|---------|---------|
| `label` | A named section of the story | `label start:` |
| `scene` | Show a background | `scene bg room` |
| `show` | Show a character | `show eileen happy` |
| `e "..."` | Character dialogue | `e "Hello!"` |
| `"..."` | Narrator text | `"It was a dark night."` |
| `menu:` | Player choice | `menu:` with options |
| `return` | End the game | `return` |

### Game Loop in Ren'Py

Ren'Py has a different game loop from real-time games:

```
Show background
↓
Show characters
↓
Show text/dialogue
↓
Wait for player input (click or key)
↓
Move to next line
↓
If choice: show menu and wait for selection
↓
Continue story
↓
Repeat
```

**Think of it as a digital book that responds to the reader.**

---

## 📥 Installing Ren'Py

### Step 1: Download

1. Visit: https://www.renpy.org/
2. Click **Download**
3. Download the **Latest** version for your OS
4. Extract the ZIP file

### Step 2: Launch

**Windows**:
- Run `renpy.exe`

**macOS**:
- Run the Ren'Py application

**Linux**:
- Run `./renpy.sh`

### Step 3: Create a New Project

1. Launch the Ren'Py Launcher
2. Click **"Create New Project"**
3. Choose a name like `VN-Test-Project`
4. Choose resolution (e.g., 1280x720)
5. Pick a color theme
6. Click **"Continue"** until finished

### Step 4: Run the Test

1. Select your project in the launcher
2. Click **"Launch Project"**
3. A sample visual novel will run

---

## 🎯 Where Ren'Py Fits in Our Learning Lab

We will use Ren'Py as a **parallel learning track** focused on **narrative and choice-based games**. It does not replace Godot, but it adds a new dimension:

### Suggested Ren'Py Path

1. **Ren'Py Introduction** (this lesson)
   - What is a visual novel?
   - Install Ren'Py
   - Create first script

2. **Mini VN 1: Branching Story**
   - Choices and consequences
   - Multiple endings
   - Characters and dialogue

3. **Mini VN 2: Character System**
   - Character definitions
   - Expressions and emotions
   - Simple relationships

4. **Mini VN 3: Inventory / Quest VN**
   - Variables and state
   - Inventory system
   - Quest tracking
   - Save and load

5. **Capstone Integration**
   - Use Ren'Py for a story-driven game
   - OR combine Ren'Py concepts with Godot

---

## 🧩 Ren'Py Projects in Our Lab

We have added a new directory for Ren'Py practice games:

```
RenPy-Projects/
├── VN01-Branching-Story/
├── VN02-Character-Expressions/
├── VN03-Inventory-Quest/
└── VN04-RenPy-Capstone/
```

These will run **alongside** your Godot games. You don't need to build all of them — you can do one or two to understand narrative game design, then apply what you learn to your main games.

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Visual Novel** | A game that is mainly reading, with choices and images |
| **Ren'Py** | An engine for making visual novels and story games |
| **Script** | A file that tells the story in Ren'Py |
| **Label** | A named section of a script |
| **Sprite** | A 2D character image |
| **Background** | The image behind the characters |
| **Menu** | A set of choices for the player |
| **Branching** | A story that changes based on choices |
| **Dialogue** | Text spoken by characters |
| **Narration** | Text that describes the scene |

---

## ✅ Self-Check

Before using Ren'Py, make sure you can:

- [ ] Explain what a visual novel is
- [ ] Explain the difference between Godot and Ren'Py
- [ ] Know when to use each engine
- [ ] Explain what a `label` is in Ren'Py
- [ ] Explain what `menu:` is in Ren'Py
- [ ] Create and run a new Ren'Py project

---

## 🚀 Why Add Ren'Py to Your Learning?

Because of your interest in **Adventure/RPG**, Ren'Py helps you understand:
- **Narrative design** - How to tell stories in games
- **Player choices** - How decisions affect gameplay
- **State tracking** - Variables and branching
- **Character systems** - Dialog, relationships, emotions
- **UI for text-heavy games** - Different from action games
- **Save/load systems** - Important for long games
- **Game feel in slower games** - Pacing, music, transitions

These skills are extremely useful for **RPGs** and **adventure games**, even if the final game is built in Godot.

---

## 💡 Real-World Analogy

Think of the two engines as **two types of art tools**:

- **Godot is like a 3D/2D animation studio** — you build worlds, physics, movement, and real-time action.
- **Ren'Py is like a comic book or film script editor** — you focus on dialogue, scenes, choices, and story flow.

Some of the best games use **both kinds of tools** in different parts!

---

## 📚 Resources

- **Ren'Py Official Site**: https://www.renpy.org/
- **Ren'Py Tutorial**: https://www.renpy.org/doc/html/tutorial.html
- **Ren'Py Cookbook**: https://lemmasoft.renai.us/forums/viewforum.php?f=51
- **Visual Novel Database**: https://vndb.org/

---

**Ren'Py gives us a new way to build games — with words and choices. When you're ready, we can create your first visual novel alongside your Godot games! 🎮📖**
