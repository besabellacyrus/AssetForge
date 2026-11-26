# Using AssetForge

AssetForge makes low-poly isometric buildings from sliders and saves them as free (CC0) game assets.
You get a 3D model and a ready-to-use 2D sprite. Use them in any game, for any purpose, no credit needed.

Release candidate: `v0.1.0-rc.1`.

## 1. What you need

- [Godot 4.7](https://godotengine.org/download) (the standard build is fine). Nothing else to install.

## 2. Open the app

1. Download or clone this repo.
2. Open Godot, click **Import**, pick `project.godot` in this folder.
3. Press **F5**. The AssetForge window opens.

From a terminal: `godot --path .`

## 3. Make a building

The left panel has sliders. The right side is a live 3D preview.

- **Rotate:** left-drag in the preview. **Zoom:** mouse wheel.
- **Generate:** rolls a random building. Same seed, same building.
- **Seed:** change it to get a different variation of the same layout.

### Pick a style

The **Style** slider switches between two looks.

| Style | What you get |
| :--- | :--- |
| **Factory** | Industrial boxes, tanks, chimneys, antennas. Lots of sliders (plan, roof, tiers, fins, tanks...). |
| **Medieval** | Castles and cottages with cone towers, battlements, timber frames, fences and crops. |

Switching to Medieval turns the ink outline on and shows the **Medieval building** slider.

### Medieval buildings (16 presets)

Move the **Medieval building** slider to pick one:

| Castles | Cottages |
| :--- | :--- |
| Keep and Hall, Great Keep, Tower House, Walled Hall, Walled Cross Hall, Walled Twin Halls, Twin Tower Court, Triple Tower Court, Tower Cluster, Gatehouse | Farmhouse, Manor, Cottage, Tower Cottage, Tower Farmstead, Thatch Cottage |

Other medieval sliders:

| Slider | Effect |
| :--- | :--- |
| Width, Depth, Height | Scale the whole building |
| Palette | Roof colour: blue, red, green or purple |
| Ink outline | Black outline around the building (on by default in Medieval) |
| Seed | Small variations: tower heights and where the crops sit |

The factory sliders (Plan, Roof, Tiers...) are hidden in Medieval because they don't apply.

## 4. Save it

Click **Save (CC0)**. The window shows where it saved. Files go to `out/<name>/` inside this folder.
`<name>` is the building plus its seed, like `tower-farmstead_3`.

| File | What it is |
| :--- | :--- |
| `sprite.png` | 512x512 transparent isometric picture. Drop it straight into a 2D game. |
| `model.glb` | The 3D model with colours. Open it in Blender, Godot, Unity, Unreal or any glTF viewer. |
| `asset.json` | Name, style, preset, triangle count and every setting used. |
| `LICENSE.txt` | CC0 1.0 notice, dedicated by Cyrus Besabella. |

Saving the same building (same preset and seed) again overwrites its folder.

## 5. Use the files in your game

### 2D game (the sprite)

Godot:

```gdscript
var sprite := Sprite2D.new()
sprite.texture = load("res://assets/tower-farmstead_3/sprite.png")
add_child(sprite)
```

Any other engine: import `sprite.png` as a normal image with transparency. It is drawn at an isometric view
(45 degrees turned, 30 degrees down).

Each sprite is framed to fit its own building, so a small cottage and a big castle both fill the 512 px image.
Scale sprites in your game so buildings have the right relative size.

### 3D game (the model)

Godot: copy `model.glb` into your project. Godot imports it automatically. Drag it into a scene.
The colours are stored in the mesh (vertex colours), with no textures to manage.

Blender: **File > Import > glTF 2.0**.

### Rebuild or edit later

`asset.json` has a `params` block with every setting. It is a record of how the building was made, so you can
set the same sliders again to get it back.

## 6. License

Everything you save is **CC0 1.0** (public domain). You may use, change, sell and share it with no credit or permission.
Credit is welcome but not required. A copy of the notice is saved with every asset.

## 7. Troubleshooting

| Problem | Fix |
| :--- | :--- |
| Script errors about missing `MedievalPresets` or similar on first open | Close and reopen the project so Godot refreshes its class list. |
| Nothing saves | Check the message under the Save button. The `out/` folder must be writable. |
| Outline looks thin when zoomed out | The outline has a fixed size in the 3D world. The saved sprite is always rendered at a fixed zoom, so it looks right there. |
| Blank or black preview | Update your graphics driver. The app needs Godot's Forward Plus renderer. |

## 8. For developers

Tests, layout and architecture are in [README.md](README.md). The plan is in
[docs/procedural-buildings.md](docs/procedural-buildings.md).
