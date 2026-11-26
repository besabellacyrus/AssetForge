# AssetForge

A procedural asset generator for our games, built in Godot 4.7 (GDScript). Move sliders, watch a 3D building update live, and (soon) hit **Create** to save it as a CC0 asset.

First asset type: isometric factory buildings. First consumer: Aegis Foundry.

## Status

Work in progress.

| Done | Planned |
| :--- | :--- |
| Building recipe generator (seeded, deterministic) | Create button: export `.glb`, `.png` sprite, `.json` settings, CC0 license |
| Mesh builder (flat-shaded, role colours, 4 palettes) | Iso sprite baking |
| Live preview app with sliders and orbit camera | Building presets (drill, refiner, bot bay, wall, rally) |
| Plans (Box, L, T, U), gable and barn roofs, towers, fins | |

Plan and task list: [docs/procedural-buildings.md](docs/procedural-buildings.md)

## Run the app

Open the folder in Godot 4.7 and press F5. The main scene is `scenes/App.tscn`.

Or from a terminal:

```
godot --path .
```

- Left panel: sliders. Everything rebuilds as you move them.
- Right side: left-drag to rotate, mouse wheel to zoom.
- **Re-roll seed** picks a random seed. The same settings and seed always give the same building.

## Settings

| Setting | Range | Effect |
| :--- | :--- | :--- |
| Seed | 1–9999 | Varies tank sizes and roof item placement |
| Plan | Box, L, T, U | Footprint shape built from wings (U leaves a front courtyard) |
| Wing thickness | 0.25–0.6 | Thickness of the wings on L, T and U plans |
| Width, Depth, Height | 4–14, 4–14, 2–16 | Building size |
| Tiers, Setback | 1–3, 0–0.4 | Stacked tiers on the Box plan, each inset from the one below |
| Offset setback | on/off | Tiers stay flush with the back-left corner (stepped tower) |
| Roof | Flat, Hipped, Stepped, Gable, Barn | Roof style. Gable and Barn follow each wing's long side |
| Roof pitch | 0.2–1.0 | Height of Gable and Barn roofs |
| Awning | 0–1 | Front awning size (0 removes it) |
| Fins | 0–6 | Full-height vertical fins on the front face |
| Front units | 0–4 | Small boxes along the ground at the front |
| Tanks | 0–4 | Cylinders standing against the right face |
| Roof units, Chimneys | 0–4, 0–3 | Rooftop clutter (sloped roofs take chimneys and antenna only) |
| Antenna | on/off | Pole with a glowing tip |
| Corner pillars, Trim bands | on/off | Trim details |
| Palette | Plain, Industrial, Steel, Rust | Colour set. Plain is a single light tone |

## How it works

```
BuildingRecipe  params -> list of parts (boxes, frustums, cylinders, prisms) with colour roles   [pure]
MeshBuilder     parts  -> ArrayMesh, flat normals, vertex colours from a palette          [pure]
ParamSpec       slider ranges and value labels                                            [pure]
AssetApp        window: slider panel + 3D preview
```

The pure layers have no nodes, so they run and test headless.

## Layout

```
scripts/procgen/   BuildingRecipe, MeshBuilder
scripts/app/       AssetApp, ParamSpec, OrbitCamera
scenes/App.tscn    main scene
tests/             headless tests
reference/         CC0 source model (not imported by Godot)
out/               export destination
docs/              plans
```

## Tests

Godot is not on PATH, so use its full path. After adding a script with a new `class_name`, refresh the class cache first:

```
godot --headless --path . --import
```

Run a test file (each prints `FAILURES: N` and exits non-zero on failure):

```
godot --headless --path . -s res://tests/test_building_recipe.gd
godot --headless --path . -s res://tests/test_mesh_builder.gd
godot --headless --path . -s res://tests/test_param_spec.gd
```

Headless Godot cannot render, so how things look needs a windowed run.

## License

CC0 1.0 Universal. See [LICENSE](LICENSE).

Dedicated to the public domain by Cyrus Besabella and Claude (Anthropic).

## Notes

- Godot treats clockwise triangles as front faces. `MeshBuilder` emits them that way, with outward normals.
- `reference/` has a `.gdignore`, so Godot does not import the reference model.
- Generated output is intended to be CC0 too. See `CLAUDE.md` for conventions.
