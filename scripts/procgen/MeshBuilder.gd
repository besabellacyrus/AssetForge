class_name MeshBuilder
extends RefCounted

# Pure geometry: recipe parts -> ArrayMesh. One surface, flat normals, vertex colours from roles.
# Triangles are not indexed (6 verts per quad) so every face keeps its own flat normal.

const CYL_SEGMENTS := 8


const PALETTES := [
	{"concrete": "8b9097", "trim": "d4b53a", "dark": "3a3f47", "glow": "22d3ee", "window": "2b4a63"},
	{"concrete": "a9b4c0", "trim": "5f7a96", "dark": "2b3440", "glow": "7dd3fc", "window": "1e3a5f"},
	{"concrete": "9a8f86", "trim": "c2410c", "dark": "3b2f2a", "glow": "fbbf24", "window": "3d2b24"},
]


static func palette(index: int) -> Dictionary:
	var src: Dictionary = PALETTES[clampi(index, 0, PALETTES.size() - 1)]
	var out := {}
	for role: String in src:
		out[role] = Color(src[role])
	return out


static func default_palette() -> Dictionary:
	return palette(0)


static func build_mesh(parts: Array, palette: Dictionary) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	for part: Dictionary in parts:
		var col: Color = palette.get(part["role"], Color.MAGENTA)
		var tris: Array = _part_triangles(part)
		for tri: Array in tris:
			# Godot front faces are clockwise, so reverse the counter-clockwise helpers' order.
			for i in [0, 2, 1]:
				verts.append(tri[i])
				normals.append(tri[3])
				colours.append(col)
	if verts.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# Each triangle is [a, b, c, normal] with normal already pointing out of the part.
static func _part_triangles(part: Dictionary) -> Array:
	var pos: Vector3 = part["pos"]
	var size: Vector3 = part["size"]
	var h := size * 0.5
	match part["kind"]:
		"box":
			return _box_tris(pos, h)
		"frustum":
			var top: Vector2 = part["top"]
			return _frustum_tris(pos, size, top * 0.5)
		"cylinder":
			return _cylinder_tris(pos, size)
	return []


static func _box_tris(pos: Vector3, h: Vector3) -> Array:
	var out: Array = []
	var faces := [
		[Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(1, -1, 1)],
		[Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, -1)],
		[Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(-1, -1, -1)],
		[Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
	]
	for face: Array in faces:
		var c: Array = []
		var mid := Vector3.ZERO
		for corner: Vector3 in face:
			var world := pos + corner * h
			c.append(world)
			mid += world
		mid /= 4.0
		out.append_array(_quad(c[0], c[1], c[2], c[3], mid - pos))
	return out


static func _frustum_tris(pos: Vector3, size: Vector3, top_half: Vector2) -> Array:
	var out: Array = []
	var hw := size.x * 0.5
	var hd := size.z * 0.5
	var y0 := pos.y - size.y * 0.5
	var y1 := pos.y + size.y * 0.5
	var ring := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var bottom: Array = []
	var top: Array = []
	for r: Vector2 in ring:
		bottom.append(Vector3(pos.x + r.x * hw, y0, pos.z + r.y * hd))
		top.append(Vector3(pos.x + r.x * top_half.x, y1, pos.z + r.y * top_half.y))
	for i in 4:
		var j := (i + 1) % 4
		var mid: Vector3 = (bottom[i] + bottom[j] + top[j] + top[i]) * 0.25
		out.append_array(_quad(bottom[i], bottom[j], top[j], top[i], mid - pos))
	out.append_array(_quad(top[0], top[1], top[2], top[3], Vector3.UP))
	out.append_array(_quad(bottom[0], bottom[1], bottom[2], bottom[3], Vector3.DOWN))
	return out


static func _cylinder_tris(pos: Vector3, size: Vector3) -> Array:
	var out: Array = []
	var rx := size.x * 0.5
	var rz := size.z * 0.5
	var y0 := pos.y - size.y * 0.5
	var y1 := pos.y + size.y * 0.5
	var centre_top := Vector3(pos.x, y1, pos.z)
	var centre_bottom := Vector3(pos.x, y0, pos.z)
	for i in CYL_SEGMENTS:
		var a0 := TAU * float(i) / CYL_SEGMENTS
		var a1 := TAU * float(i + 1) / CYL_SEGMENTS
		var b0 := Vector3(pos.x + cos(a0) * rx, y0, pos.z + sin(a0) * rz)
		var b1 := Vector3(pos.x + cos(a1) * rx, y0, pos.z + sin(a1) * rz)
		var t0 := Vector3(b0.x, y1, b0.z)
		var t1 := Vector3(b1.x, y1, b1.z)
		var mid := (b0 + b1 + t0 + t1) * 0.25
		out.append_array(_quad(b0, b1, t1, t0, mid - pos))
		out.append_array(_tri(centre_top, t0, t1, Vector3.UP))
		out.append_array(_tri(centre_bottom, b1, b0, Vector3.DOWN))
	return out


# Two triangles for a quad, wound so the normal faces the hint direction.
static func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, hint: Vector3) -> Array:
	var n := (b - a).cross(c - a).normalized()
	var q := [a, b, c, d]
	if n.dot(hint) < 0.0:
		n = -n
		q = [a, d, c, b]
	return [[q[0], q[1], q[2], n], [q[0], q[2], q[3], n]]


static func _tri(a: Vector3, b: Vector3, c: Vector3, hint: Vector3) -> Array:
	var n := (b - a).cross(c - a).normalized()
	if n.dot(hint) < 0.0:
		n = -n
		return [[a, c, b, n]]
	return [[a, b, c, n]]
