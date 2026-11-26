class_name ParamSpec
extends RefCounted

# Pure: slider ranges and value labels for the asset app. Keys match BuildingRecipe.default_params().

const ROOF_NAMES := ["Flat", "Hipped", "Stepped", "Gable", "Barn"]
const PLAN_NAMES := ["Box", "L", "T", "U"]
const PALETTE_NAMES := ["Plain", "Industrial", "Steel", "Rust"]
const WHOLE_KEYS := ["seed", "tiers", "tanks", "fins", "front_units", "roof_units", "chimneys"]
const TOGGLE_KEYS := ["offset", "antenna", "pillars", "bands"]


static func specs() -> Array:
	return [
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


static func format_value(key: String, value: float) -> String:
	if key == "roof":
		return _name(ROOF_NAMES, value)
	if key == "plan":
		return _name(PLAN_NAMES, value)
	if key == "palette":
		return _name(PALETTE_NAMES, value)
	if key in TOGGLE_KEYS:
		return "On" if value >= 0.5 else "Off"
	if key in WHOLE_KEYS:
		return "%d" % int(value)
	return "%.2f" % value


static func _name(names: Array, value: float) -> String:
	return names[clampi(int(value), 0, names.size() - 1)]
