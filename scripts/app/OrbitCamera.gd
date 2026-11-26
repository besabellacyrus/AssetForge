class_name OrbitCamera
extends Camera3D

# Orbit camera around the building. Left-drag rotates, wheel zooms. Isometric default angle.

const ELEVATION := deg_to_rad(30.0)
const MIN_DIST := 8.0
const MAX_DIST := 40.0

var yaw := deg_to_rad(45.0)
var distance := 18.0
var target := Vector3(0, 3.5, 0)


func _ready() -> void:
	current = true
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= event.relative.x * 0.01
		_apply()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance * 0.9, MIN_DIST, MAX_DIST)
			_apply()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance * 1.1, MIN_DIST, MAX_DIST)
			_apply()


func set_target(new_target: Vector3) -> void:
	target = new_target
	_apply()


func _apply() -> void:
	var offset := Vector3(sin(yaw) * cos(ELEVATION), sin(ELEVATION), cos(yaw) * cos(ELEVATION))
	position = target + offset * distance
	look_at(target, Vector3.UP)
