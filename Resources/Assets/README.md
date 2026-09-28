# Assets

Shared graphics, sounds, fonts, and music for all projects in this lab.

**Why shared?** Most Stage 2+ games need the same handful of things — a
player shape, a pickup, an enemy, UI sounds. Build them once here, copy
into each project, and your game folders stay self-contained.

---

## 📁 Organization

```
Assets/
├── README.md            ← You are here
├── placeholders/        ← Simple SVG shapes — use TODAY, replace later
│   ├── ball.svg
│   ├── paddle.svg
│   ├── player.svg
│   ├── enemy.svg
│   ├── coin.svg
│   └── tile.svg
├── sprites/             ← Downloaded/drawn sprite packs
├── audio/
│   ├── sfx/             ← Jump, pickup, hit, click...
│   └── music/           ← Loops and tracks
└── fonts/               ← .ttf / .otf for UI
```

## 🏷️ Naming Conventions

- `lowercase_with_underscores` — `player_idle_01.png`, not `Player Idle 01.PNG`
- Prefix by role: `player_*`, `enemy_*`, `ui_*`, `sfx_*`, `music_*`
- Number variants from `01`: `coin_spin_01.png`, `coin_spin_02.png`

## ⚖️ Licensing

Anything you didn't draw yourself needs a license line. Keep an
`ATTRIBUTION.md` in each game folder that uses external assets:

```markdown
| Asset | Author | Source | License |
|-------|--------|--------|---------|
| coin.png | Kenney | https://kenney.nl/... | CC0 |
```

Where to find free, legal assets: `../References/Asset-Sources.md`

## 🎨 The Placeholders

`placeholders/` contains minimal SVG shapes in lab-standard colors.
Godot 4 imports SVG as a texture — drag one onto a `Sprite2D` and it
just works.

| File | Shape | Suggested role |
|------|-------|----------------|
| `player.svg` | Green triangle | Player character, ship |
| `enemy.svg` | Red diamond | Enemy, hazard |
| `coin.svg` | Gold circle | Pickup, collectible |
| `ball.svg` | White circle | Pong/breakout ball, projectile |
| `paddle.svg` | White rounded bar | Pong/breakout paddle |
| `tile.svg` | Grey square w/ border | Grid cell, platform block |

**The placeholder rule**: get the game *fun* with these first. Replace
art only after the mechanics earn it.
