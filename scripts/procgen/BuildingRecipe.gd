class_name BuildingRecipe
extends RefCounted

# Pure: params Dictionary -> Array of part Dictionaries. Deterministic for a given seed.
# Part: {"kind": "box"|"frustum"|"cylinder", "pos": Vector3, "size": Vector3, "role": String}
# Footprint is centred on origin: x in [-w/2, w/2], z in [-d/2, d/2], y up from 0.
# Front face is +z, the right face is +x (the two faces the isometric camera sees).
# Accents (awning, glow strip, windows, pillars, bands) may protrude past a face by up to AWNING_DEPTH.
# Roof items (units, chimneys, antenna) sit on the roof plateau, inside the footprint.
# Ground tanks stand against the +x face, reaching up to TANK_REACH past it.

const ROLE_CONCRETE := "concrete"
const ROLE_TRIM := "trim"
const ROLE_DARK := "dark"
const ROLE_GLOW := "glow"
const ROLE_WINDOW := "window"

const AWNING_DEPTH := 0.6
const TANK_REACH := 1.6
const BAND_HEIGHT := 0.2
const GLOW_DEPTH := 0.05
const WINDOW_DEPTH := 0.08
const WINDOW_LIT_CHANCE := 0.55

const ROOF_FLAT := 0
const ROOF_HIPPED := 1
const ROOF_STEPPED := 2


static func default_params() -> Dictionary:
	return {
		"seed": 1,
		"width": 8.0,
		"depth": 8.0,
		"height": 7.0,
		"tiers": 1,
		"setback": 0.15,
		"roof": ROOF_HIPPED,
		"awning": 0.5,
		"tanks": 0,
		"windows": 3,
		"roof_units": 2,
		"chimneys": 0,
		"antenna": 0,
		"pillars": 1,
		"bands": 1,
		"palette": 0,
	}


static func build(params: Dictionary) -> Array:
	var p := _normalize(params)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p["seed"])
	var parts: Array = []
	var w: float = p["width"]
	var d: float = p["depth"]
	var tiers: int = p["tiers"]
	var tier_h: float = float(p["height"]) / tiers
	var sb: float = p["setback"]
	var y := 0.0
	var top_w := w
	var top_d := d
	var cw := w
	var cd := d
	for i in tiers:
		parts.append(_box(Vector3(0, y + tier_h * 0.5, 0), Vector3(cw, tier_h, cd), ROLE_CONCRETE))
		top_w = cw
		top_d = cd
		y += tier_h
		if int(p["bands"]) > 0:
			parts.append(_box(Vector3(0, y - BAND_HEIGHT * 0.5, 0), Vector3(cw + 0.2, BAND_HEIGHT, cd + 0.2), ROLE_TRIM))
		cw *= 1.0 - sb
		cd *= 1.0 - sb
	var plateau := _add_roof(parts, p["roof"], y, top_w, top_d)
	var awning: float = p["awning"]
	var ah := 0.5 + 0.9 * awning
	if awning > 0.0:
		parts.append(_box(Vector3(0, ah * 0.5, d * 0.5 + AWNING_DEPTH * 0.5), Vector3(w * (0.4 + 0.5 * awning), ah, AWNING_DEPTH), ROLE_TRIM))
	parts.append(_box(Vector3(0, tier_h * 0.5, d * 0.5 + GLOW_DEPTH * 0.5), Vector3(w * 0.5, 0.12, GLOW_DEPTH), ROLE_GLOW))
	if int(p["pillars"]) > 0:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				parts.append(_box(Vector3(sx * (w * 0.5 - 0.1), tier_h * 0.5, sz * (d * 0.5 - 0.1)), Vector3(0.4, tier_h, 0.4), ROLE_TRIM))
	var tank_count: int = p["tanks"]
	for i in tank_count:
		# Tanks stand in a row against the right (+x) face, outside the body, so the iso camera sees them.
		var r := 0.45 + rng.randf() * 0.25
		var th := minf(1.5 + rng.randf() * 1.5, tier_h * 0.9)
		var x := w * 0.5 + r + 0.15
		var z := lerpf(-d * 0.3, d * 0.3, (float(i) + 0.5) / tank_count) + rng.randf_range(-0.03, 0.03) * d
		parts.append({"kind": "cylinder", "pos": Vector3(x, th * 0.5, z), "size": Vector3(r * 2.0, th, r * 2.0), "role": ROLE_DARK})
	_add_windows(parts, rng, int(p["windows"]), w, d, tier_h, ah)
	_add_roof_items(parts, rng, p, plateau)
	return parts


