class_name AssetWriter
extends RefCounted

# File output for a saved asset: out/<name>/model.glb, sprite.png, asset.json, LICENSE.txt.

static func default_root() -> String:
	return ProjectSettings.globalize_path("res://out")


# Returns {"error": Error, "dir": String}. `root` is the folder that will hold the asset folder.
static func save(root: String, params: Dictionary, mesh: ArrayMesh, sprite: Image) -> Dictionary:
	var dir := root.path_join(AssetExport.asset_name(params))
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return {"error": err, "dir": dir}
	err = _write_glb(dir.path_join(AssetExport.FILE_MODEL), mesh)
	if err != OK:
		return {"error": err, "dir": dir}
	err = sprite.save_png(dir.path_join(AssetExport.FILE_SPRITE))
	if err != OK:
		return {"error": err, "dir": dir}
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var triangles: int = verts.size() / 3
	var meta := AssetExport.metadata(params, sprite.get_size(), triangles)
	err = _write_text(dir.path_join(AssetExport.FILE_META), JSON.stringify(meta, "\t"))
	if err != OK:
		return {"error": err, "dir": dir}
	err = _write_text(dir.path_join(AssetExport.FILE_LICENSE), AssetExport.license_text())
	return {"error": err, "dir": dir}


static func _write_glb(path: String, mesh: ArrayMesh) -> Error:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	var root := Node3D.new()
	root.add_child(instance)
	var state := GLTFState.new()
	var doc := GLTFDocument.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, path)
	root.free()
	return err


static func _write_text(path: String, text: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK