class_name RandomBuilding
extends RefCounted

# Pure: rolls a random but sensible set of building settings. Same seed gives the same roll.
# Every value stays inside its ParamSpec range. Optional extras (fins, tanks, chimneys...) are
# often left off so most rolls read as clean buildings.

const CHANCE_EXTRA := 0.3


static func roll(seed: int, style: int = BuildingRecipe.STYLE_FACTORY) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var p := BuildingRecipe.default_params()
	p["seed"] = rng.randi_range(1, 9999)
	if style == BuildingRecipe.STYLE_MEDIEVAL:
		return _roll_medieval(rng, p)
	p["plan"] = _pick(rng, [BuildingRecipe.PLAN_BOX, BuildingRecipe.PLAN_BOX, BuildingRecipe.PLAN_L, BuildingRecipe.PLAN_T, BuildingRecipe.PLAN_U])
	p["wing"] = snappedf(rng.randf_range(0.3, 0.5), 0.05)
	p["width"] = snappedf(rng.randf_range(6.0, 12.0), 0.5)
	p["depth"] = snappedf(rng.randf_range(6.0, 12.0), 0.5)
	p["height"] = snappedf(rng.randf_range(3.0, 12.0), 0.5)
	p["tiers"] = rng.randi_range(1, 3)
	p["setback"] = snappedf(rng.randf_range(0.0, 0.3), 0.01)
	p["offset"] = 1 if rng.randf() < CHANCE_EXTRA and int(p["tiers"]) > 1 else 0
	p["roof"] = rng.randi_range(0, 4)
	p["pitch"] = snappedf(rng.randf_range(0.4, 0.9), 0.05)
	p["awning"] = snappedf(rng.randf_range(0.0, 1.0), 0.05)
	p["fins"] = _extra(rng, 2, 4)
	p["front_units"] = _extra(rng, 1, 3)
	p["tanks"] = _extra(rng, 1, 3)
	p["roof_units"] = rng.randi_range(0, 3)
	p["chimneys"] = _extra(rng, 1, 2)
	p["antenna"] = 1 if rng.randf() < CHANCE_EXTRA else 0
	p["pillars"] = 1 if rng.randf() < 0.6 else 0
	p["bands"] = 1 if rng.randf() < 0.7 else 0
	p["palette"] = rng.randi_range(0, 3)
	return p


static func _pick(rng: RandomNumberGenerator, options: Array) -> Variant:
	return options[rng.randi_range(0, options.size() - 1)]


# Off most of the time. When on, a whole count between lo and hi.
static func _extra(rng: RandomNumberGenerator, lo: int, hi: int) -> int:
	if rng.randf() >= CHANCE_EXTRA:
		return 0
	return rng.randi_range(lo, hi)


# Medieval: a random preset, size and roof colour, inked.
static func _roll_medieval(rng: RandomNumberGenerator, p: Dictionary) -> Dictionary:
	p["style"] = BuildingRecipe.STYLE_MEDIEVAL
	p["medieval"] = rng.randi_range(0, MedievalPresets.COUNT - 1)
	p["width"] = snappedf(rng.randf_range(6.0, 12.0), 0.5)
	p["depth"] = snappedf(rng.randf_range(6.0, 12.0), 0.5)
	p["height"] = snappedf(rng.randf_range(5.0, 10.0), 0.5)
	p["palette"] = rng.randi_range(0, 3)
	p["outline"] = 1
	return p