static func _normalize(params: Dictionary) -> Dictionary:
	var d := default_params()
	for k in params:
		d[k] = params[k]
	d["width"] = clampf(float(d["width"]), 4.0, 14.0)
	d["depth"] = clampf(float(d["depth"]), 4.0, 14.0)
	d["height"] = clampf(float(d["height"]), 2.0, 16.0)
	d["tiers"] = clampi(int(d["tiers"]), 1, 3)
	d["setback"] = clampf(float(d["setback"]), 0.0, 0.4)
	d["roof"] = clampi(int(d["roof"]), ROOF_FLAT, ROOF_STEPPED)
	d["awning"] = clampf(float(d["awning"]), 0.0, 1.0)
	d["tanks"] = clampi(int(d["tanks"]), 0, 4)
	d["windows"] = clampi(int(d["windows"]), 0, 6)
	d["roof_units"] = clampi(int(d["roof_units"]), 0, 4)
	d["chimneys"] = clampi(int(d["chimneys"]), 0, 3)
	d["antenna"] = clampi(int(d["antenna"]), 0, 1)
	d["pillars"] = clampi(int(d["pillars"]), 0, 1)
	d["bands"] = clampi(int(d["bands"]), 0, 1)
	d["palette"] = clampi(int(d["palette"]), 0, 2)
	d["seed"] = int(d["seed"])
	return d


# Returns the roof plateau: {"y": top surface, "w": width, "d": depth}.
static func _add_roof(parts: Array, roof: int, y: float, w: float, d: float) -> Dictionary:
	if roof == ROOF_HIPPED:
		parts.append({"kind": "frustum", "pos": Vector3(0, y + 0.6, 0), "size": Vector3(w, 1.2, d), "top": Vector2(w * 0.55, d * 0.55), "role": ROLE_CONCRETE})
		return {"y": y + 1.2, "w": w * 0.55, "d": d * 0.55}
	if roof == ROOF_STEPPED:
		parts.append(_box(Vector3(0, y + 0.075, 0), Vector3(w, 0.15, d), ROLE_TRIM))
		parts.append(_box(Vector3(0, y + 0.55, 0), Vector3(w * 0.6, 0.8, d * 0.6), ROLE_CONCRETE))
		return {"y": y + 0.95, "w": w * 0.6, "d": d * 0.6}
	parts.append(_box(Vector3(0, y + 0.075, 0), Vector3(w, 0.15, d), ROLE_TRIM))
	return {"y": y + 0.15, "w": w, "d": d}


# Window grid on the two faces the iso camera sees (+z and +x), on the base tier.
static func _add_windows(parts: Array, rng: RandomNumberGenerator, columns: int, w: float, d: float, tier_h: float, awning_h: float) -> void:
	if columns <= 0 or tier_h < 2.0:
		return
	var rows := mini(3, 1 + int(tier_h / 3.5))
	var y_min := maxf(awning_h + 0.65, tier_h * 0.35)
	var y_max := tier_h - 0.7
	if y_max < y_min:
		y_max = y_min
	for face in 2:
		var span := (w if face == 0 else d) * 0.7
		for c in columns:
			var along := -span * 0.5 + span * (float(c) + 0.5) / columns
			for r in rows:
				var wy := lerpf(y_min, y_max, (float(r) + 0.5) / rows)
				var role := ROLE_GLOW if rng.randf() < WINDOW_LIT_CHANCE else ROLE_WINDOW
				if face == 0:
					parts.append(_box(Vector3(along, wy, d * 0.5 + WINDOW_DEPTH * 0.5), Vector3(0.7, 0.9, WINDOW_DEPTH), role))
				else:
					parts.append(_box(Vector3(w * 0.5 + WINDOW_DEPTH * 0.5, wy, along), Vector3(WINDOW_DEPTH, 0.9, 0.7), role))


static func _add_roof_items(parts: Array, rng: RandomNumberGenerator, p: Dictionary, plateau: Dictionary) -> void:
	var top_y: float = plateau["y"]
	var pw: float = plateau["w"]
	var pd: float = plateau["d"]
	for i in int(p["roof_units"]):
		var sx := minf(0.6 + rng.randf() * 0.6, pw * 0.8)
		var sz := minf(0.6 + rng.randf() * 0.6, pd * 0.8)
		var sy := 0.4 + rng.randf() * 0.4
		var x := rng.randf_range(-1.0, 1.0) * (pw * 0.5 - sx * 0.5)
		var z := rng.randf_range(-1.0, 1.0) * (pd * 0.5 - sz * 0.5)
		parts.append(_box(Vector3(x, top_y + sy * 0.5, z), Vector3(sx, sy, sz), ROLE_DARK))
	for i in int(p["chimneys"]):
		var r := minf(0.2 + rng.randf() * 0.1, minf(pw, pd) * 0.3)
		var ch := 1.2 + rng.randf() * 0.8
		var x := rng.randf_range(-1.0, 1.0) * (pw * 0.5 - r)
		var z := rng.randf_range(-1.0, 1.0) * (pd * 0.5 - r)
		parts.append({"kind": "cylinder", "pos": Vector3(x, top_y + ch * 0.5, z), "size": Vector3(r * 2.0, ch, r * 2.0), "role": ROLE_DARK})
	if int(p["antenna"]) > 0:
		var ax := pw * 0.2
		var az := -pd * 0.2
		parts.append({"kind": "cylinder", "pos": Vector3(ax, top_y + 1.3, az), "size": Vector3(0.14, 2.6, 0.14), "role": ROLE_DARK})
		parts.append(_box(Vector3(ax, top_y + 2.7, az), Vector3(0.22, 0.22, 0.22), ROLE_GLOW))


static func _box(pos: Vector3, size: Vector3, role: String) -> Dictionary:
	return {"kind": "box", "pos": pos, "size": size, "role": role}
