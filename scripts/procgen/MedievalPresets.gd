class_name MedievalPresets
extends RefCounted

# Pure data: the 16 medieval building layouts, from the castle and village reference sheet.
# Each preset is a list of pieces. Positions and sizes are fractions of the building's width, depth
# and height (see MedievalRecipe), so the Width/Depth/Height sliders scale every preset.
#   block:   x, z (centre, -1..1 of the half footprint), w, d (fraction of footprint), h (fraction of
#            height), y (elevation, fraction of height), roof ("none"|"gable"|"cross"|"thatch"),
#            ridge ("x"|"z", default long side), crenel, timber, door, chimney (bool)
#   tower:   x, z, r (fraction of the short footprint side), h, cap ("cone"|"open"|"flat"), banner
#   fence:   x, z, w, d (centre and size as fractions), sides (letters f b l r)
#   crops:   x, z, w, d
#   leanto:  x, z, w, d, h (a wedge of thatch)

const COUNT := 16

const NAMES := [
	"Keep and Hall",
	"Great Keep",
	"Tower House",
	"Walled Hall",
	"Walled Cross Hall",
	"Walled Twin Halls",
	"Twin Tower Court",
	"Triple Tower Court",
	"Tower Cluster",
	"Gatehouse",
	"Farmhouse",
	"Manor",
	"Cottage",
	"Tower Cottage",
	"Tower Farmstead",
	"Thatch Cottage",
]


