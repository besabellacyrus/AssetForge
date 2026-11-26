class_name MedievalRecipe
extends RefCounted

# Pure: params Dictionary -> Array of part Dictionaries, same part format as BuildingRecipe.
# Lays out one of the 16 MedievalPresets. Deterministic for a given seed (the seed only nudges tower
# heights and crop placement). Front face is +z, right face is +x, y is up from 0.

const ROLE_STONE := "concrete"
const ROLE_STONE_DARK := "trim"
const ROLE_WOOD := "dark"
const ROLE_BANNER := "glow"
const ROLE_ROOF := "roof"
const ROLE_THATCH := "thatch"
const ROLE_CROP := "crop"
const ROLE_SOIL := "soil"

const ROOF_PITCH := 0.7
const EAVE := 0.6
const GABLE_OVERHANG := 0.4
const MERLON := Vector3(0.55, 0.5, 0.55)
const PLINTH := 0.25

const GABLE_PROFILE := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1)]
const THATCH_PROFILE := [Vector2(-1, 0), Vector2(1, 0), Vector2(0.85, 0.55), Vector2(0, 1), Vector2(-0.85, 0.55)]
const LEANTO_PROFILE := [Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1)]


static func build(p: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p["seed"])
	var ext := Vector3(float(p["width"]), float(p["height"]), float(p["depth"]))
	var parts: Array = []
	for piece: Dictionary in MedievalPresets.pieces(int(p["medieval"])):
		match piece["t"]:
			"block":
				_add_block(parts, piece, ext)
			"tower":
				_add_tower(parts, rng, piece, ext)
			"fence":
				_add_fence(parts, piece, ext)
			"crops":
				_add_crops(parts, rng, piece, ext)
			"leanto":
				_add_leanto(parts, piece, ext)
	return parts


# ---- blocks, roofs, battlements ----

static func _add_block(parts: Array, piece: Dictionary, ext: Vector3) -> void:
	var cx: float = float(piece["x"]) * ext.x * 0.5
	var cz: float = float(piece["z"]) * ext.z * 0.5
	var bw: float = float(piece["w"]) * ext.x
	var bd: float = float(piece["d"]) * ext.z
	var bh: float = float(piece["h"]) * ext.y
	var by: float = float(piece.get("y", 0.0)) * ext.y
	var top := by + bh
	parts.append(_box(Vector3(cx, by + bh * 0.5, cz), Vector3(bw, bh, bd), ROLE_STONE))
	parts.append(_box(Vector3(cx, by + PLINTH * 0.5, cz), Vector3(bw + 0.15, PLINTH, bd + 0.15), ROLE_STONE_DARK))
	if piece.get("crenel", false):
		_add_battlements(parts, cx, cz, bw, bd, top)
	if piece.get("timber", false):
		_add_timber(parts, cx, cz, bw, bd, by, bh)
	if piece.get("door", false):
		var dh := minf(1.7, bh * 0.8)
		parts.append(_box(Vector3(cx - bw * 0.15, by + dh * 0.5, cz + bd * 0.5 + 0.04), Vector3(1.0, dh, 0.1), ROLE_WOOD))
	var roof: String = piece.get("roof", "none")
	if roof == "none":
		return
	var ridge := String(piece.get("ridge", "x" if bw >= bd else "z"))
	var role := ROLE_THATCH if roof == "thatch" else ROLE_ROOF
	var profile: Array = THATCH_PROFILE if roof == "thatch" else GABLE_PROFILE
	var ridge_y := _add_gable(parts, cx, cz, bw, bd, top, ridge, role, profile)
	if roof == "cross":
		ridge_y = maxf(ridge_y, _add_gable(parts, cx, cz, bw, bd, top, "z" if ridge == "x" else "x", role, profile))
	if piece.get("chimney", false):
		var height := ridge_y + 0.8 - top
		parts.append(_box(Vector3(cx + bw * 0.3, top + height * 0.5, cz - bd * 0.15), Vector3(0.6, height, 0.6), ROLE_STONE_DARK))


# Adds a ridge roof over a block and returns the ridge height.
static func _add_gable(parts: Array, cx: float, cz: float, bw: float, bd: float, top: float, axis: String, role: String, profile: Array) -> float:
	var along_x := axis == "x"
	var length := bw if along_x else bd
	var across := bd if along_x else bw
	var rise := ROOF_PITCH * across * 0.5
	var size := Vector3(length + GABLE_OVERHANG, rise, across + EAVE) if along_x else Vector3(across + EAVE, rise, length + GABLE_OVERHANG)
	parts.append({"kind": "prism", "pos": Vector3(cx, top + rise * 0.5, cz), "size": size, "profile": profile.duplicate(), "axis": axis, "role": role})
	return top + rise


