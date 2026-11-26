# Procedural Buildings

**Status:** Planning
**Project:** standalone Godot 4.7 project, `Documents/AssetForge` (own git repo)
**Source:** `reference/building_commercial_05` (user-made, CC0, copied from Aegis Foundry `CC0_packs/`)
**Output:** PNG sprites + `manifest.json` in `out/`, engine-agnostic

---

## 1. Goal

A reusable asset generator for our games. First set: factory buildings (core, drill, refiner, bot bay, wall, rally, belt end caps), generated in code,
in the style of the CC0 model, then bake them to isometric 2D sprites. The game stays 2D.
Each building type gets a recipe; a seed varies size and details so two drills don't look identical.

## 2. What the CC0 model is

`building_commercial_05` (OBJ/GLB/FBX, same mesh): 24 vertices, 19 quads, no materials, no textures.
Bounds about 8.4 x 9.05 x 9.5 units. It is three parts:

| Part | Shape | Size (units) |
| :--- | :--- | :--- |
| Body | box, square footprint | 8.36 x 7.84 tall x 8.36 |
| Roof cap | hipped frustum, 7.84 → 9.05, top inset to 3.47 square | 1.21 tall |
| Awning | slab sticking out the front face, from the ground up | 7.19 wide x 3.39 tall x 1.16 deep |

This gives the grammar: **body box + roof cap + front annex**, plus optional extras.

## 3. Generation grammar

A recipe is a list of **parts**. Each part is a primitive with a position, size and color role.

Primitives:
- `box` (x, y, z, w, h, d)
- `frustum` (base w/d, top w/d, height): the roof cap
- `cylinder` (radius, height, sides): tanks, chimneys, drill heads

Parts per building:
1. **Body:** 1–2 stacked boxes. The second tier is set back (inset 10–25%).
2. **Roof:** one of flat, frustum cap (like the model), or stepped.
3. **Front annex:** awning or loading bay on one face (like the model). Faces the build direction.
4. **Details (type-specific):** rooftop units, tanks, vents, antenna, light strips (glow color role).

Type recipes (every building is 1x1 in `GridManager` today; bigger footprints are proposals):

| Type | Footprint | Signature parts |
| :--- | :--- | :--- |
| core | 1x1 (3x3? Q2) | tall stepped body, frustum cap, glow ring |
| drill | 1x1 | short body, cylinder drill head + derrick |
| smelter (refiner) | 1x1 | body + 1–2 tanks + chimney |
| assembler (bot bay) | 1x1 (2x2? Q2) | wide body, big awning/bay door, roof units |
| wall | 1x1 | low box, no annex, crenels |
| beacon (rally) | 1x1 | small base + tall antenna + glow tip |

Colour roles (no textures, vertex colors, flat shaded): `concrete` grey, `trim` yellow,
`dark` panel, `glow` cyan `#22d3ee`. Matches the reference look in spirit, not in detail.

## 4. Architecture

```
scripts/procgen/BuildingRecipe.gd   pure: (type, seed) -> Array[Dictionary] parts. Deterministic. Testable.
scripts/procgen/MeshBuilder.gd      pure-ish: parts -> ArrayMesh (SurfaceTool, vertex colors, flat normals). Testable.
scripts/procgen/IsoBaker.gd         node: SubViewport + orthographic Camera3D (iso angle) + light -> ImageTexture.
scripts/procgen/BuildingArt.gd      cache: (type, seed, dir) -> Texture2D. Bakes on first use.
scenes/dev/BuildingGallery.tscn     dev-only preview grid of every type x a few seeds.
tests/test_building_recipe.gd       recipe bounds, determinism, type signatures
tests/test_mesh_builder.gd          vertex/face counts, colors per role
```

- **Separation:** the recipe is pure data, the mesh builder is pure geometry, the baker owns rendering,
  the cache owns lifetime. Nothing here touches `GridManager` or gameplay.
