extends SceneTree

# Run: godot --headless --path <project> -s res://tests/test_building_recipe.gd

var failures := 0


func _init() -> void:
	_test_determinism()
	_test_seed_variation()
	_test_roof_styles()
	_test_awning()
	_test_tanks()
	_test_glow()
	_test_footprint_bounds()
	_test_front_accents_protrude()
	_test_windows()
	_test_roof_units()
	_test_chimneys()
	_test_antenna()
	_test_pillars()
	_test_bands()
	_test_all_features_bounds()
	_test_tanks_stand_outside_body()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


func _count_kind(parts: Array, kind: String) -> int:
	var n := 0
	for p: Dictionary in parts:
		if p["kind"] == kind:
			n += 1
	return n


func _has_role(parts: Array, role: String) -> bool:
	for p: Dictionary in parts:
		if p["role"] == role:
			return true
	return false


func _with(overrides: Dictionary) -> Dictionary:
	var p := BuildingRecipe.default_params()
	for k in overrides:
		p[k] = overrides[k]
	return p


func _test_determinism() -> void:
	var p := _with({"seed": 42, "tanks": 2, "tiers": 2})
	var a := BuildingRecipe.build(p)
	var b := BuildingRecipe.build(p)
	_check(a.size() > 0, "recipe produces parts")
	_check(str(a) == str(b), "same params and seed give identical parts")


func _test_seed_variation() -> void:
	var a := BuildingRecipe.build(_with({"seed": 1, "tanks": 3}))
	var b := BuildingRecipe.build(_with({"seed": 2, "tanks": 3}))
	_check(a.size() > 0 and str(a) != str(b), "different seeds vary the detail")


func _test_roof_styles() -> void:
	var hipped := BuildingRecipe.build(_with({"roof": BuildingRecipe.ROOF_HIPPED}))
	_check(_count_kind(hipped, "frustum") == 1, "hipped roof adds one frustum")
	var flat := BuildingRecipe.build(_with({"roof": BuildingRecipe.ROOF_FLAT}))
	_check(_count_kind(flat, "frustum") == 0 and flat.size() > 0, "flat roof has no frustum")
	var stepped := BuildingRecipe.build(_with({"roof": BuildingRecipe.ROOF_STEPPED}))
	_check(_count_kind(stepped, "frustum") == 0 and _count_kind(stepped, "box") > _count_kind(flat, "box"), "stepped roof has more roof boxes than flat")


func _test_awning() -> void:
	var with_awning := BuildingRecipe.build(_with({"awning": 0.5}))
	var no_awning := BuildingRecipe.build(_with({"awning": 0.0}))
	_check(_count_kind(with_awning, "box") > _count_kind(no_awning, "box"), "awning adds a box")
	_check(with_awning.size() > 0 and _has_role(with_awning, BuildingRecipe.ROLE_TRIM), "awning uses trim role")


func _test_tanks() -> void:
	var parts := BuildingRecipe.build(_with({"tanks": 3}))
	_check(_count_kind(parts, "cylinder") == 3, "tanks=3 gives three cylinders")
	var none := BuildingRecipe.build(_with({"tanks": 0}))
	_check(parts.size() > 0 and _count_kind(none, "cylinder") == 0, "tanks=0 gives no cylinders")


func _test_glow() -> void:
	var parts := BuildingRecipe.build(_with({}))
	_check(parts.size() > 0 and _has_role(parts, BuildingRecipe.ROLE_GLOW), "building has a glow accent")