# Merlons around the top edge of a block, plus a dark floor inside (the open courtyard).
static func _add_battlements(parts: Array, cx: float, cz: float, bw: float, bd: float, top: float) -> void:
	var nx := maxi(3, int(bw / 1.0))
	var nz := maxi(3, int(bd / 1.0))
	var x0 := cx - bw * 0.5 + MERLON.x * 0.5
	var x1 := cx + bw * 0.5 - MERLON.x * 0.5
	var z0 := cz - bd * 0.5 + MERLON.z * 0.5
	var z1 := cz + bd * 0.5 - MERLON.z * 0.5
	for i in nx:
		var x := lerpf(x0, x1, float(i) / (nx - 1))
		parts.append(_box(Vector3(x, top + MERLON.y * 0.5, z0), MERLON, ROLE_STONE_DARK))
		parts.append(_box(Vector3(x, top + MERLON.y * 0.5, z1), MERLON, ROLE_STONE_DARK))
	for i in range(1, nz - 1):
		var z := lerpf(z0, z1, float(i) / (nz - 1))
		parts.append(_box(Vector3(x0, top + MERLON.y * 0.5, z), MERLON, ROLE_STONE_DARK))
		parts.append(_box(Vector3(x1, top + MERLON.y * 0.5, z), MERLON, ROLE_STONE_DARK))
	parts.append(_box(Vector3(cx, top + 0.02, cz), Vector3(bw - 1.1, 0.04, bd - 1.1), ROLE_WOOD))


# Dark half-timber beams on the front and right faces.
static func _add_timber(parts: Array, cx: float, cz: float, bw: float, bd: float, by: float, bh: float) -> void:
	var front := cz + bd * 0.5 + 0.03
	var right := cx + bw * 0.5 + 0.03
	for i in 4:
		parts.append(_box(Vector3(cx - bw * 0.4 + bw * 0.8 * i / 3.0, by + bh * 0.5, front), Vector3(0.16, bh, 0.08), ROLE_WOOD))
	for i in 3:
		parts.append(_box(Vector3(right, by + bh * 0.5, cz - bd * 0.4 + bd * 0.8 * i / 2.0), Vector3(0.08, bh, 0.16), ROLE_WOOD))
	parts.append(_box(Vector3(cx, by + bh * 0.55, front), Vector3(bw, 0.14, 0.08), ROLE_WOOD))
	parts.append(_box(Vector3(right, by + bh * 0.55, cz), Vector3(0.08, 0.14, bd), ROLE_WOOD))


# ---- towers ----

static func _add_tower(parts: Array, rng: RandomNumberGenerator, piece: Dictionary, ext: Vector3) -> void:
	var cx: float = float(piece["x"]) * ext.x * 0.5
	var cz: float = float(piece["z"]) * ext.z * 0.5
	var r: float = float(piece["r"]) * minf(ext.x, ext.z)
	var th: float = float(piece["h"]) * ext.y * (1.0 + rng.randf_range(-0.06, 0.06))
	parts.append({"kind": "cylinder", "pos": Vector3(cx, th * 0.5, cz), "size": Vector3(r * 2.0, th, r * 2.0), "role": ROLE_STONE})
	parts.append({"kind": "cylinder", "pos": Vector3(cx, PLINTH * 0.5, cz), "size": Vector3(r * 2.0 + 0.3, PLINTH, r * 2.0 + 0.3), "role": ROLE_STONE_DARK})
	var banner: bool = piece.get("banner", false)
	match piece["cap"]:
		"cone":
			var cone_h := r * 2.4
			var cone_r := r * 1.25
			parts.append({"kind": "cylinder", "pos": Vector3(cx, th - 0.1, cz), "size": Vector3(r * 2.0 + 0.2, 0.2, r * 2.0 + 0.2), "role": ROLE_STONE_DARK})
			parts.append({"kind": "cone", "pos": Vector3(cx, th + cone_h * 0.5, cz), "size": Vector3(cone_r * 2.0, cone_h, cone_r * 2.0), "role": ROLE_ROOF})
			if banner:
				var apex := th + cone_h
				parts.append({"kind": "cylinder", "pos": Vector3(cx, apex + 0.75, cz), "size": Vector3(0.12, 1.5, 0.12), "role": ROLE_WOOD})
				parts.append(_box(Vector3(cx + 0.45, apex + 1.2, cz), Vector3(0.8, 0.4, 0.05), ROLE_BANNER))
		"open":
			parts.append({"kind": "cylinder", "pos": Vector3(cx, th + 0.03, cz), "size": Vector3(r * 1.6, 0.06, r * 1.6), "role": ROLE_WOOD})
			for i in 8:
				var a := TAU * float(i) / 8.0
				parts.append(_box(Vector3(cx + cos(a) * r * 0.85, th + MERLON.y * 0.4, cz + sin(a) * r * 0.85), Vector3(0.42, 0.5, 0.42), ROLE_STONE_DARK))
			if banner:
				parts.append(_box(Vector3(cx, th * 0.65, cz + r + 0.03), Vector3(0.55, 1.1, 0.06), ROLE_BANNER))


