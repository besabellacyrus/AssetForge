class_name BuildingRecipe
extends RefCounted

# Pure: params Dictionary -> Array of part Dictionaries. Deterministic for a given seed.
# Part: {"kind": "box"|"frustum"|"cylinder"|"prism", "pos": Vector3, "size": Vector3, "role": String}
#   frustum adds "top": Vector2 (top face size). prism adds "profile": Array[Vector2] (x in [-1, 1]
#   across the ridge, y in [0, 1] up) and "axis": "x"|"z" (ridge direction).
# Footprint is centred on origin: x in [-w/2, w/2], z in [-d/2, d/2], y up from 0.
# Front face is +z, the right face is +x (the two faces the isometric camera sees).
# The plan is a set of wing rectangles (Rect2 in x/z). Tiers and setbacks apply to the Box plan only.
# Accents (awning, glow strip, pillars, bands, fins, front units) may protrude by up to AWNING_DEPTH.
# Roof items (units, chimneys, antenna) stay on the first top rectangle, inside the footprint.
# Ground tanks stand against the right face, reaching up to TANK_REACH past it.

const ROLE_CONCRETE := "concrete"
const ROLE_TRIM := "trim"
const ROLE_DARK := "dark"
const ROLE_GLOW := "glow"

const AWNING_DEPTH := 0.6
const TANK_REACH := 1.6
const BAND_HEIGHT := 0.2
const GLOW_DEPTH := 0.05
const FIN_DEPTH := 0.35
const FIN_INSET := 0.05

const STYLE_FACTORY := 0
const STYLE_MEDIEVAL := 1

const ROOF_FLAT := 0
const ROOF_HIPPED := 1
const ROOF_STEPPED := 2
const ROOF_GABLE := 3
const ROOF_BARN := 4

const PLAN_BOX := 0
const PLAN_L := 1
const PLAN_T := 2
const PLAN_U := 3

const GABLE_PROFILE := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1)]
const BARN_PROFILE := [Vector2(-1, 0), Vector2(1, 0), Vector2(0.55, 0.65), Vector2(0, 1), Vector2(-0.55, 0.65)]


static func default_params() -> Dictionary:
	return {
		"style": STYLE_FACTORY,
		"medieval": 0,
		"outline": 0,
		"seed": 1,
		"width": 8.0,
		"depth": 8.0,
		"height": 7.0,
		"plan": PLAN_BOX,
		"wing": 0.4,
		"tiers": 1,
		"setback": 0.15,
		"offset": 0,
		"roof": ROOF_HIPPED,
		"pitch": 0.6,
		"awning": 0.5,
		"tanks": 0,
		"fins": 0,
		"front_units": 0,
		"roof_units": 2,
		"chimneys": 0,
		"antenna": 0,
		"pillars": 1,
		"bands": 1,
		"palette": 0,
	}


static func build(params: Dictionary) -> Array:
	var p := _normalize(params)
	if p["style"] == STYLE_MEDIEVAL:
		return MedievalRecipe.build(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p["seed"])
	var parts: Array = []
	var w: float = p["width"]
	var d: float = p["depth"]
	var plan: int = p["plan"]
	var tiers: int = p["tiers"] if plan == PLAN_BOX else 1
	var tier_h: float = float(p["height"]) / tiers

	var base_rects: Array = _plan_rects(plan, w, d, p["wing"])
	var top_rects: Array = base_rects
	var y := 0.0
	if plan == PLAN_BOX:
		var cw := w
		var cd := d
		for i in tiers:
			var rect := Rect2(-w * 0.5, -d * 0.5, cw, cd) if int(p["offset"]) > 0 else Rect2(-cw * 0.5, -cd * 0.5, cw, cd)
			_add_body(parts, rect, y, tier_h, int(p["bands"]) > 0)
			top_rects = [rect]
			if i == 0:
				base_rects = [rect]
			y += tier_h
			cw *= 1.0 - float(p["setback"])
			cd *= 1.0 - float(p["setback"])
	else:
		for rect: Rect2 in base_rects:
			_add_body(parts, rect, 0.0, tier_h, int(p["bands"]) > 0)
		y = tier_h

	var plateau := {}
	for i in top_rects.size():
		var roof_info := _add_roof(parts, p["roof"], y, top_rects[i], p["pitch"])
		if i == 0:
			plateau = roof_info

	var front := _front_rect(base_rects)
	_add_front_accents(parts, p, front, tier_h)
	if int(p["pillars"]) > 0:
		for rect: Rect2 in base_rects:
			_add_pillars(parts, rect, tier_h)
	_add_tanks(parts, rng, int(p["tanks"]), _right_rect(base_rects), tier_h)
	_add_roof_items(parts, rng, p, plateau)
	return parts


