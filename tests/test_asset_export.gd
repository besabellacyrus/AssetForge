extends SceneTree

# Run: godot --headless --path <project> -s res://tests/test_asset_export.gd

var failures := 0


func _init() -> void:
	_test_slug()
	_test_names()
	_test_metadata()
	_test_license()
	_test_write()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


func _medieval(preset: int, seed: int) -> Dictionary:
	var p := BuildingRecipe.default_params()
	p["style"] = 1
	p["medieval"] = preset
	p["seed"] = seed
	return p


func _test_slug() -> void:
	_check(AssetExport.slug("Keep and Hall") == "keep-and-hall", "slug lowercases and joins words")
	_check(AssetExport.slug("  Tower  House!! ") == "tower-house", "slug drops punctuation and extra spaces")


func _test_names() -> void:
	_check(AssetExport.asset_name(_medieval(1, 42)) == "great-keep_42", "medieval name is preset and seed")
	var factory := BuildingRecipe.default_params()
	factory["seed"] = 7
	_check(AssetExport.asset_name(factory) == "factory_7", "factory name is style and seed")
	_check(AssetExport.asset_name(_medieval(1, 42)) != AssetExport.asset_name(_medieval(2, 42)), "different presets get different names")


func _test_metadata() -> void:
	var p := _medieval(3, 5)
	var meta := AssetExport.metadata(p, Vector2i(512, 512), 120)
	_check(meta["name"] == "walled-hall_5", "metadata has the asset name")
	_check(meta["style"] == "Medieval" and meta["preset"] == "Walled Hall", "metadata names style and preset")
	_check(meta["license"] == "CC0-1.0", "metadata declares CC0")
	_check(meta["sprite"]["size"] == [512, 512], "metadata has the sprite size")
	_check(meta["triangles"] == 120, "metadata has the triangle count")
	_check(meta["params"]["seed"] == 5, "metadata keeps the params so the asset can be rebuilt")
	_check(meta["files"].has("model.glb") and meta["files"].has("sprite.png") and meta["files"].has("LICENSE.txt"), "metadata lists the files")
	_check(meta["author"] == "Cyrus Besabella" and meta["author_email"] == "besabellacyrus@gmail.com", "metadata names the author and email")
	_check(not JSON.stringify(meta).is_empty(), "metadata serialises to JSON")


func _test_license() -> void:
	var text := AssetExport.license_text()
	_check(text.contains("Dedicated to the public domain by Cyrus Besabella <besabellacyrus@gmail.com>"), "license names the author and email")
	_check(text.contains("CC0 1.0") and text.contains("creativecommons.org/publicdomain/zero/1.0"), "license names CC0 1.0 and links the deed")


func _test_write() -> void:
	var p := _medieval(1, 9)
	var parts := BuildingRecipe.build(p)
	var mesh := MeshBuilder.build_mesh(parts, MeshBuilder.palette(0, 1))
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var dir := OS.get_temp_dir().path_join("assetforge_test_export")
	var result := AssetWriter.save(dir, p, mesh, img)
	_check(result["error"] == OK, "save reports OK")
	for f in ["model.glb", "sprite.png", "asset.json", "LICENSE.txt"]:
		_check(FileAccess.file_exists(dir.path_join(AssetExport.asset_name(p)).path_join(f)), "writes " + f)
	var glb := FileAccess.open(dir.path_join(AssetExport.asset_name(p)).path_join("model.glb"), FileAccess.READ)
	_check(glb != null and glb.get_length() > 100, "glb is not empty")