static func pieces(index: int) -> Array:
	match clampi(index, 0, COUNT - 1):
		0:
			return [
				_wall(0.28),
				_block(0.25, 0.25, 0.55, 0.5, 0.45, {"y": 0.28, "roof": "gable", "ridge": "x", "door": true}),
				_block(0.6, -0.55, 0.28, 0.28, 0.32, {"y": 0.28, "roof": "gable", "ridge": "z"}),
				_tower(-0.55, -0.4, 0.26, 0.95, "cone", true),
			]
		1:
			return [
				_wall(0.25),
				_tower(0.0, -0.1, 0.22, 0.95, "cone", true),
				_tower(-0.78, 0.68, 0.12, 0.55, "cone", false),
				_tower(0.78, 0.68, 0.12, 0.55, "cone", false),
				_tower(0.78, -0.75, 0.12, 0.55, "cone", false),
				_block(0.0, 0.7, 0.3, 0.2, 0.3, {"y": 0.25, "door": true}),
			]
		2:
			return [
				_wall(0.2),
				_tower(-0.5, -0.25, 0.24, 0.85, "cone", false),
				_block(0.25, 0.15, 0.6, 0.5, 0.4, {"y": 0.2, "roof": "gable", "ridge": "x", "door": true}),
				_tower(0.62, -0.62, 0.2, 0.5, "open", false),
			]
		3:
			return [
				_wall(0.3),
				_block(0.0, 0.05, 0.7, 0.55, 0.4, {"y": 0.3, "roof": "gable", "ridge": "x", "door": true}),
			]
		4:
			return [
				_wall(0.3),
				_block(0.0, 0.0, 0.7, 0.7, 0.4, {"y": 0.3, "roof": "cross", "door": true, "chimney": true}),
			]
		5:
			return [
				_wall(0.3),
				_block(-0.25, -0.1, 0.45, 0.7, 0.45, {"y": 0.3, "roof": "gable", "ridge": "z", "chimney": true}),
				_block(0.45, 0.3, 0.38, 0.38, 0.3, {"y": 0.3, "roof": "gable", "ridge": "x", "door": true}),
			]
		6:
			return [
				_wall(0.35),
				_tower(-0.72, -0.7, 0.2, 0.65, "open", true),
				_tower(0.72, 0.7, 0.2, 0.65, "open", true),
				_block(0.0, 0.0, 0.4, 0.4, 0.2, {"y": 0.35, "roof": "gable", "ridge": "x"}),
			]
		7:
			return [
				_wall(0.3),
				_tower(-0.72, -0.7, 0.2, 0.65, "open", false),
				_tower(0.72, -0.7, 0.2, 0.65, "open", true),
				_tower(-0.72, 0.7, 0.2, 0.65, "open", true),
				_block(0.2, 0.2, 0.4, 0.4, 0.2, {"y": 0.3, "roof": "gable", "ridge": "x"}),
			]
		8:
			return [
				_tower(-0.5, -0.3, 0.28, 0.7, "open", true),
				_tower(0.45, -0.5, 0.25, 0.85, "open", true),
				_tower(0.4, 0.4, 0.26, 0.5, "open", true),
				_block(-0.15, 0.35, 0.45, 0.4, 0.3, {"roof": "gable", "ridge": "x", "door": true}),
			]
		9:
			return [
				_tower(-0.7, 0.0, 0.22, 0.75, "open", true),
				_tower(0.7, 0.0, 0.22, 0.75, "open", true),
				_block(0.0, 0.0, 0.7, 0.5, 0.5, {"roof": "gable", "ridge": "x", "door": true}),
			]
		10:
			return [
				_block(-0.15, -0.3, 0.55, 0.45, 0.45, {"roof": "gable", "ridge": "x", "door": true, "chimney": true}),
				{"t": "leanto", "x": 0.55, "z": -0.3, "w": 0.22, "d": 0.4, "h": 0.3},
				{"t": "fence", "x": 0.0, "z": 0.2, "w": 0.95, "d": 0.5, "sides": "fl"},
				{"t": "crops", "x": -0.25, "z": 0.62, "w": 0.4, "d": 0.3},
			]
		11:
			return [
				_block(0.0, -0.3, 0.55, 0.45, 0.65, {"roof": "gable", "ridge": "x", "timber": true, "chimney": true}),
				_block(-0.05, 0.3, 0.8, 0.3, 0.4, {"roof": "gable", "ridge": "x", "door": true}),
				{"t": "fence", "x": 0.0, "z": 0.6, "w": 0.95, "d": 0.7, "sides": "fr"},
			]
		12:
			return [
				_block(0.0, 0.0, 0.7, 0.6, 0.45, {"roof": "gable", "ridge": "x", "door": true, "chimney": true}),
			]
		13:
			return [
				_block(-0.25, 0.0, 0.55, 0.6, 0.45, {"roof": "gable", "ridge": "x", "timber": true, "door": true, "chimney": true}),
				_tower(0.5, -0.1, 0.2, 0.75, "cone", false),
			]
		14:
			return [
				_block(-0.2, -0.3, 0.55, 0.45, 0.45, {"roof": "gable", "ridge": "x", "timber": true, "chimney": true}),
				_tower(0.45, -0.3, 0.17, 0.8, "cone", false),
				{"t": "leanto", "x": 0.45, "z": 0.35, "w": 0.3, "d": 0.3, "h": 0.25},
				{"t": "fence", "x": -0.1, "z": 0.45, "w": 0.7, "d": 0.5, "sides": "fl"},
				{"t": "crops", "x": -0.4, "z": 0.7, "w": 0.35, "d": 0.3},
			]
	return [
		_block(0.0, -0.3, 0.6, 0.45, 0.35, {"roof": "thatch", "ridge": "x", "door": true, "chimney": true}),
		{"t": "fence", "x": 0.0, "z": 0.3, "w": 0.95, "d": 0.5, "sides": "fl"},
		{"t": "crops", "x": -0.5, "z": 0.62, "w": 0.35, "d": 0.3},
		{"t": "crops", "x": 0.5, "z": 0.62, "w": 0.35, "d": 0.3},
	]


# A low crenellated wall around the whole footprint, with a dark courtyard floor.
static func _wall(h: float) -> Dictionary:
	return {"t": "block", "x": 0.0, "z": 0.0, "w": 1.0, "d": 1.0, "h": h, "crenel": true}


static func _block(x: float, z: float, w: float, d: float, h: float, extra: Dictionary = {}) -> Dictionary:
	var b := {"t": "block", "x": x, "z": z, "w": w, "d": d, "h": h}
	b.merge(extra, true)
	return b


static func _tower(x: float, z: float, r: float, h: float, cap: String, banner: bool) -> Dictionary:
	return {"t": "tower", "x": x, "z": z, "r": r, "h": h, "cap": cap, "banner": banner}