static func _normalize(params: Dictionary) -> Dictionary:
	var d := default_params()
	for k in params:
		if d.has(k):
			d[k] = params[k]
	d["style"] = clampi(int(d["style"]), STYLE_FACTORY, STYLE_MEDIEVAL)
	d["medieval"] = clampi(int(d["medieval"]), 0, MedievalPresets.COUNT - 1)
	d["outline"] = clampi(int(d["outline"]), 0, 1)
	d["width"] = clampf(float(d["width"]), 4.0, 14.0)
	d["depth"] = clampf(float(d["depth"]), 4.0, 14.0)
	d["height"] = clampf(float(d["height"]), 2.0, 16.0)
	d["plan"] = clampi(int(d["plan"]), PLAN_BOX, PLAN_U)
	d["wing"] = clampf(float(d["wing"]), 0.25, 0.6)
	d["tiers"] = clampi(int(d["tiers"]), 1, 3)
	d["setback"] = clampf(float(d["setback"]), 0.0, 0.4)
	d["offset"] = clampi(int(d["offset"]), 0, 1)
	d["roof"] = clampi(int(d["roof"]), ROOF_FLAT, ROOF_BARN)
	d["pitch"] = clampf(float(d["pitch"]), 0.2, 1.0)
	d["awning"] = clampf(float(d["awning"]), 0.0, 1.0)
	d["tanks"] = clampi(int(d["tanks"]), 0, 4)
	d["fins"] = clampi(int(d["fins"]), 0, 6)
	d["front_units"] = clampi(int(d["front_units"]), 0, 4)
	d["roof_units"] = clampi(int(d["roof_units"]), 0, 4)
	d["chimneys"] = clampi(int(d["chimneys"]), 0, 3)
	d["antenna"] = clampi(int(d["antenna"]), 0, 1)
	d["pillars"] = clampi(int(d["pillars"]), 0, 1)
	d["bands"] = clampi(int(d["bands"]), 0, 1)
	d["palette"] = clampi(int(d["palette"]), 0, 3)
	d["seed"] = int(d["seed"])
	return d


# Wing rectangles in x/z. The back bar runs along the back (-z); legs run toward the front (+z).
static func _plan_rects(plan: int, w: float, d: float, wing: float) -> Array:
	var x0 := -w * 0.5
	var z0 := -d * 0.5
	var bar_d := d * wing
	var leg_d := d - bar_d
	match plan:
		PLAN_L:
			return [Rect2(x0, z0, w, bar_d), Rect2(x0, z0 + bar_d, w * wing, leg_d)]
		PLAN_T:
			return [Rect2(x0, z0, w, bar_d), Rect2(-w * wing * 0.5, z0 + bar_d, w * wing, leg_d)]
		PLAN_U:
			var leg_w := w * wing * 0.75
			return [Rect2(x0, z0, w, bar_d), Rect2(x0, z0 + bar_d, leg_w, leg_d), Rect2(w * 0.5 - leg_w, z0 + bar_d, leg_w, leg_d)]
	return [Rect2(x0, z0, w, d)]


static func _add_body(parts: Array, rect: Rect2, y: float, h: float, band: bool) -> void:
	var c := rect.get_center()
	parts.append(_box(Vector3(c.x, y + h * 0.5, c.y), Vector3(rect.size.x, h, rect.size.y), ROLE_CONCRETE))
	if band:
		parts.append(_box(Vector3(c.x, y + h - BAND_HEIGHT * 0.5, c.y), Vector3(rect.size.x + 0.2, BAND_HEIGHT, rect.size.y + 0.2), ROLE_TRIM))


