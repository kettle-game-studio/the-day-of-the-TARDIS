extends Node

@export var scene: PackedScene

func _ready() -> void:
	await get_tree().process_frame
	await debug_scene(scene)
	await get_tree().process_frame
	get_tree().quit()

static func prepare_debug_scene(node: Node):
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasLayer or node is CanvasItem or node is Node3D:
		node.visible = false
		if node is VisualInstance3D:
			SSTNodeUtils.disable_culling(node)
	for child in node.get_children():
		prepare_debug_scene(child)


static func debug_by_node_scene(node: Node, current_node: Array):
	if node is CanvasLayer or node is CanvasItem or node is Node3D:
		current_node[0] = node
		node.visible = true
		if node is GPUParticles3D or node is CPUParticles3D:
			node.emitting = true
		await SSTShaderStutterWatcher.new_tick_processed
		await SSTShaderStutterWatcher.new_tick_processed
	for child in node.get_children():
		await debug_by_node_scene(child, current_node)
	if node is CanvasLayer or node is CanvasItem or node is Node3D:
		node.visible = false


func debug_scene(scene: PackedScene):
	var scene_root := scene.instantiate()
	prepare_debug_scene(scene_root)
	add_child(scene_root)
	var current_node := [scene_root]
	var catched := func(report: Dictionary):
		var node = current_node[0] as Node
		var triggers := SSTTriggerCandidate.from_or_unknown(node)
		SSTVisibleTracker.on_screen_triggers.add_new_triggers_force(node, triggers)
	SSTShaderStutterWatcher.new_shaders_compiled.connect(catched)
	await SSTShaderStutterWatcher.new_tick_processed
	var old_mode := DisplayServer.window_get_vsync_mode()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSyncMode.VSYNC_DISABLED)
	Engine.max_fps = 0
	await debug_by_node_scene(scene_root, current_node)
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(old_mode)
	SSTShaderStutterWatcher.new_shaders_compiled.disconnect(catched)
