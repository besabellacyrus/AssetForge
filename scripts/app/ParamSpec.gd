class_name ParamSpec
extends RefCounted

# Pure: slider ranges and value labels for the asset app. Keys match BuildingRecipe.default_params().

const ROOF_NAMES := ["Flat", "Hipped", "Stepped", "Gable", "Barn"]
const PLAN_NAMES := ["Box", "L", "T", "U"]
const PALETTE_NAMES := ["Plain", "Industrial", "Steel", "Rust"]
const MEDIEVAL_PALETTE_NAMES := ["Blue roofs", "Red roofs", "Green roofs", "Purple roofs"]
const STYLE_NAMES := ["Factory", "Medieval"]
# Sliders the medieval style uses. The rest only apply to the factory style.
const MEDIEVAL_KEYS := ["style", "medieval", "outline", "seed", "width", "depth", "height", "palette"]
const WHOLE_KEYS := ["seed", "tiers", "tanks", "fins", "front_units", "roof_units", "chimneys"]
const TOGGLE_KEYS := ["offset", "antenna", "pillars", "bands", "outline"]


static func specs() -> Array:
	return [
		{"key": "style", "label": "Style", "min": 0, "max": 1, "step": 1, "default": 0},
		{"key": "medieval", "label": "Medieval building", "min": 0, "max": MedievalPresets.COUNT - 1, "step": 1, "default": 0},
		{"key": "outline", "label": "Ink outline", "min": 0, "max": 1, "step": 1, "default": 0},
		{"key": "seed", "label": "Seed", "min": 1, "max": 9999, "step": 1, "default": 1},
		{"key": "plan", "label": "Plan", "min": 0, "max": 3, "step": 1, "default": 0},
		{"key": "wing", "label": "Wing thickness", "min": 0.25, "max": 0.6, "step": 0.05, "default": 0.4},
		{"key": "width", "label": "Width", "min": 4, "max": 14, "step": 0.5, "default": 8.0},
		{"key": "depth", "label": "Depth", "min": 4, "max": 14, "step": 0.5, "default": 8.0},
		{"key": "height", "label": "Height", "min": 2, "max": 16, "step": 0.5, "default": 7.0},
		{"key": "tiers", "label": "Tiers (Box plan)", "min": 1, "max": 3, "step": 1, "default": 1},
		{"key": "setback", "label": "Setback", "min": 0, "max": 0.4, "step": 0.01, "default": 0.15},
		{"key": "offset", "label": "Offset setback", "min": 0, "max": 1, "step": 1, "default": 0},
		{"key": "roof", "label": "Roof", "min": 0, "max": 4, "step": 1, "default": 1},
		{"key": "pitch", "label": "Roof pitch", "min": 0.2, "max": 1.0, "step": 0.05, "default": 0.6},
		{"key": "awning", "label": "Awning", "min": 0, "max": 1, "step": 0.05, "default": 0.5},
		{"key": "fins", "label": "Fins", "min": 0, "max": 6, "step": 1, "default": 0},
		{"key": "front_units", "label": "Front units", "min": 0, "max": 4, "step": 1, "default": 0},
		{"key": "tanks", "label": "Tanks", "min": 0, "max": 4, "step": 1, "default": 0},
		{"key": "roof_units", "label": "Roof units", "min": 0, "max": 4, "step": 1, "default": 2},
		{"key": "chimneys", "label": "Chimneys", "min": 0, "max": 3, "step": 1, "default": 0},
		{"key": "antenna", "label": "Antenna", "min": 0, "max": 1, "step": 1, "default": 0},
		{"key": "pillars", "label": "Corner pillars", "min": 0, "max": 1, "step": 1, "default": 1},
		{"key": "bands", "label": "Trim bands", "min": 0, "max": 1, "step": 1, "default": 1},
		{"key": "palette", "label": "Palette", "min": 0, "max": 3, "step": 1, "default": 0},
	]


static func is_visible(key: String, style: int) -> bool:
	if style == BuildingRecipe.STYLE_MEDIEVAL:
		return key in MEDIEVAL_KEYS
	return key != "medieval"


static func format_value(key: String, value: float, style: int = 0) -> String:
	if key == "style":
		return _name(STYLE_NAMES, value)
	if key == "medieval":
		return _name(MedievalPresets.NAMES, value)
	if key == "roof":
		return _name(ROOF_NAMES, value)
	if key == "plan":
		return _name(PLAN_NAMES, value)
	if key == "palette":
		return _name(MEDIEVAL_PALETTE_NAMES if style == BuildingRecipe.STYLE_MEDIEVAL else PALETTE_NAMES, value)
	if key in TOGGLE_KEYS:
		return "On" if value >= 0.5 else "Off"
	if key in WHOLE_KEYS:
		return "%d" % int(value)
	return "%.2f" % value


static func _name(names: Array, value: float) -> String:
	return names[clampi(int(value), 0, names.size() - 1)]
