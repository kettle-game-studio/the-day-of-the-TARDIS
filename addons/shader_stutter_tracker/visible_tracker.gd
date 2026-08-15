extends Node

const TrackOnScreen := preload("res://addons/shader_stutter_tracker/track_on_screen.gd")

var on_screen_triggers := SSTTriggerCollector.new()
var on_screen_enviroments: Array[WorldEnvironment] = []


func _ready() -> void:
	Performance.add_custom_monitor(
		&"shaders/new_triggers",
		func():
			return on_screen_triggers.size(),
	)
	# Performance.add_custom_monitor(&"shaders/new_triggers", get_new_triggers_on_screen_count)
	add_existed_nodes.call_deferred(get_tree().current_scene)
	get_tree().node_added.connect(_on_node_added)
	process_mode = Node.PROCESS_MODE_ALWAYS


func report() -> Array:
	return on_screen_triggers.report()


func clear() -> void:
	on_screen_triggers.clear()


func copy_visible_as_scene() -> PackedScene:
	var active_camera := get_viewport().get_camera_3d()
	if active_camera and active_camera.environment != null:
		on_screen_triggers.add_new_triggers(active_camera, SSTTriggerCandidate.from(active_camera.environment))
	else:
		for env in on_screen_enviroments:
			on_screen_triggers.add_new_triggers(env, SSTTriggerCandidate.from(env.environment))
	return on_screen_triggers.copy_as_scene()


func add_existed_nodes(node):
	for child in node.get_children():
		add_existed_nodes(child)
		_on_node_added(child)


func on_enter_visible(node: VisualInstance3D):
	on_screen_triggers.add_new_triggers(node, SSTTriggerCandidate.from(node))

func force_frustrum_scan(node: Node, cam: Camera3D):
	if node is Node3D:
		if node.is_visible_in_tree() and is_actually_on_screen_3d(node):
			on_screen_triggers.add_new_triggers(node, SSTTriggerCandidate.from(node))
	elif node is CanvasItem:
		if node is Control:
			if node.get_global_rect().intersects(node.get_viewport_rect()):
				on_screen_triggers.add_new_triggers(node, SSTTriggerCandidate.from(node))
	for child in node.get_children():
		force_frustrum_scan(child, cam)

func is_actually_on_screen_3d(node: Node3D) -> bool:
	var cam := node.get_viewport().get_camera_3d()
	if cam == null:
		return false

	var aabb: AABB

	if node is GPUParticles3D:
		aabb = node.visibility_aabb
	elif node is CPUParticles3D:
		aabb = node.visibility_aabb
	elif node is VisualInstance3D:
		aabb = node.get_aabb()
	else:
		return false

	if aabb.size == Vector3.ZERO:
		return false

	# переводим AABB в мировые координаты
	var world_aabb := node.global_transform * aabb

	return is_aabb_in_frustum(cam, world_aabb)

func is_aabb_in_frustum(cam: Camera3D, aabb: AABB) -> bool:
	var p := aabb.position
	var s := aabb.size
	var c := [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s
	]
	
	for v in c:
		if cam.is_position_in_frustum(v):
			return true

	var f := cam.get_frustum()
	for e in [
		[c[0], c[1]], [c[0], c[2]], [c[0], c[3]],
		[c[7], c[4]], [c[7], c[5]], [c[7], c[6]],
		[c[1], c[4]], [c[1], c[5]],
		[c[2], c[4]], [c[2], c[6]],
		[c[3], c[5]], [c[3], c[6]]
	]:
		if Geometry3D.segment_intersects_convex(e[0], e[1], f):
			return true

	var vp := get_viewport().get_visible_rect().size
	for sp in [Vector2.ZERO, Vector2(vp.x, 0.0), Vector2(0.0, vp.y), vp]:
		if aabb.has_point(cam.project_position(sp, cam.near)):
			return true
		if aabb.has_point(cam.project_position(sp, cam.far)):
			return true

	return false

func is_aabb_in_frustum2(cam: Camera3D, aabb: AABB) -> bool:
	var frustum := cam.get_frustum()

	var corners = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]

	# 1) любая вершина внутри фрустума
	for c in corners:
		if cam.is_position_in_frustum(c):
			return true

	# 2) любое ребро AABB пересекает фрустум
	var edges = [
		[0,1], [0,2], [0,3],
		[1,4], [1,5],
		[2,4], [2,6],
		[3,5], [3,6],
		[4,7], [5,7], [6,7],
	]

	for e in edges:
		if Geometry3D.segment_intersects_convex(corners[e[0]], corners[e[1]], frustum).size() > 0:
			return true

	return false

func _on_node_added(node: Node):
	if node.get_script() == TrackOnScreen:
		return
	if node is VisualInstance3D:
		return
		var t = TrackOnScreen.new(node, on_enter_visible.bind(node))
		node.add_child(t)
	if node is WorldEnvironment:
		on_screen_enviroments.push_back(node)
		node.tree_exited.connect(
			func():
				on_screen_enviroments.erase(node),
		)