- **Determinism:** `RandomNumberGenerator` seeded from `(type, seed)`. Same input, same building.
  Per-instance seed comes from the cell (e.g. `hash(cell)`), so a building looks the same after reload.
- **Bake once:** bake at startup (or first use) into the cache. No 3D at runtime in the world.
- **Directions:** bake 4 rotations per variant (the annex faces the build direction).
- **Iso camera:** orthographic, yaw 45°, pitch about -30° (2:1 pixel iso). Transparent background.

## 5. Tasks

- [x] 0. Scaffold project (`project.godot`, folders, git init, reference model).
- [x] 1. `BuildingRecipe` (tests green, 11 assertions) + tests (TDD): determinism, part bounds inside footprint, each type has its signature part.
- [x] 2. `MeshBuilder` (6 assertions green) + tests (TDD): box = 24 verts (flat faces), frustum, cylinder; color roles applied.
- [ ] 3. `IsoBaker`: SubViewport bake to `ImageTexture`, save PNGs. Verify in a windowed run (headless can't render).
- [ ] 4. `BuildingGallery.tscn`: grid of types x seeds x directions. You judge the look here.
- [ ] 5. Tune recipes and palette from the gallery.
- [ ] 6. Export: `out/<type>_<seed>_<dir>.png` + `manifest.json` (type, seed, dir, size, pivot offset).
- [x] 3a. `ParamSpec` (slider ranges, value labels) + tests.
- [x] 3b. `App.tscn` window: sliders, live 3D preview, orbit camera (`OrbitCamera`). Verified by a headless frame capture; look needs your review.
- [x] 3d. More features: windows (iso faces), roof units, chimneys, antenna, corner pillars, trim bands, 3 palettes (Industrial, Steel, Rust). Tanks moved outside the body (they were buried). Scrolling slider panel. Tests green.
- [x] 3e. Shapes from reference sheet: plans (Box, L, T, U), gable and barn roofs with pitch, offset setback towers, fins, front units, Plain palette (default). Windows removed.
- [x] 3g. Medieval style (castles and cottages from the reference sheet): `style` toggle, 16 presets in `MedievalPresets`, `MedievalRecipe`, `cone` primitive, blue/red/green/purple roof palettes, ink outline (inverted hull, `MeshBuilder.build_outline_mesh`). Factory look unchanged.
- [ ] 3f. Building presets (drill, refiner, bot bay, wall, rally).
- [x] 3c. Save button (CC0): export `.glb` + `.png` + `.json` + CC0 license to `out/<name>/`.
- [ ] 7. Run all tests. Ask before any push.

## 6. Risks

- **Headless can't render.** Tasks 1–2 are testable headless; the bake (3) and gallery (4) need a windowed run.
- **Bake time.** About 6 types x 4 seeds x 4 dirs = 96 small renders at startup. Should be well under a second; measure.
- **Look ceiling.** Flat-shaded boxes look clean and low-poly, not like the detailed reference art.
- **CC0 files in the project.** `CC0_packs/` is inside the project, so Godot imports all three formats
  (FBX, GLB, OBJ). We only use it as a reference, so a `.gdignore` in `CC0_packs/` would skip the imports.

## 7. Decisions

- Separate project, not inside the game repo. Reusable across games.
- Godot 4.7 + GDScript. Bakes through a SubViewport.
- Output is PNG sprites + JSON manifest. No .glb export for now.
- Reference model only, kept in `reference/` with `.gdignore`.

## 8. Open questions

1. **Footprints:** buildings are 1x1 in Aegis Foundry today. Should the generator also emit multi-cell footprints (core 3x3, bot bay 2x2) for later?
2. **Sprite size:** target pixel size per cell, e.g. 64x32 diamond per cell (2:1 iso)?
3. **Hookup:** how Aegis Foundry consumes `out/` is a separate task, after the isometric projection work.
