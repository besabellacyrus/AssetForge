class_name AssetExport
extends RefCounted

# Pure: names, metadata and the licence text for a saved asset. No file access here (see AssetWriter).

const FILE_MODEL := "model.glb"
const FILE_SPRITE := "sprite.png"
const FILE_META := "asset.json"
const FILE_LICENSE := "LICENSE.txt"
const LICENSE_ID := "CC0-1.0"
const AUTHOR := "Cyrus Besabella"
const AUTHOR_EMAIL := "besabellacyrus@gmail.com"


static func slug(text: String) -> String:
	var out := ""
	var last_dash := true
	for c in text.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
			last_dash = false
		elif not last_dash:
			out += "-"
			last_dash = true
	return out.rstrip("-")


static func style_name(params: Dictionary) -> String:
	return ParamSpec.STYLE_NAMES[int(params["style"])]


static func preset_name(params: Dictionary) -> String:
	if int(params["style"]) == BuildingRecipe.STYLE_MEDIEVAL:
		return MedievalPresets.NAMES[int(params["medieval"])]
	return ""


# Same params give the same name, so saving again overwrites the same folder.
static func asset_name(params: Dictionary) -> String:
	var base := slug(preset_name(params)) if int(params["style"]) == BuildingRecipe.STYLE_MEDIEVAL else slug(style_name(params))
	return "%s_%d" % [base, int(params["seed"])]


static func metadata(params: Dictionary, sprite_size: Vector2i, triangles: int) -> Dictionary:
	return {
		"name": asset_name(params),
		"style": style_name(params),
		"preset": preset_name(params),
		"license": LICENSE_ID,
		"generator": "AssetForge",
		"author": AUTHOR,
		"author_email": AUTHOR_EMAIL,
		"triangles": triangles,
		"sprite": {"size": [sprite_size.x, sprite_size.y], "projection": "isometric", "yaw": 45, "pitch": -30, "background": "transparent"},
		"files": [FILE_MODEL, FILE_SPRITE, FILE_META, FILE_LICENSE],
		"params": params.duplicate(),
	}


static func license_text() -> String:
	return "CC0 1.0 Universal (Public Domain Dedication)\n\n" \
		+ "The person who associated a work with this deed has dedicated the work to the public domain by waiving all of\n" \
		+ "their rights to the work worldwide under copyright law, including all related and neighboring rights, to the\n" \
		+ "extent allowed by law. You can copy, modify, distribute and perform the work, even for commercial purposes,\n" \
		+ "all without asking permission.\n\n" \
		+ "Dedicated to the public domain by %s <%s>\n\n" % [AUTHOR, AUTHOR_EMAIL] \
		+ "This asset was generated procedurally by AssetForge.\n\n" \
		+ "Full legal text: https://creativecommons.org/publicdomain/zero/1.0/legalcode\n" \
		+ "Deed: https://creativecommons.org/publicdomain/zero/1.0/\n"