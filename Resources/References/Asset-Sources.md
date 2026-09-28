# Free Game Asset Sources

Where to find sprites, sounds, music, and fonts you can legally use —
plus the licensing rules that matter.

> **Rule zero**: download assets into `Resources/Assets/` (organized by
> the README there) and **always record the source + license**. Future
> you will not remember where that coin sprite came from.

---

## 🎨 Sprites & 2D Art

| Site | Link | License | Notes |
|------|------|---------|-------|
| **Kenney** | https://kenney.nl/assets | CC0 | The gold standard — huge free packs, consistent style |
| **OpenGameArt** | https://opengameart.org/ | Mixed | Check each asset's license; quality varies |
| **itch.io assets** | https://itch.io/game-assets | Mixed | Filter by "free"; lots of pixel art |
| **Godot Asset Library** | https://godotengine.org/asset-library/ | Mixed | Assets + plugins, installable from the editor |

## 🔊 Sound Effects & Music

| Site | Link | License | Notes |
|------|------|---------|-------|
| **Kenney audio** | https://kenney.nl/assets/category:Audio | CC0 | UI clicks, impacts, jingles |
| **Freesound** | https://freesound.org/ | Mixed | Massive; check each file's license |
| **Pixabay** | https://pixabay.com/sound-effects/ | Pixabay license | Free SFX + music, no attribution needed |
| **jsfxr / sfxr** | (web tool — search "jsfxr") | CC0 output | Generate retro bleeps yourself — perfect for learning projects |

## 🔤 Fonts

| Site | Link | License | Notes |
|------|------|---------|-------|
| **Google Fonts** | https://fonts.google.com/ | Mostly OFL | Free for any use, including commercial |
| **Kenney fonts** | https://kenney.nl/assets/category:Fonts | CC0 | Game-styled fonts (Kenney Pixel etc.) |

## 🖼️ Visual Novel Art (Ren'Py track)

| Site | Link | Notes |
|------|------|-------|
| **Lemma Soft resources** | https://lemmasoft.renai.us/forums/viewforum.php?f=52 | Free VN backgrounds & sprites shared by the community |
| **OpenGameArt** | https://opengameart.org/ | Tag search "visual novel" / "background" |

---

## 📜 Licenses — the 60-second version

| License | You may... | You must... |
|---------|-----------|-------------|
| **CC0** | Anything, no credit | Nothing — public domain |
| **CC-BY** | Use, modify, sell | **Credit the author** |
| **CC-BY-SA** | Use, modify, sell | Credit + share your work under the same license |
| **OFL** (fonts) | Use, embed, sell | Don't resell the font alone |
| **"Free for personal use"** | Use in learning projects | NOT publish/sell games with it |

**Practical rules for this lab:**

1. **Prefer CC0** (Kenney covers ~90% of learning needs)
2. **Keep an `ATTRIBUTION.md`** in your game folder listing every
   third-party asset: name, author, source URL, license
3. **"Free to download" ≠ "free to redistribute"** — a published game
   ships copies of its assets, so check the license *before* you build
   around an asset
4. **Never rip assets** from commercial games — even for practice
   projects you'd share

### `ATTRIBUTION.md` skeleton

```markdown
# Attributions

| Asset | Author | Source | License |
|-------|--------|--------|---------|
| coin.png | Kenney | https://kenney.nl/assets/... | CC0 |
```

---

## 🛠️ Making Your Own (recommended!)

Learning projects honestly benefit from ugly-but-yours art:

- **Aseprite / Piskel** — pixel art (Piskel is free, browser-based)
- **Krita / GIMP** — general 2D art (free)
- **Audacity** — record/edit sounds (free)
- **The `placeholders/` folder** in `Resources/Assets/` — simple shapes
  you can drop in *today* so art never blocks coding

Placeholder-first is a real workflow: get the game fun with squares and
circles, then skin it. **Fun survives bad art; pretty doesn't survive
bad fun.**
