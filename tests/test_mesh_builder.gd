extends SceneTree

# Run: godot --headless --path <project> -s res://tests/test_mesh_builder.gd

var failures := 0


func _init() -> void:
	_test_box()
	_test_frustum()
	_test_cylinder()
	_test_colours()
	_test_winding_faces_out()
	_test_full_building_builds()
	_test_palettes()
	_test_prisms()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


func _part(kind: String, role: String) -> Dictionary:
	var p := {"kind": kind, "pos": Vector3(0, 1, 0), "size": Vector3(2, 2, 2), "role": role}
	if kind == "frustum":
		p["top"] = Vector2(1, 1)
	if kind == "prism":
		p["profile"] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1)]
		p["axis"] = "x"
	return p


func _verts(mesh: ArrayMesh) -> PackedVector3Array:
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _colors(mesh: ArrayMesh) -> PackedColorArray:
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]


func _test_box() -> void:
	var pal := MeshBuilder.default_palette()
	var mesh := MeshBuilder.build_mesh([_part("box", BuildingRecipe.ROLE_CONCRETE)], pal)
	_check(mesh != null and mesh.get_surface_count() == 1, "box makes one surface")
	_check(mesh != null and _verts(mesh).size() == 36, "box has 36 vertices (12 triangles)")


func _test_frustum() -> void:
	var pal := MeshBuilder.default_palette()
	var mesh := MeshBuilder.build_mesh([_part("frustum", BuildingRecipe.ROLE_CONCRETE)], pal)
	_check(mesh != null and _verts(mesh).size() == 36, "frustum has 36 vertices")


func _test_cylinder() -> void:
	var pal := MeshBuilder.default_palette()
	var mesh := MeshBuilder.build_mesh([_part("cylinder", BuildingRecipe.ROLE_DARK)], pal)
	_check(mesh != null and _verts(mesh).size() == MeshBuilder.CYL_SEGMENTS * 12, "cylinder vertex count follows segments")


func _test_colours() -> void:
	var pal := MeshBuilder.default_palette()
	var mesh := MeshBuilder.build_mesh([_part("box", BuildingRecipe.ROLE_TRIM)], pal)
	var ok := mesh != null and _colors(mesh).size() == 36
	if ok:
		for c in _colors(mesh):
			if not c.is_equal_approx(pal[BuildingRecipe.ROLE_TRIM]):
				ok = false
	_check(ok, "every vertex of a trim part uses the trim colour")


func _test_winding_faces_out() -> void:
	# Godot front faces are clockwise: the geometric normal from the winding must point INTO the part,
	# while the stored vertex normals point OUT of it.
	var pal := MeshBuilder.default_palette()
	var barn := _part("prism", BuildingRecipe.ROLE_CONCRETE)
	barn["profile"] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0.55, 0.65), Vector2(0, 1), Vector2(-0.55, 0.65)]
	barn["axis"] = "z"
	var parts := [_part("box", BuildingRecipe.ROLE_CONCRETE), _part("frustum", BuildingRecipe.ROLE_CONCRETE), _part("cylinder", BuildingRecipe.ROLE_DARK), _part("prism", BuildingRecipe.ROLE_CONCRETE), barn]
	for part: Dictionary in parts:
		var mesh := MeshBuilder.build_mesh([part], pal)
		var ok := mesh != null and _verts(mesh).size() > 0
		if ok:
			var arrays := mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var centre: Vector3 = part["pos"]
			for i in range(0, v.size(), 3):
				var geo := (v[i + 1] - v[i]).cross(v[i + 2] - v[i]).normalized()
				var mid := (v[i] + v[i + 1] + v[i + 2]) / 3.0
				if geo.dot(mid - centre) >= 0.0:
					ok = false
				if nrm[i].dot(mid - centre) <= 0.0:
					ok = false
		_check(ok, "%s: clockwise front faces, outward normals" % part["kind"])


func _test_full_building_builds() -> void:
	var parts := BuildingRecipe.build(BuildingRecipe.default_params())
	var mesh := MeshBuilder.build_mesh(parts, MeshBuilder.default_palette())
	_check(mesh != null and mesh.get_surface_count() == 1, "default recipe builds one mesh surface")


func _test_palettes() -> void:
	var roles := [BuildingRecipe.ROLE_CONCRETE, BuildingRecipe.ROLE_TRIM, BuildingRecipe.ROLE_DARK, BuildingRecipe.ROLE_GLOW]
	var ok := true
	for i in 4:
		var pal := MeshBuilder.palette(i)
		for r in roles:
			if not pal.has(r):
				ok = false
	_check(ok, "every palette defines every role")
	_check(str(MeshBuilder.palette(0)) != str(MeshBuilder.palette(1)), "palettes differ")
	_check(str(MeshBuilder.palette(99)) == str(MeshBuilder.palette(3)), "out-of-range palette index clamps to the last")
	var plain := MeshBuilder.palette(0)
	_check(not plain.is_empty() and (plain[BuildingRecipe.ROLE_CONCRETE] as Color).get_luminance() > 0.6, "palette 0 is the light Plain palette")
	_check(str(MeshBuilder.default_palette()) == str(MeshBuilder.palette(0)), "default palette is palette 0")


func _test_prisms() -> void:
	var pal := MeshBuilder.default_palette()
	var gable := MeshBuilder.build_mesh([_part("prism", BuildingRecipe.ROLE_CONCRETE)], pal)
	_check(gable != null and _verts(gable).size() == 24, "gable prism has 24 vertices (3 sides + 2 caps)")
	var barn := _part("prism", BuildingRecipe.ROLE_CONCRETE)
	barn["profile"] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0.55, 0.65), Vector2(0, 1), Vector2(-0.55, 0.65)]
	var barn_mesh := MeshBuilder.build_mesh([barn], pal)
	_check(barn_mesh != null and _verts(barn_mesh).size() == 48, "barn prism has 48 vertices (5 sides + 2 caps)")
