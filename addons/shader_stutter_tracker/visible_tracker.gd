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


func _on_node_added(node: Node):
	if node.get_script() == TrackOnScreen:
		return
	if node is VisualInstance3D:
		var t = TrackOnScreen.new(node, on_enter_visible.bind(node))
		node.add_child(t)
	if node is WorldEnvironment:
		on_screen_enviroments.push_back(node)
		node.tree_exited.connect(
			func():
				on_screen_enviroments.erase(node),
		)
