extends SceneTree

# Run: godot --headless --path <project> -s res://tests/test_medieval_recipe.gd

const KINDS := ["box", "frustum", "cylinder", "prism", "cone"]
const ROLES := ["concrete", "trim", "dark", "glow", "roof", "thatch", "crop", "soil"]
const MARGIN := 1.6

var failures := 0


func _init() -> void:
	_test_sixteen_presets()
	_test_all_build()
	_test_deterministic()
	_test_presets_differ()
	_test_kinds_and_roles()
	_test_bounds()
	_test_roofed()
	_test_castle_towers()
	_test_cottage_extras()
	_test_style_switch()
	_test_params_clamped()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


func _build(preset: int, seed: int = 1, extra: Dictionary = {}) -> Array:
	var p := {"style": BuildingRecipe.STYLE_MEDIEVAL, "medieval": preset, "seed": seed}
	for k in extra:
		p[k] = extra[k]
	return BuildingRecipe.build(p)


func _has(parts: Array, kind: String, role: String = "") -> bool:
	for part: Dictionary in parts:
		if part["kind"] == kind and (role == "" or part["role"] == role):
			return true
	return false


func _has_role(parts: Array, role: String) -> bool:
	for part: Dictionary in parts:
		if part["role"] == role:
			return true
	return false


func _test_sixteen_presets() -> void:
	_check(MedievalPresets.COUNT == 16, "16 medieval presets")
	_check(MedievalPresets.NAMES.size() == 16, "every preset has a name")
	var named := true
	for n: String in MedievalPresets.NAMES:
		if n.is_empty():
			named = false
	_check(named, "preset names are not empty")


func _test_all_build() -> void:
	var ok := true
	for i in MedievalPresets.COUNT:
		if _build(i).is_empty():
			ok = false
	_check(ok, "all 16 presets build parts")


func _test_deterministic() -> void:
	var ok := true
	for i in MedievalPresets.COUNT:
		if str(_build(i, 7)) != str(_build(i, 7)):
			ok = false
	_check(ok, "same preset and seed give the same building")


func _test_presets_differ() -> void:
	var seen := {}
	for i in MedievalPresets.COUNT:
		seen[str(_build(i))] = true
	_check(seen.size() == 16, "16 presets give 16 different buildings")


func _test_kinds_and_roles() -> void:
	var ok := true
	for i in MedievalPresets.COUNT:
		for part: Dictionary in _build(i):
			if not (part["kind"] in KINDS) or not (part["role"] in ROLES):
				ok = false
	_check(ok, "only known kinds and roles are used")


func _test_bounds() -> void:
	var ok := true
	for i in MedievalPresets.COUNT:
		for part: Dictionary in _build(i, 3, {"width": 8.0, "depth": 8.0, "height": 7.0}):
			var pos: Vector3 = part["pos"]
			var size: Vector3 = part["size"]
			if absf(pos.x) + size.x * 0.5 > 4.0 + MARGIN or absf(pos.z) + size.z * 0.5 > 4.0 + MARGIN:
				ok = false
			if pos.y - size.y * 0.5 < -0.001 or pos.y + size.y * 0.5 > 14.0:
				ok = false
	_check(ok, "parts stay near the footprint and above the ground")


func _test_roofed() -> void:
	var ok := true
	for i in MedievalPresets.COUNT:
		var parts := _build(i)
		if not (_has_role(parts, "roof") or _has_role(parts, "thatch")):
			ok = false
	_check(ok, "every preset has a roof or thatch")
	_check(_has_role(_build(15), "thatch"), "thatch cottage uses thatch")


func _test_castle_towers() -> void:
	_check(_has(_build(1), "cone", "roof"), "great keep has a cone roof")
	_check(_has(_build(0), "cone"), "keep and hall has a cone tower")
	_check(_has_role(_build(1), "glow"), "great keep flies a flag")
	var merlons := 0
	for part: Dictionary in _build(3):
		if part["role"] == "trim" and part["kind"] == "box" and (part["size"] as Vector3).y == 0.5:
			merlons += 1
	_check(merlons >= 8, "walled hall has battlements")
	_check(_has(_build(7), "cylinder", "dark"), "courtyard towers are open (dark floor)")


func _test_cottage_extras() -> void:
	_check(_has_role(_build(10), "crop"), "farmhouse has crops")
	_check(_has_role(_build(10), "soil"), "farmhouse has soil")
	_check(_has_role(_build(15), "crop"), "thatch cottage has crops")
	_check(_has(_build(10), "prism", "thatch"), "farmhouse has a thatch lean-to")
	_check(not _has_role(_build(12), "crop"), "plain cottage has no crops")


func _test_style_switch() -> void:
	var factory := BuildingRecipe.build({"seed": 1})
	_check(not _has(factory, "cone"), "factory style never makes cones")
	_check(str(factory) != str(_build(0)), "style switches the generator")


func _test_params_clamped() -> void:
	var ok := not BuildingRecipe.build({"style": 1, "medieval": 99}).is_empty()
	ok = ok and not BuildingRecipe.build({"style": 1, "medieval": -5}).is_empty()
	_check(ok, "preset index is clamped")
	var d := BuildingRecipe.default_params()
	_check(d["style"] == 0 and d["medieval"] == 0 and d["outline"] == 0, "defaults keep the factory look")
