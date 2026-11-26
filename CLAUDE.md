# AssetForge

Procedural asset generator for our games. Godot 4.7 (GDScript). Generates isometric buildings in code, bakes them to PNG sprite sheets plus a JSON manifest in `out/`. Output is plain PNG/JSON, so any game can load it. First consumer: Aegis Foundry (`../AegisFoundry`).

Plan: `docs/procedural-buildings.md`.

## Commands

Godot is not on PATH. Executable: `C:\Users\Cyrus Besabella\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

- Refresh class cache after adding a `class_name` script: `godot --headless --path . --import`
- Run one test: `godot --headless --path . -s res://tests/<file>.gd`
- Headless cannot render. Bake and gallery need a windowed run.

## Layout

```
scripts/procgen/  BuildingRecipe (pure), MeshBuilder, IsoBaker, BuildingArt
scenes/dev/       BuildingGallery (preview grid)
tests/            headless SceneTree tests, _check(cond, label), prints FAILURES: N
reference/        CC0 source model (.gdignore, not imported)
out/              baked PNGs + manifest.json
docs/             plans
```

## Conventions

- Type every variable, parameter, return. Tabs.
- TDD for new logic. Deterministic: same (type, seed) gives the same asset.
- No new dependencies or addons without asking.
- Branch from `dev`, `feat/*` or `fix/*`. Ask before push or PR. Commit only when asked.
