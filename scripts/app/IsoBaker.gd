class_name IsoBaker
extends RefCounted

# Renders a building to a transparent isometric sprite (orthographic, yaw 45, pitch -30).
# Needs a window: headless cannot render. Call from a node in the tree and await the result.

const PITCH := deg_to_rad(30.0)
const YAW := deg_to_rad(45.0)
const MARGIN := 1.1


static func bake(host: Node, mesh: Mesh, outline: Mesh, size: int) -> Image:
	var view := SubViewport.new()
	view.size = Vector2i(size, size)
	view.transparent_bg = true
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("aab4c0")
	environment.ambient_light_energy = 0.7
	env.environment = environment
	view.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	view.add_child(sun)
	view.add_child(_instance(mesh, false))
	if outline != null:
		view.add_child(_instance(outline, true))
	var aabb := mesh.get_aabb()
	var centre := aabb.get_center()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = aabb.size.length() * MARGIN
	view.add_child(cam)
	var dir := Vector3(sin(YAW) * cos(PITCH), sin(PITCH), cos(YAW) * cos(PITCH))
	cam.look_at_from_position(centre + dir * 50.0, centre)
	host.add_child(view)
	for i in 4:
		await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	view.queue_free()
	return image


static func _instance(mesh: Mesh, ink: bool) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	if ink:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_FRONT
	else:
		mat.roughness = 0.85
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	if ink:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node