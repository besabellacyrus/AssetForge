extends SceneTree

# Run: godot --headless --path <project> -s res://tests/test_param_spec.gd

var failures := 0


func _init() -> void:
	_test_keys_match_recipe()
	_test_defaults_in_range()
	_test_default_values_match_recipe()
	_test_format_value()
	_test_medieval_specs()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


func _spec_for(key: String) -> Dictionary:
	for s: Dictionary in ParamSpec.specs():
		if s["key"] == key:
			return s
	return {}


func _test_keys_match_recipe() -> void:
	var keys := {}
	for s: Dictionary in ParamSpec.specs():
		keys[s["key"]] = true
	var recipe_keys := BuildingRecipe.default_params().keys()
	var ok := keys.size() == recipe_keys.size() and not keys.is_empty()
	for k in recipe_keys:
		if not keys.has(k):
			ok = false
	_check(ok, "one slider spec per recipe parameter")


func _test_defaults_in_range() -> void:
	var ok := not ParamSpec.specs().is_empty()
	for s: Dictionary in ParamSpec.specs():
		if float(s["default"]) < float(s["min"]) or float(s["default"]) > float(s["max"]):
			ok = false
	_check(ok, "every default lies within its min and max")


func _test_default_values_match_recipe() -> void:
	var recipe := BuildingRecipe.default_params()
	var ok := not ParamSpec.specs().is_empty()
	for s: Dictionary in ParamSpec.specs():
		if not is_equal_approx(float(s["default"]), float(recipe[s["key"]])):
			ok = false
	_check(ok, "slider defaults equal recipe defaults")


func _test_format_value() -> void:
	_check(ParamSpec.format_value("roof", 2.0) == "Stepped", "roof shows its name")
	_check(ParamSpec.format_value("roof", 0.0) == "Flat", "flat roof name")
	_check(ParamSpec.format_value("tanks", 3.0) == "3", "tank count shows as whole number")
	_check(ParamSpec.format_value("width", 8.5) == "8.50", "width shows two decimals")
	_check(ParamSpec.format_value("antenna", 1.0) == "On" and ParamSpec.format_value("antenna", 0.0) == "Off", "toggles show On and Off")
	_check(ParamSpec.format_value("pillars", 1.0) == "On" and ParamSpec.format_value("bands", 0.0) == "Off", "pillars and bands are toggles")
	_check(ParamSpec.format_value("palette", 0.0) == "Plain" and ParamSpec.format_value("palette", 2.0) == "Steel", "palette shows its name")
	_check(ParamSpec.format_value("plan", 3.0) == "U" and ParamSpec.format_value("plan", 1.0) == "L", "plan shows its shape")
	_check(ParamSpec.format_value("roof", 3.0) == "Gable" and ParamSpec.format_value("roof", 4.0) == "Barn", "new roof names")
	_check(ParamSpec.format_value("offset", 1.0) == "On", "offset setback is a toggle")
	_check(ParamSpec.format_value("fins", 4.0) == "4", "fin count is a whole number")


func _test_medieval_specs() -> void:
	_check(ParamSpec.format_value("style", 0.0) == "Factory" and ParamSpec.format_value("style", 1.0) == "Medieval", "style shows its name")
	_check(ParamSpec.format_value("medieval", 1.0) == MedievalPresets.NAMES[1], "medieval preset shows its name")
	_check(ParamSpec.format_value("outline", 1.0) == "On", "outline is a toggle")
	_check(ParamSpec.format_value("palette", 1.0, 0) == "Industrial", "factory palette names")
	_check(ParamSpec.format_value("palette", 1.0, 1) != "Industrial", "medieval palette names differ")
	_check(_spec_for("medieval")["max"] == MedievalPresets.COUNT - 1, "medieval slider spans every preset")
	_check(not ParamSpec.is_visible("medieval", 0) and ParamSpec.is_visible("medieval", 1), "preset slider only shows in medieval")
	_check(ParamSpec.is_visible("tanks", 0) and not ParamSpec.is_visible("tanks", 1), "factory sliders hide in medieval")
	_check(ParamSpec.is_visible("seed", 1) and ParamSpec.is_visible("palette", 1) and ParamSpec.is_visible("outline", 1), "shared sliders always show")