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
	_test_no_windows()
	_test_roof_units()
	_test_chimneys()
	_test_antenna()
	_test_pillars()
	_test_bands()
	_test_all_features_bounds()
	_test_tanks_stand_outside_body()
	_test_plan_wings()
	_test_u_courtyard_open()
	_test_gable_roofs()
	_test_barn_profile()
	_test_ridge_follows_long_side()
	_test_pitch()
	_test_sloped_roof_skips_roof_units()
	_test_offset_setback()
	_test_fins()
	_test_front_units()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


# ---------- helpers ----------

const OFF := {"roof_units": 0, "chimneys": 0, "antenna": 0, "pillars": 0, "bands": 0, "tanks": 0, "awning": 0.0, "fins": 0, "front_units": 0}


func _with(overrides: Dictionary) -> Dictionary:
	var p := BuildingRecipe.default_params()
	for k in overrides:
		p[k] = overrides[k]
	return p


func _only(overrides: Dictionary) -> Dictionary:
	var p := OFF.duplicate()
	for k in overrides:
		p[k] = overrides[k]
	return _with(p)


func _count_kind(parts: Array, kind: String) -> int:
	var n := 0
	for p: Dictionary in parts:
		if p["kind"] == kind:
			n += 1
	return n


func _count_role(parts: Array, role: String) -> int:
	var n := 0
	for p: Dictionary in parts:
		if p["role"] == role:
			n += 1
	return n


func _has_role(parts: Array, role: String) -> bool:
	return _count_role(parts, role) > 0


func _of_kind(parts: Array, kind: String) -> Array:
	var out: Array = []
	for p: Dictionary in parts:
		if p["kind"] == kind:
			out.append(p)
	return out


func _body_boxes(parts: Array) -> Array:
	var out: Array = []
	for p: Dictionary in parts:
		if p["kind"] == "box" and p["role"] == BuildingRecipe.ROLE_CONCRETE:
			out.append(p)
	return out


func _inside_box(part: Dictionary, point: Vector3) -> bool:
	var pos: Vector3 = part["pos"]
	var h: Vector3 = part["size"] * 0.5
	return absf(point.x - pos.x) < h.x and absf(point.y - pos.y) < h.y and absf(point.z - pos.z) < h.z


func _within_bounds(parts: Array, w: float, d: float) -> bool:
	var hx := w * 0.5 + 0.001
	var hz := d * 0.5 + 0.001
	for part: Dictionary in parts:
		var pos: Vector3 = part["pos"]
		var size: Vector3 = part["size"]
		var accent: bool = part["role"] in [BuildingRecipe.ROLE_TRIM, BuildingRecipe.ROLE_GLOW]
		var extra := BuildingRecipe.AWNING_DEPTH if accent else 0.0
		if part["kind"] == "cylinder" and pos.y < 3.0:
			extra = BuildingRecipe.TANK_REACH
		if absf(pos.x) + size.x * 0.5 > hx + extra or absf(pos.z) + size.z * 0.5 > hz + extra:
			return false
	return true


# ---------- core ----------

func _test_determinism() -> void:
	var p := _with({"seed": 42, "tanks": 2, "tiers": 2, "plan": BuildingRecipe.PLAN_L, "roof": BuildingRecipe.ROOF_GABLE})
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
	var parts := BuildingRecipe.build(_with({"width": 8.0, "depth": 6.0, "awning": 0.5}))
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


func _test_no_windows() -> void:
	var parts := BuildingRecipe.build(_with({}))
	_check(parts.size() > 0 and _count_role(parts, "window") == 0, "buildings have no windows")
	_check(not BuildingRecipe.default_params().has("windows"), "windows parameter is gone")


func _test_footprint_bounds() -> void:
	var p := _with({"width": 6.0, "depth": 5.0, "tiers": 3, "tanks": 4, "seed": 7})
	var parts := BuildingRecipe.build(p)
	_check(parts.size() > 0 and _within_bounds(parts, 6.0, 5.0), "all parts stay inside the footprint")


func _test_all_features_bounds() -> void:
	var ok := true
	for plan in 4:
		for roof in 5:
			var p := _with({"width": 9.0, "depth": 7.0, "tiers": 3, "tanks": 4, "roof_units": 4, "chimneys": 3, "antenna": 1, "pillars": 1, "bands": 1, "fins": 6, "front_units": 4, "offset": 1, "plan": plan, "roof": roof, "seed": 11})
			var parts := BuildingRecipe.build(p)
			if parts.is_empty() or not _within_bounds(parts, 9.0, 7.0):
				ok = false
	_check(ok, "every plan and roof keeps within footprint plus allowances")


func _test_tanks_stand_outside_body() -> void:
	var w := 8.0
	var parts := BuildingRecipe.build(_only({"tanks": 3, "width": w, "depth": 8.0}))
	var cylinders := _of_kind(parts, "cylinder")
	var all_outside := true
	for p: Dictionary in cylinders:
		var pos: Vector3 = p["pos"]
		var size: Vector3 = p["size"]
		if pos.x - size.x * 0.5 < w * 0.5 - 0.001:
			all_outside = false
	_check(cylinders.size() == 3 and all_outside, "tanks stand outside the body, against the right face")


# ---------- roof items ----------

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
	var gable := BuildingRecipe.build(_only({"antenna": 1, "height": height, "roof": BuildingRecipe.ROOF_GABLE}))
	_check(_glow_above(gable, height + 1.5), "antenna also stands on a gable roof")


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


# ---------- plans ----------

