extends Control

# Asset Forge window. Builds the slider panel and the 3D preview. Rebuilds the mesh on every change.
# Pure logic lives in BuildingRecipe, MeshBuilder and ParamSpec.

var params := BuildingRecipe.default_params()
var _mesh: MeshInstance3D
var _seed_slider: HSlider
var _camera: OrbitCamera


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(split)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var panel := _build_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	split.add_child(scroll)
	split.add_child(_build_viewport())
	_rebuild()


func _build_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var title := Label.new()
	title.text = "ASSET FORGE - BUILDING"
	panel.add_child(title)
	for spec: Dictionary in ParamSpec.specs():
		var key: String = spec["key"]
		var row := VBoxContainer.new()
		var head := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = spec["label"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label := Label.new()
		head.add_child(name_label)
		head.add_child(value_label)
		var slider := HSlider.new()
		slider.min_value = spec["min"]
		slider.max_value = spec["max"]
		slider.step = spec["step"]
		slider.value = params[key]
		value_label.text = ParamSpec.format_value(key, slider.value)
		slider.value_changed.connect(_on_param_changed.bind(key, value_label))
		row.add_child(head)
		row.add_child(slider)
		panel.add_child(row)
		if key == "seed":
			_seed_slider = slider
	var reroll := Button.new()
	reroll.text = "Re-roll seed"
	reroll.pressed.connect(_on_reroll)
	panel.add_child(reroll)
	return panel


func _build_viewport() -> Control:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var view := SubViewport.new()
	view.handle_input_locally = true
	container.add_child(view)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("1e2530")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8899aa")
	environment.ambient_light_energy = 0.6
	env.environment = environment
	view.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	view.add_child(sun)

	_camera = OrbitCamera.new()
	view.add_child(_camera)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	_mesh = MeshInstance3D.new()
	_mesh.material_override = mat
	view.add_child(_mesh)
	return container


func _on_param_changed(value: float, key: String, value_label: Label) -> void:
	params[key] = value
	value_label.text = ParamSpec.format_value(key, value)
	_rebuild()


func _on_reroll() -> void:
	_seed_slider.value = randi_range(1, 9999)


func _rebuild() -> void:
	var parts := BuildingRecipe.build(params)
	_mesh.mesh = MeshBuilder.build_mesh(parts, MeshBuilder.palette(int(params["palette"])))
	_camera.set_target(Vector3(0, float(params["height"]) * 0.5, 0))