func _test_front_accents_protrude() -> void:
	# Awning and glow strip must stick out of the front face (z > depth/2), not sink into the wall.
	var p := _with({"width": 8.0, "depth": 6.0, "awning": 0.5})
	var parts := BuildingRecipe.build(p)
	var front := 3.0
	var awning_out := false
	var glow_out := false
	for part: Dictionary in parts:
		var pos: Vector3 = part["pos"]
		var size: Vector3 = part["size"]
		if part["role"] == BuildingRecipe.ROLE_TRIM and pos.z - size.z * 0.5 >= front - 0.001 and pos.y < 2.0:
			awning_out = true
		if part["role"] == BuildingRecipe.ROLE_GLOW and pos.z - size.z * 0.5 >= front - 0.001:
			glow_out = true
	_check(awning_out, "awning protrudes from the front face")
	_check(glow_out, "glow strip protrudes from the front face")


const OFF := {"windows": 0, "roof_units": 0, "chimneys": 0, "antenna": 0, "pillars": 0, "bands": 0, "tanks": 0, "awning": 0.0}


func _only(overrides: Dictionary) -> Dictionary:
	var p := OFF.duplicate()
	for k in overrides:
		p[k] = overrides[k]
	return _with(p)


func _count_role(parts: Array, role: String) -> int:
	var n := 0
	for p: Dictionary in parts:
		if p["role"] == role:
			n += 1
	return n


func _lit_or_window(parts: Array) -> int:
	return _count_role(parts, BuildingRecipe.ROLE_WINDOW) + _count_role(parts, BuildingRecipe.ROLE_GLOW)


func _test_windows() -> void:
	var none := BuildingRecipe.build(_only({}))
	var few := BuildingRecipe.build(_only({"windows": 2}))
	var many := BuildingRecipe.build(_only({"windows": 4}))
	_check(none.size() > 0 and _lit_or_window(none) == 1, "windows=0 leaves only the front glow strip")
	_check(_lit_or_window(few) > 1 and _lit_or_window(many) > _lit_or_window(few), "more window columns give more window parts")


func _test_roof_units() -> void:
	var height := 7.0
	var parts := BuildingRecipe.build(_only({"roof_units": 3, "height": height, "roof": BuildingRecipe.ROOF_FLAT}))
	var n := 0
	for p: Dictionary in parts:
		var pos: Vector3 = p["pos"]
		if p["kind"] == "box" and p["role"] == BuildingRecipe.ROLE_DARK and pos.y > height:
			n += 1
	_check(n == 3, "roof_units=3 puts three dark boxes on the roof")


func _test_chimneys() -> void:
	var height := 7.0
	var parts := BuildingRecipe.build(_only({"chimneys": 2, "height": height}))
	var n := 0
	for p: Dictionary in parts:
		var pos: Vector3 = p["pos"]
		if p["kind"] == "cylinder" and pos.y > height:
			n += 1
	_check(n == 2, "chimneys=2 puts two cylinders above the roofline")


func _glow_above(parts: Array, y: float) -> bool:
	for p: Dictionary in parts:
		var pos: Vector3 = p["pos"]
		if p["role"] == BuildingRecipe.ROLE_GLOW and pos.y > y:
			return true
	return false


func _test_antenna() -> void:
	var height := 7.0
	var on := BuildingRecipe.build(_only({"antenna": 1, "height": height}))
	var off := BuildingRecipe.build(_only({"antenna": 0, "height": height}))
	_check(_glow_above(on, height + 1.5) and not _glow_above(off, height + 1.5), "antenna adds a glow tip high above the roof")


func _count_tall_trim(parts: Array, height: float) -> int:
	var n := 0
	for p: Dictionary in parts:
		var size: Vector3 = p["size"]
		if p["role"] == BuildingRecipe.ROLE_TRIM and p["kind"] == "box" and size.y >= height - 0.01:
			n += 1
	return n


func _test_pillars() -> void:
	var height := 7.0
	var on := BuildingRecipe.build(_only({"pillars": 1, "height": height, "tiers": 1}))
	var off := BuildingRecipe.build(_only({"pillars": 0, "height": height, "tiers": 1}))
	_check(_count_tall_trim(on, height) == 4, "pillars=1 adds four tall corner trim columns")
	_check(off.size() > 0 and _count_tall_trim(off, height) == 0, "pillars=0 adds none")


