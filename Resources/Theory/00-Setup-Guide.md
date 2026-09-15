# Setup Guide: Installing Godot and Getting Started

## What You'll Learn
- What a game engine is and why we use one
- What Godot is and why it's great for learning
- How to install and configure Godot
- How to create your first project
- Basic Godot interface navigation

---

## 🎮 What is a Game Engine?

### Definition
A **game engine** is a software framework designed to help developers create games. Think of it as a toolkit that provides pre-built systems for common game development tasks.

### What Does a Game Engine Provide?

**Without a game engine**, you would need to write code for:
- Drawing graphics on the screen (rendering)
- Playing sounds
- Detecting keyboard/mouse input
- Physics calculations (gravity, collisions)
- Managing game objects
- Loading and saving files
- And much more...

**With a game engine**, these systems are already built! You can focus on:
- Your game's unique mechanics
- Level design
- Game logic
- Player experience

### Real-World Analogy
Imagine building a house:
- **Without an engine**: You mine ore, smelt metal, forge nails, cut down trees, mill lumber, etc.
- **With an engine**: You buy pre-made materials and focus on designing and building your house.

---

## 🚀 What is Godot?

**Godot** is a free, open-source game engine that's perfect for learning game development.

### Why Godot?

✅ **Completely Free** - No licensing fees, ever  
✅ **Open Source** - Community-driven, transparent  
✅ **Beginner-Friendly** - Designed with ease of use in mind  
✅ **Powerful** - Can create 2D and 3D games  
✅ **Lightweight** - Small download, runs on older computers  
✅ **Cross-Platform** - Make games for Windows, Mac, Linux, mobile, web  
✅ **Great Documentation** - Excellent learning resources  
✅ **Active Community** - Helpful forums and tutorials  
✅ **GDScript** - Python-like language that's easy to learn  

### Godot vs. Other Engines

| Engine | Best For | Learning Curve | Cost |
|--------|----------|----------------|------|
| **Godot** | Learning, 2D games, indie 3D | Easy | Free |
| Unity | Professional 3D, mobile | Medium | Free (with limits) |
| Unreal | AAA 3D graphics | Hard | Free (5% royalty) |
| GameMaker | 2D games | Easy | Paid |

**For learning**: Godot is ideal because it's free, lightweight, and teaches fundamental concepts that transfer to any engine.

---

## 📥 Installing Godot

### Step 1: Download Godot

1. **Visit the official website**:  
   https://godotengine.org/download