# Returns roof info: {"y": surface for roof items, "rect": Rect2 they may use, "sloped": bool, "ridge_y": float, "axis": String}.
static func _add_roof(parts: Array, roof: int, y: float, rect: Rect2, pitch: float) -> Dictionary:
	var c := rect.get_center()
	var w := rect.size.x
	var d := rect.size.y
	if roof == ROOF_GABLE or roof == ROOF_BARN:
		var axis := "x" if w >= d else "z"
		var roof_h := pitch * minf(w, d) * 0.5
		var profile: Array = GABLE_PROFILE if roof == ROOF_GABLE else BARN_PROFILE
		parts.append({"kind": "prism", "pos": Vector3(c.x, y + roof_h * 0.5, c.y), "size": Vector3(w, roof_h, d), "profile": profile.duplicate(), "axis": axis, "role": ROLE_CONCRETE})
		return {"y": y, "rect": rect, "sloped": true, "ridge_y": y + roof_h, "axis": axis}
	if roof == ROOF_HIPPED:
		parts.append({"kind": "frustum", "pos": Vector3(c.x, y + 0.6, c.y), "size": Vector3(w, 1.2, d), "top": Vector2(w * 0.55, d * 0.55), "role": ROLE_CONCRETE})
		return {"y": y + 1.2, "rect": _scaled(rect, 0.55), "sloped": false}
	if roof == ROOF_STEPPED:
		parts.append(_box(Vector3(c.x, y + 0.075, c.y), Vector3(w, 0.15, d), ROLE_TRIM))
		parts.append(_box(Vector3(c.x, y + 0.55, c.y), Vector3(w * 0.6, 0.8, d * 0.6), ROLE_CONCRETE))
		return {"y": y + 0.95, "rect": _scaled(rect, 0.6), "sloped": false}
	parts.append(_box(Vector3(c.x, y + 0.075, c.y), Vector3(w, 0.15, d), ROLE_TRIM))
	return {"y": y + 0.15, "rect": rect, "sloped": false}


static func _scaled(rect: Rect2, k: float) -> Rect2:
	var size := rect.size * k
	return Rect2(rect.get_center() - size * 0.5, size)


# The wing whose front edge is furthest forward (first one wins a tie).
static func _front_rect(rects: Array) -> Rect2:
	var best: Rect2 = rects[0]
	for r: Rect2 in rects:
		if r.end.y > best.end.y + 0.001:
			best = r
	return best


# The wing whose right edge is furthest right (first one wins a tie).
static func _right_rect(rects: Array) -> Rect2:
	var best: Rect2 = rects[0]
	for r: Rect2 in rects:
		if r.end.x > best.end.x + 0.001:
			best = r
	return best


static func _add_front_accents(parts: Array, p: Dictionary, rect: Rect2, tier_h: float) -> void:
	var cx := rect.get_center().x
	var fw := rect.size.x
	var front := rect.end.y
	var awning: float = p["awning"]
	if awning > 0.0:
		var ah := 0.5 + 0.9 * awning
		parts.append(_box(Vector3(cx, ah * 0.5, front + AWNING_DEPTH * 0.5), Vector3(fw * (0.4 + 0.5 * awning), ah, AWNING_DEPTH), ROLE_TRIM))
	parts.append(_box(Vector3(cx, tier_h * 0.5, front + GLOW_DEPTH * 0.5), Vector3(fw * 0.5, 0.12, GLOW_DEPTH), ROLE_GLOW))
	var fins: int = p["fins"]
	for i in fins:
		var fx := cx - fw * 0.4 + fw * 0.8 * (float(i) + 0.5) / fins
		parts.append(_box(Vector3(fx, tier_h * 0.5, front - FIN_INSET + FIN_DEPTH * 0.5), Vector3(0.25, tier_h, FIN_DEPTH), ROLE_TRIM))
	var units: int = p["front_units"]
	for i in units:
		var ux := cx - fw * 0.4 + fw * 0.8 * (float(i) + 0.5) / units
		parts.append(_box(Vector3(ux, 0.275, front + 0.3), Vector3(minf(0.9, fw * 0.8 / units), 0.55, 0.5), ROLE_TRIM))