func _count_bands(parts: Array) -> int:
	var n := 0
	for p: Dictionary in parts:
		var size: Vector3 = p["size"]
		if p["role"] == BuildingRecipe.ROLE_TRIM and is_equal_approx(size.y, BuildingRecipe.BAND_HEIGHT):
			n += 1
	return n


func _test_bands() -> void:
	var on := BuildingRecipe.build(_only({"bands": 1, "tiers": 2}))
	var off := BuildingRecipe.build(_only({"bands": 0, "tiers": 2}))
	_check(_count_bands(on) == 2, "bands=1 adds one trim band per tier")
	_check(off.size() > 0 and _count_bands(off) == 0, "bands=0 adds none")


func _test_all_features_bounds() -> void:
	var p := _with({"width": 6.0, "depth": 5.0, "tiers": 3, "tanks": 4, "windows": 6, "roof_units": 4, "chimneys": 3, "antenna": 1, "pillars": 1, "bands": 1, "seed": 11})
	var parts := BuildingRecipe.build(p)
	var ok := parts.size() > 0
	var hx: float = p["width"] * 0.5 + 0.001
	var hz: float = p["depth"] * 0.5 + 0.001
	for part: Dictionary in parts:
		var pos: Vector3 = part["pos"]
		var size: Vector3 = part["size"]
		var accent: bool = part["role"] in [BuildingRecipe.ROLE_TRIM, BuildingRecipe.ROLE_GLOW, BuildingRecipe.ROLE_WINDOW]
		var extra := BuildingRecipe.AWNING_DEPTH if accent else 0.0
		if part["kind"] == "cylinder" and pos.y < 3.0:
			extra = BuildingRecipe.TANK_REACH
		if absf(pos.x) + size.x * 0.5 > hx + extra or absf(pos.z) + size.z * 0.5 > hz + extra:
			ok = false
	_check(ok, "every feature keeps within footprint plus front-accent allowance")


func _test_tanks_stand_outside_body() -> void:
	var w := 8.0
	var parts := BuildingRecipe.build(_only({"tanks": 3, "width": w, "depth": 8.0}))
	var n := 0
	var all_outside := true
	for p: Dictionary in parts:
		if p["kind"] == "cylinder":
			n += 1
			var pos: Vector3 = p["pos"]
			var size: Vector3 = p["size"]
			if pos.x - size.x * 0.5 < w * 0.5 - 0.001:
				all_outside = false
	_check(n == 3 and all_outside, "tanks stand outside the body, against the right face")


func _test_footprint_bounds() -> void:
	var p := _with({"width": 6.0, "depth": 5.0, "tiers": 3, "tanks": 4, "seed": 7})
	var parts := BuildingRecipe.build(p)
	var ok := parts.size() > 0
	var hx: float = p["width"] * 0.5 + 0.001
	var hz: float = p["depth"] * 0.5 + 0.001
	for part: Dictionary in parts:
		var pos: Vector3 = part["pos"]
		var size: Vector3 = part["size"]
		var accent: bool = part["role"] in [BuildingRecipe.ROLE_TRIM, BuildingRecipe.ROLE_GLOW, BuildingRecipe.ROLE_WINDOW]
		var extra := BuildingRecipe.AWNING_DEPTH if accent else 0.0
		if part["kind"] == "cylinder" and pos.y < 3.0:
			extra = BuildingRecipe.TANK_REACH
		if part["kind"] == "box" or part["kind"] == "cylinder":
			if absf(pos.x) + size.x * 0.5 > hx + extra or absf(pos.z) + size.z * 0.5 > hz + extra:
				ok = false
		elif part["kind"] == "frustum":
			if absf(pos.x) + size.x * 0.5 > hx or absf(pos.z) + size.z * 0.5 > hz:
				ok = false
	_check(ok, "all parts stay inside the footprint")