func _test_plan_wings() -> void:
	var expected := {BuildingRecipe.PLAN_BOX: 1, BuildingRecipe.PLAN_L: 2, BuildingRecipe.PLAN_T: 2, BuildingRecipe.PLAN_U: 3}
	for plan: int in expected:
		var parts := BuildingRecipe.build(_only({"plan": plan, "tiers": 1, "roof": BuildingRecipe.ROOF_FLAT}))
		_check(_body_boxes(parts).size() == expected[plan], "plan %d has %d wing(s)" % [plan, expected[plan]])


func _test_u_courtyard_open() -> void:
	var parts := BuildingRecipe.build(_only({"plan": BuildingRecipe.PLAN_U, "width": 10.0, "depth": 10.0, "wing": 0.3, "tiers": 1, "roof": BuildingRecipe.ROOF_FLAT}))
	var bodies := _body_boxes(parts)
	var courtyard_empty := bodies.size() == 3
	for b: Dictionary in bodies:
		if _inside_box(b, Vector3(0, 1.0, 3.5)):
			courtyard_empty = false
	_check(courtyard_empty, "U plan leaves the front courtyard open")


# ---------- sloped roofs ----------

func _test_gable_roofs() -> void:
	var box := BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "plan": BuildingRecipe.PLAN_BOX}))
	_check(_count_kind(box, "prism") == 1, "gable on a box plan is one prism")
	var l_plan := BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "plan": BuildingRecipe.PLAN_L, "tiers": 1}))
	_check(_count_kind(l_plan, "prism") == 2, "gable on an L plan puts a prism on each wing")
	var prisms := _of_kind(box, "prism")
	_check(prisms.size() == 1 and (prisms[0]["profile"] as Array).size() == 3, "gable profile is a triangle")


func _test_barn_profile() -> void:
	var parts := BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_BARN}))
	var prisms := _of_kind(parts, "prism")
	_check(prisms.size() == 1 and (prisms[0]["profile"] as Array).size() == 5, "barn roof is a five-point gambrel profile")


func _test_ridge_follows_long_side() -> void:
	var wide := _of_kind(BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "width": 12.0, "depth": 6.0})), "prism")
	var deep := _of_kind(BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "width": 6.0, "depth": 12.0})), "prism")
	_check(wide.size() == 1 and wide[0]["axis"] == "x", "ridge runs along x on a wide building")
	_check(deep.size() == 1 and deep[0]["axis"] == "z", "ridge runs along z on a deep building")


func _test_pitch() -> void:
	var low := _of_kind(BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "pitch": 0.3})), "prism")
	var high := _of_kind(BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "pitch": 0.9})), "prism")
	_check(low.size() == 1 and high.size() == 1 and (high[0]["size"] as Vector3).y > (low[0]["size"] as Vector3).y, "higher pitch makes a taller roof")


func _test_sloped_roof_skips_roof_units() -> void:
	var height := 7.0
	var parts := BuildingRecipe.build(_only({"roof": BuildingRecipe.ROOF_GABLE, "roof_units": 3, "height": height}))
	var n := 0
	for p: Dictionary in parts:
		var pos: Vector3 = p["pos"]
		if p["kind"] == "box" and p["role"] == BuildingRecipe.ROLE_DARK and pos.y > height:
			n += 1
	_check(parts.size() > 0 and n == 0, "sloped roofs carry no roof units")


# ---------- towers ----------

func _top_body(parts: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_y := -INF
	for b: Dictionary in _body_boxes(parts):
		var pos: Vector3 = b["pos"]
		if pos.y > best_y:
			best_y = pos.y
			best = b
	return best


func _test_offset_setback() -> void:
	var w := 10.0
	var d := 8.0
	var offset := _top_body(BuildingRecipe.build(_only({"tiers": 3, "offset": 1, "width": w, "depth": d, "roof": BuildingRecipe.ROOF_FLAT})))
	var centred := _top_body(BuildingRecipe.build(_only({"tiers": 3, "offset": 0, "width": w, "depth": d, "roof": BuildingRecipe.ROOF_FLAT})))
	var aligned := false
	if not offset.is_empty():
		var pos: Vector3 = offset["pos"]
		var size: Vector3 = offset["size"]
		aligned = is_equal_approx(pos.x - size.x * 0.5, -w * 0.5) and is_equal_approx(pos.z - size.z * 0.5, -d * 0.5) and size.x < w
	_check(aligned, "offset setback keeps upper tiers flush with the back-left corner")
	_check(not centred.is_empty() and absf((centred["pos"] as Vector3).x) < 0.001, "centred setback keeps tiers on the centre line")


func _test_fins() -> void:
	var height := 7.0
	var d := 8.0
	var parts := BuildingRecipe.build(_only({"fins": 4, "height": height, "depth": d, "tiers": 1}))
	var n := 0
	for p: Dictionary in parts:
		var pos: Vector3 = p["pos"]
		var size: Vector3 = p["size"]
		if p["role"] == BuildingRecipe.ROLE_TRIM and size.y >= height - 0.01 and pos.z > d * 0.5:
			n += 1
	_check(n == 4, "fins=4 adds four full-height fins on the front face")


func _test_front_units() -> void:
	var d := 8.0
	var parts := BuildingRecipe.build(_only({"front_units": 3, "depth": d}))
	var n := 0
	for p: Dictionary in parts:
		var pos: Vector3 = p["pos"]
		if p["kind"] == "box" and p["role"] == BuildingRecipe.ROLE_TRIM and pos.y < 1.0 and pos.z > d * 0.5:
			n += 1
	_check(n == 3, "front_units=3 puts three small boxes in front at ground level")