# ---- yard details ----

static func _add_fence(parts: Array, piece: Dictionary, ext: Vector3) -> void:
	var cx: float = float(piece["x"]) * ext.x * 0.5
	var cz: float = float(piece["z"]) * ext.z * 0.5
	var hw: float = float(piece["w"]) * ext.x * 0.5
	var hd: float = float(piece["d"]) * ext.z * 0.5
	var sides: String = piece["sides"]
	if "f" in sides:
		_fence_run(parts, Vector2(cx - hw, cz + hd), Vector2(cx + hw, cz + hd))
	if "b" in sides:
		_fence_run(parts, Vector2(cx - hw, cz - hd), Vector2(cx + hw, cz - hd))
	if "l" in sides:
		_fence_run(parts, Vector2(cx - hw, cz - hd), Vector2(cx - hw, cz + hd))
	if "r" in sides:
		_fence_run(parts, Vector2(cx + hw, cz - hd), Vector2(cx + hw, cz + hd))


static func _fence_run(parts: Array, a: Vector2, b: Vector2) -> void:
	var length := a.distance_to(b)
	var n := maxi(1, ceili(length / 0.9))
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		parts.append(_box(Vector3(q.x, 0.4, q.y), Vector3(0.14, 0.8, 0.14), ROLE_WOOD))
	var mid := (a + b) * 0.5
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	for y in [0.6, 0.3]:
		var size := Vector3(length, 0.08, 0.06) if along_x else Vector3(0.06, 0.08, length)
		parts.append(_box(Vector3(mid.x, y, mid.y), size, ROLE_WOOD))


static func _add_crops(parts: Array, rng: RandomNumberGenerator, piece: Dictionary, ext: Vector3) -> void:
	var cx: float = float(piece["x"]) * ext.x * 0.5
	var cz: float = float(piece["z"]) * ext.z * 0.5
	var cw: float = float(piece["w"]) * ext.x
	var cd: float = float(piece["d"]) * ext.z
	parts.append(_box(Vector3(cx, 0.05, cz), Vector3(cw, 0.1, cd), ROLE_SOIL))
	var cols := maxi(2, int(cw / 0.9))
	var rows := maxi(2, int(cd / 0.9))
	for row in rows:
		for col in cols:
			var x := cx - cw * 0.5 + cw * (float(col) + 0.5) / cols + rng.randf_range(-0.08, 0.08)
			var z := cz - cd * 0.5 + cd * (float(row) + 0.5) / rows + rng.randf_range(-0.08, 0.08)
			var s := 0.4 + rng.randf() * 0.15
			parts.append({"kind": "cylinder", "pos": Vector3(x, 0.1 + s * 0.4, z), "size": Vector3(s, s * 0.8, s), "role": ROLE_CROP})


# A thatch wedge: tall side on the left (-x), sloping down to the right. Leans on a wall to its left.
static func _add_leanto(parts: Array, piece: Dictionary, ext: Vector3) -> void:
	var cx: float = float(piece["x"]) * ext.x * 0.5
	var cz: float = float(piece["z"]) * ext.z * 0.5
	var lw: float = float(piece["w"]) * ext.x
	var ld: float = float(piece["d"]) * ext.z
	var lh: float = float(piece["h"]) * ext.y
	parts.append({"kind": "prism", "pos": Vector3(cx, lh * 0.5, cz), "size": Vector3(lw, lh, ld), "profile": LEANTO_PROFILE.duplicate(), "axis": "z", "role": ROLE_THATCH})


static func _box(pos: Vector3, size: Vector3, role: String) -> Dictionary:
	return {"kind": "box", "pos": pos, "size": size, "role": role}
