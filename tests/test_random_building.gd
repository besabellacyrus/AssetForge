extends SceneTree

# Run: godot --headless --path <project> -s res://tests/test_random_building.gd

var failures := 0


func _init() -> void:
	_test_keys_match_recipe()
	_test_values_in_spec_ranges()
	_test_deterministic()
	_test_seeds_differ()
	_test_rolls_build()
	_test_plans_vary()
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures += 1
		print("FAIL: " + label)


func _test_keys_match_recipe() -> void:
	var rolled := RandomBuilding.roll(3)
	var recipe_keys := BuildingRecipe.default_params().keys()
	var ok := rolled.size() == recipe_keys.size() and not rolled.is_empty()
	for k in recipe_keys:
		if not rolled.has(k):
			ok = false
	_check(ok, "roll sets every recipe parameter")


func _test_values_in_spec_ranges() -> void:
	var ok := true
	for seed in range(1, 201):
		var rolled := RandomBuilding.roll(seed)
		for spec: Dictionary in ParamSpec.specs():
			var v := float(rolled.get(spec["key"], -1000.0))
			if v < float(spec["min"]) - 0.0001 or v > float(spec["max"]) + 0.0001:
				ok = false
	_check(ok, "200 rolls stay inside every slider range")


func _test_deterministic() -> void:
	_check(str(RandomBuilding.roll(42)) == str(RandomBuilding.roll(42)), "same seed gives the same roll")


func _test_seeds_differ() -> void:
	var distinct := {}
	for seed in range(1, 21):
		distinct[str(RandomBuilding.roll(seed))] = true
	_check(distinct.size() == 20, "20 seeds give 20 different rolls")


func _test_rolls_build() -> void:
	var ok := true
	for seed in range(1, 101):
		var parts := BuildingRecipe.build(RandomBuilding.roll(seed))
		if parts.is_empty():
			ok = false
	_check(ok, "100 rolls all build a non-empty building")


func _test_plans_vary() -> void:
	var plans := {}
	var roofs := {}
	for seed in range(1, 201):
		var rolled := RandomBuilding.roll(seed)
		plans[int(rolled.get("plan", -1))] = true
		roofs[int(rolled.get("roof", -1))] = true
	_check(plans.size() == 4, "200 rolls use all four plans")
	_check(roofs.size() == 5, "200 rolls use all five roof styles")
