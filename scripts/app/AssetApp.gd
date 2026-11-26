extends Control

# Asset Forge window. Builds the slider panel and the 3D preview. Rebuilds the mesh on every change.
# Pure logic lives in BuildingRecipe, MeshBuilder and ParamSpec.

var params := BuildingRecipe.default_params()
const INK_THICKNESS := 0.12
const SPRITE_SIZE := 512

var _status: Label

var _mesh: MeshInstance3D
var _outline: MeshInstance3D
var _rows := {}
var _sliders := {}
var _value_labels := {}
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
		value_label.text = ParamSpec.format_value(key, slider.value, int(params["style"]))
		slider.value_changed.connect(_on_param_changed.bind(key, value_label))
		row.add_child(head)
		row.add_child(slider)
		panel.add_child(row)
		_rows[key] = row
		_sliders[key] = slider
		_value_labels[key] = value_label
	var generate := Button.new()
	generate.text = "Generate"
	generate.tooltip_text = "Roll a new random building. Every slider changes, keep the seed to repeat it."
	generate.pressed.connect(_on_generate)
	panel.add_child(generate)
	var save := Button.new()
	save.text = "Save (CC0)"
	save.tooltip_text = "Write model.glb, sprite.png, asset.json and LICENSE.txt to out/<name>/."
	save.pressed.connect(_on_save)
	panel.add_child(save)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	panel.add_child(_status)
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

	var ink := StandardMaterial3D.new()
	ink.vertex_color_use_as_albedo = true
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.cull_mode = BaseMaterial3D.CULL_FRONT
	_outline = MeshInstance3D.new()
	_outline.material_override = ink
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.add_child(_outline)
	return container


func _on_param_changed(value: float, key: String, value_label: Label) -> void:
	params[key] = value
	value_label.text = ParamSpec.format_value(key, value, int(params["style"]))
	if key == "style":
		_set_slider("outline", 1.0 if int(value) == BuildingRecipe.STYLE_MEDIEVAL else 0.0)
		_refresh_labels()
	_rebuild()


func _set_slider(key: String, value: float) -> void:
	params[key] = value
	(_sliders[key] as HSlider).set_value_no_signal(value)
	(_value_labels[key] as Label).text = ParamSpec.format_value(key, value, int(params["style"]))


# Palette names depend on the style.
func _refresh_labels() -> void:
	for key: String in _value_labels:
		(_value_labels[key] as Label).text = ParamSpec.format_value(key, float(params[key]), int(params["style"]))


func _on_generate() -> void:
	var rolled := RandomBuilding.roll(randi(), int(params["style"]))
	for key: String in rolled:
		_set_slider(key, rolled[key])
	_rebuild()


func _on_save() -> void:
	if _mesh.mesh == null:
		return
	_status.text = "Saving..."
	var sprite := await IsoBaker.bake(self, _mesh.mesh, _outline.mesh, SPRITE_SIZE)
	var result := AssetWriter.save(AssetWriter.default_root(), params, _mesh.mesh as ArrayMesh, sprite)
	if result["error"] == OK:
		_status.text = "Saved to " + String(result["dir"])
	else:
		_status.text = "Save failed: " + error_string(result["error"])


func _rebuild() -> void:
	var style := int(params["style"])
	for key: String in _rows:
		(_rows[key] as Control).visible = ParamSpec.is_visible(key, style)
	var parts := BuildingRecipe.build(params)
	_mesh.mesh = MeshBuilder.build_mesh(parts, MeshBuilder.palette(int(params["palette"]), style))
	_outline.visible = int(params["outline"]) > 0
	_outline.mesh = MeshBuilder.build_outline_mesh(parts, INK_THICKNESS) if _outline.visible else null
	_camera.set_target(Vector3(0, float(params["height"]) * 0.5, 0))