static func _add_pillars(parts: Array, rect: Rect2, h: float) -> void:
	for x in [rect.position.x + 0.1, rect.end.x - 0.1]:
		for z in [rect.position.y + 0.1, rect.end.y - 0.1]:
			parts.append(_box(Vector3(x, h * 0.5, z), Vector3(0.4, h, 0.4), ROLE_TRIM))


# Tanks stand in a row against the right (+x) face of the rightmost wing, so the iso camera sees them.
static func _add_tanks(parts: Array, rng: RandomNumberGenerator, count: int, rect: Rect2, tier_h: float) -> void:
	for i in count:
		var r := 0.45 + rng.randf() * 0.25
		var th := minf(1.5 + rng.randf() * 1.5, tier_h * 0.9)
		var x := rect.end.x + r + 0.15
		var t := (float(i) + 0.5) / count
		var z := lerpf(rect.position.y + rect.size.y * 0.2, rect.end.y - rect.size.y * 0.2, t) + rng.randf_range(-0.03, 0.03) * rect.size.y
		parts.append({"kind": "cylinder", "pos": Vector3(x, th * 0.5, z), "size": Vector3(r * 2.0, th, r * 2.0), "role": ROLE_DARK})


static func _add_roof_items(parts: Array, rng: RandomNumberGenerator, p: Dictionary, roof: Dictionary) -> void:
	var rect: Rect2 = roof["rect"]
	var c := rect.get_center()
	var pw := rect.size.x
	var pd := rect.size.y
	var base_y: float = roof["y"]
	var sloped: bool = roof["sloped"]
	# Sloped roofs have no flat surface, so they carry no roof units.
	if not sloped:
		for i in int(p["roof_units"]):
			var sx := minf(0.6 + rng.randf() * 0.6, pw * 0.8)
			var sz := minf(0.6 + rng.randf() * 0.6, pd * 0.8)
			var sy := 0.4 + rng.randf() * 0.4
			var x := c.x + rng.randf_range(-1.0, 1.0) * (pw * 0.5 - sx * 0.5)
			var z := c.y + rng.randf_range(-1.0, 1.0) * (pd * 0.5 - sz * 0.5)
			parts.append(_box(Vector3(x, base_y + sy * 0.5, z), Vector3(sx, sy, sz), ROLE_DARK))
	var rise: float = float(roof["ridge_y"]) - base_y if sloped else 0.0
	for i in int(p["chimneys"]):
		var r := minf(0.2 + rng.randf() * 0.1, minf(pw, pd) * 0.3)
		var ch := rise + 1.2 + rng.randf() * 0.8
		var x := c.x + rng.randf_range(-1.0, 1.0) * (pw * 0.5 - r)
		var z := c.y + rng.randf_range(-1.0, 1.0) * (pd * 0.5 - r)
		parts.append({"kind": "cylinder", "pos": Vector3(x, base_y + ch * 0.5, z), "size": Vector3(r * 2.0, ch, r * 2.0), "role": ROLE_DARK})
	if int(p["antenna"]) > 0:
		var ax := c.x + pw * 0.2
		var az := c.y - pd * 0.2
		var ay := base_y
		if sloped:
			# Stand on the ridge line, part way along it.
			ay = roof["ridge_y"]
			if roof["axis"] == "x":
				az = c.y
			else:
				ax = c.x
		parts.append({"kind": "cylinder", "pos": Vector3(ax, ay + 1.3, az), "size": Vector3(0.14, 2.6, 0.14), "role": ROLE_DARK})
		parts.append(_box(Vector3(ax, ay + 2.7, az), Vector3(0.22, 0.22, 0.22), ROLE_GLOW))


static func _box(pos: Vector3, size: Vector3, role: String) -> Dictionary:
	return {"kind": "box", "pos": pos, "size": size, "role": role}