2. **Choose your version**:
   - **Godot 4.x** (Latest) - Recommended for new projects
   - Download the **Standard** version (not .NET unless you want C#)

3. **Select your operating system**:
   - Windows (64-bit)
   - macOS
   - Linux

4. **Download the ZIP file**

### Step 2: Extract and Run

**Windows**:
1. Extract the ZIP file to a location like `C:\Godot\` or `E:\Games\Godot\`
2. Inside, you'll find `Godot_v4.x.x_win64.exe`
3. Double-click to run (no installation needed!)
4. *Optional*: Create a desktop shortcut

**macOS**:
1. Extract the ZIP file
2. Move `Godot.app` to your Applications folder
3. Double-click to run
4. If macOS blocks it, go to System Preferences > Security & Privacy and allow it

**Linux**:
1. Extract the ZIP file
2. Make the file executable: `chmod +x Godot_v4.x.x_linux.x86_64`
3. Run it: `./Godot_v4.x.x_linux.x86_64`

### Step 3: First Launch

When you first launch Godot, you'll see the **Project Manager**:
- This is where you create, open, and manage projects
- Each game is a separate project
- Projects are stored in folders you choose

---

## 🎯 Understanding Godot's Core Concepts

Before creating your first project, let's understand key terminology:

### 1. Project
- A **project** is a complete game
- Contains all code, assets, scenes, and settings
- Stored in a folder on your computer
- Has a `project.godot` file

### 2. Scene
- A **scene** is a collection of game objects
- Think of it like a level, menu, or reusable component
- Examples: Main menu scene, Level 1 scene, Player scene
- Scenes can contain other scenes (composition)
- Saved as `.tscn` files

### 3. Node
- A **node** is a single game object or component
- Everything in Godot is made of nodes
- Examples: Sprite (displays an image), Timer, AudioPlayer
- Nodes are organized in a tree structure (parent-child relationships)

### 4. Script
- A **script** is code attached to a node
- Written in GDScript (Python-like language)
- Controls behavior and logic
- Saved as `.gd` files

### 5. Resource
- A **resource** is data used by your game
- Examples: Images, sounds, fonts, materials
- Can be reused across multiple scenes

### Visual Hierarchy Example

```
Game Project
├── Main Menu Scene
│   ├── Background (Sprite Node)
│   ├── Title (Label Node)
│   └── Start Button (Button Node + Script)
└── Level 1 Scene
    ├── Player (Node2D)
    │   ├── Sprite (Sprite Node)
    │   ├── CollisionShape (CollisionShape2D Node)
    │   └── PlayerScript.gd (Script)
    ├── Enemy (Node2D + Script)
    └── Background (Sprite Node)
```

---

## 🏗️ Creating Your First Project

### Step 1: Create a New Project

1. **Open Godot** (Project Manager appears)
2. **Click "New Project"**
3. **Fill in the details**:
   - **Project Name**: `TestProject`
   - **Project Path**: Choose a location (e.g., `E:\Games\Custom\GameDevLab\Stage0-Foundations\`)
   - **Renderer**: 
     - **Forward+** - Best graphics, modern hardware (3D games)
     - **Mobile** - Good graphics, wider compatibility
     - **Compatibility** - Older hardware, simple 2D games
     - *For learning, choose **Compatibility** or **Mobile***
4. **Click "Create & Edit"**

### Step 2: Understanding the Godot Editor

When your project opens, you'll see several panels:

```
┌─────────────────────────────────────────────────────┐
│  Menu Bar (File, Scene, Project, Debug, etc.)      │
├──────────┬──────────────────────────┬───────────────┤
│          │                          │               │
│  Scene   │                          │   Inspector   │
│  Tree    │      Viewport            │               │
│          │   (Main editing area)    │   (Properties)│
│          │                          │               │
├──────────┼──────────────────────────┤               │
│          │                          │               │
│FileSystem│      Bottom Panel        │               │
│          │  (Output, Debugger, etc.)│               │
└──────────┴──────────────────────────┴───────────────┘
```

**Key Panels**:

1. **Scene Tree** (Top Left)
   - Shows all nodes in your current scene
   - Hierarchical tree structure
   - Add, remove, and organize nodes here

2. **FileSystem** (Bottom Left)
   - Shows all files in your project
   - Scenes, scripts, images, sounds
   - Double-click to open files

3. **Viewport** (Center)
   - Main editing area
   - Visual editor for positioning objects
   - 2D and 3D views

4. **Inspector** (Right)
   - Shows properties of selected node
   - Modify position, size, color, etc.
   - Attach scripts here

5. **Bottom Panel**
   - **Output**: Messages and print statements
   - **Debugger**: Find and fix errors
   - **Animation**: Create animations
   - **Shader Editor**: Advanced graphics

### Step 3: Create Your First Scene

1. **Click the "+" button** in the Scene panel (or Scene > New Scene)
2. **Choose a root node type**:
   - For 2D: Select **Node2D** or **Control**
   - For 3D: Select **Node3D**
   - For now, choose **Node2D**
3. **Rename the node**:
   - Right-click the node > Rename
   - Name it "Main"
4. **Save the scene**:
   - Press `Ctrl+S` (or `Cmd+S` on Mac)
   - Name it `main.tscn`
   - Save in `res://` (your project root)

### Step 4: Add a Node

1. **Click the "+" button** in Scene panel (or right-click Main > Add Child Node)
2. **Search for "Label"**
3. **Select Label** and click "Create"
4. **In the Inspector** (right panel):
   - Find "Text" property
   - Type: `Hello, Godot!`
5. **In the Viewport**:
   - Drag the label to center of screen
   - Or set Position in Inspector: X=500, Y=300

### Step 5: Run Your First Scene

1. **Press F5** (or click the Play button ▶️ in top-right)
2. **Select a main scene** when prompted:
   - Choose `main.tscn`
   - Click "Select Current"
3. **Your game window opens** showing "Hello, Godot!"
4. **Close the window** to return to the editor

🎉 **Congratulations!** You've created and run your first Godot project!

---

## 📁 Project Organization Best Practices

As you build games, organize your files like this:

```
MyGame/
├── project.godot          # Project settings
├── scenes/                # All scene files
│   ├── main.tscn
│   ├── player.tscn
│   └── levels/
│       ├── level_1.tscn
│       └── level_2.tscn
├── scripts/               # All script files
│   ├── player.gd
│   └── enemy.gd
├── assets/                # All resources
│   ├── sprites/
│   │   ├── player.png
│   │   └── enemy.png
│   ├── sounds/
│   │   └── jump.wav
│   └── fonts/
│       └── main_font.ttf
└── README.md              # Game documentation
```

---

## 🎓 Key Vocabulary

| Term | Definition |
|------|------------|
| **Game Engine** | Software framework for creating games |
| **Godot** | Free, open-source game engine |
| **Project** | A complete game with all its files |
| **Scene** | A collection of nodes (like a level or component) |
| **Node** | A single game object or component |
| **Script** | Code that controls node behavior |
| **Resource** | Data file (image, sound, etc.) |
| **GDScript** | Python-like programming language for Godot |
| **Viewport** | The main editing area in Godot |
| **Inspector** | Panel showing properties of selected node |
| **Scene Tree** | Hierarchical view of all nodes in a scene |

---

## ✅ Verification Checklist

Before moving to the next lesson, make sure you can:

- [ ] Explain what a game engine does
- [ ] Explain why we're using Godot
- [ ] Launch Godot successfully
- [ ] Create a new project
- [ ] Identify the main panels in the Godot editor
- [ ] Create a new scene
- [ ] Add a node to a scene
- [ ] Save a scene
- [ ] Run a scene
- [ ] Explain what a node is
- [ ] Explain what a scene is
- [ ] Explain the difference between a node and a script

---

## 🚀 Next Steps

Now that Godot is installed and you understand the basics:

1. **Explore the interface** - Click around, open menus, see what's available
2. **Read the official "Your First 2D Game" tutorial** (optional):  
   https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html
3. **Get ready for Stage 0, Lesson 1**: Understanding game loops and basic programming

---

## 🆘 Troubleshooting

### Godot won't launch
- **Windows**: Make sure you extracted the ZIP file (don't run from inside ZIP)
- **macOS**: Check Security & Privacy settings
- **Linux**: Ensure the file is executable (`chmod +x`)

### Can't find the project folder
- Check the path you selected during project creation
- In Godot, go to Project > Open Project Manager to see all projects

### Scene won't run
- Make sure you saved the scene (Ctrl+S)
- Check that you selected a main scene (Project > Project Settings > Run > Main Scene)

### Interface looks different
- Godot 3.x and 4.x have different interfaces
- This guide assumes Godot 4.x
- Most concepts are the same, but button locations may differ

---

## 📚 Additional Resources

- **Official Documentation**: https://docs.godotengine.org/
- **Official Tutorials**: https://docs.godotengine.org/en/stable/community/tutorials.html
- **Godot Q&A**: https://ask.godotengine.org/
- **Reddit**: r/godot
- **Discord**: https://discord.gg/godotengine

---

**Ready to start coding? Let's move to Stage 0, Lesson 1!** 🎮
