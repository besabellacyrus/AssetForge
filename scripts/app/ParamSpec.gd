class_name ParamSpec
extends RefCounted

# Pure: slider ranges and value labels for the asset app. Keys match BuildingRecipe.default_params().

const ROOF_NAMES := ["Flat", "Hipped", "Stepped"]
const PALETTE_NAMES := ["Industrial", "Steel", "Rust"]
const WHOLE_KEYS := ["seed", "tiers", "roof", "tanks", "windows", "roof_units", "chimneys", "palette"]
const TOGGLE_KEYS := ["antenna", "pillars", "bands"]


static func specs() -> Array:
	return [
		{"key": "seed", "label": "Seed", "min": 1, "max": 9999, "step": 1, "default": 1},
		{"key": "width", "label": "Width", "min": 4, "max": 14, "step": 0.5, "default": 8.0},
		{"key": "depth", "label": "Depth", "min": 4, "max": 14, "step": 0.5, "default": 8.0},
		{"key": "height", "label": "Height", "min": 2, "max": 16, "step": 0.5, "default": 7.0},
		{"key": "tiers", "label": "Tiers", "min": 1, "max": 3, "step": 1, "default": 1},
		{"key": "setback", "label": "Setback", "min": 0, "max": 0.4, "step": 0.01, "default": 0.15},
		{"key": "roof", "label": "Roof", "min": 0, "max": 2, "step": 1, "default": 1},
		{"key": "awning", "label": "Awning", "min": 0, "max": 1, "step": 0.05, "default": 0.5},
		{"key": "tanks", "label": "Tanks", "min": 0, "max": 4, "step": 1, "default": 0},
		{"key": "windows", "label": "Window columns", "min": 0, "max": 6, "step": 1, "default": 3},
		{"key": "roof_units", "label": "Roof units", "min": 0, "max": 4, "step": 1, "default": 2},
		{"key": "chimneys", "label": "Chimneys", "min": 0, "max": 3, "step": 1, "default": 0},
		{"key": "antenna", "label": "Antenna", "min": 0, "max": 1, "step": 1, "default": 0},
		{"key": "pillars", "label": "Corner pillars", "min": 0, "max": 1, "step": 1, "default": 1},
		{"key": "bands", "label": "Trim bands", "min": 0, "max": 1, "step": 1, "default": 1},
		{"key": "palette", "label": "Palette", "min": 0, "max": 2, "step": 1, "default": 0},
	]


static func format_value(key: String, value: float) -> String:
	if key == "roof":
		return ROOF_NAMES[clampi(int(value), 0, ROOF_NAMES.size() - 1)]
	if key == "palette":
		return PALETTE_NAMES[clampi(int(value), 0, PALETTE_NAMES.size() - 1)]
	if key in TOGGLE_KEYS:
		return "On" if value >= 0.5 else "Off"
	if key in WHOLE_KEYS:
		return "%d" % int(value)
	return "%.2f" % value
