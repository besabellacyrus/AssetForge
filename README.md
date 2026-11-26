# AssetForge

A procedural asset generator for our games, built in Godot 4.7 (GDScript). Move sliders, watch a 3D building update live, and (soon) hit **Create** to save it as a CC0 asset.

First asset type: isometric factory buildings. First consumer: Aegis Foundry.

## Status

Work in progress.

| Done | Planned |
| :--- | :--- |
| Building recipe generator (seeded, deterministic) | Create button: export `.glb`, `.png` sprite, `.json` settings, CC0 license |
| Mesh builder (flat-shaded, role colours, 3 palettes) | Iso sprite baking |
| Live preview app with sliders and orbit camera | Windows on upper tiers, building presets (drill, refiner, bot bay, wall, rally) |

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
| Seed | 1–9999 | Varies tank sizes, window lighting, roof item placement |
| Width, Depth, Height | 4–14, 4–14, 2–16 | Building size |
| Tiers, Setback | 1–3, 0–0.4 | Stacked tiers, each inset from the one below |
| Roof | Flat, Hipped, Stepped | Roof style |
| Awning | 0–1 | Front awning size (0 removes it) |
| Tanks | 0–4 | Cylinders standing against the right face |
| Window columns | 0–6 | Window grid on the two faces the iso camera sees |
| Roof units, Chimneys | 0–4, 0–3 | Rooftop clutter |
| Antenna | on/off | Pole with a glowing tip |
| Corner pillars, Trim bands | on/off | Trim details |
| Palette | Industrial, Steel, Rust | Colour set |

## How it works

```
BuildingRecipe  params -> list of parts (boxes, frustums, cylinders) with colour roles   [pure]
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
