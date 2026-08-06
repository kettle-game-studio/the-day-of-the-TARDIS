extends Node

@export var num_frames: int = 5  # The number of frames to display all materials

signal all_shaders_compiled  # This signal is emitted when the node frees itself (i.e., all materials are compiled)

#class ShaderTriggers:
	#var ligths: 

@export var config: ShadersCompilerConfig

@onready var camera: Camera3D = $"./Camera3D"

var _counter: int = 0

func is_shader_with_mode(mat: Material, mode: Shader.Mode):
	return mat is ShaderMaterial and (mat as ShaderMaterial).shader.get_mode() == mode

func _ready():
	_add_material3d(null)
	for mat in config.materials:
		if mat is BaseMaterial3D or is_shader_with_mode(mat, Shader.Mode.MODE_SPATIAL):
			_add_material_with_skeleton3d(mat)
		elif mat is ParticleProcessMaterial or is_shader_with_mode(mat, Shader.Mode.MODE_PARTICLES):
			_add_particles3d(mat)

var ended = false
func _process(_delta: float) -> void:
	if ended:
		return
	var active_env := _counter/2-1
	if active_env >= 0:
		camera.environment = config.environments.get(active_env)
	_counter += 1
	if _counter >= (config.environments.size()+1)*2:
		ended = true
		all_shaders_compiled.emit()


var quad := make_skinned_quad()

func create_node(description: Dictionary) -> Node:
	var clazz: StringName = description[&"class"]
	var properties: Dictionary = description[&"propertiest"]
	var node := ClassDB.instantiate(clazz)
	for property in properties:
		node.set(property, properties.get(property))
	return node

func _disable_culling(node: VisualInstance3D):
	RenderingServer.instance_set_ignore_culling(node.get_instance(), true)

func _add_material3d(material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	add_child(instance)
	instance.owner = self
	instance.material_override = material
	_disable_culling(instance)
	return instance

func _add_material_with_skeleton3d(material: Material) -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	add_child(skeleton)
	skeleton.owner = self

	var bone := skeleton.add_bone("Bone1")
	skeleton.set_bone_rest(bone, Transform3D.IDENTITY)

	var instance := _add_material3d(material)
	instance.reparent(skeleton)
	instance.skeleton = instance.get_path_to(skeleton)
	instance.skin = skeleton.create_skin_from_rest_transforms()

	return skeleton

func prepare_debug_scene(node: Node):
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasLayer or node is CanvasItem or node is Node3D:
		node.visible = false
		if node is VisualInstance3D:
			_disable_culling(node)
	for child in node.get_children():
		prepare_debug_scene(child)

func debug_by_node_scene(node: Node, current_node: Array):
	if node is CanvasLayer or node is CanvasItem or node is Node3D:
		current_node[0] = node
		node.visible = true
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
		var triggers := SSTVisibleTracker.ShaderTriggers.new()
		if node is VisualInstance3D:
			triggers.add_from_visual_instance_3d(node)
		elif node is GridMap:
			triggers.add_from_grid_map(node)
		if triggers.triggers.size() == 0:
			triggers.triggers.push_back(SSTVisibleTracker.TriggerV1.new(
					&"NODE",
					["UNKNOWN"],
					node.get_path(),
					{"class": node.get_class(), "path": node.get_path()},
			))
		SSTVisibleTracker.add_new_triggers_force(node, triggers.triggers)
	SSTShaderStutterWatcher.new_shaders_compiled.connect(catched)
	await SSTShaderStutterWatcher.new_tick_processed
	var old_mode := DisplayServer.window_get_vsync_mode()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSyncMode.VSYNC_DISABLED)
	Engine.max_fps = 0
	await debug_by_node_scene(scene_root, current_node)
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(old_mode)
	SSTShaderStutterWatcher.new_shaders_compiled.disconnect(catched)

static func make_skinned_quad() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts := [
		Vector3(-0.5, -0.5, 0.0),
		Vector3( 0.5, -0.5, 0.0),
		Vector3( 0.5,  0.5, 0.0),
		Vector3(-0.5,  0.5, 0.0),
	]

	for v in verts:
		st.set_bones(PackedInt32Array([0, 0, 0, 0]))
		st.set_weights(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		st.add_vertex(v)

	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(0)
	st.add_index(2)
	st.add_index(3)

	return st.commit()

func _add_particles3d(mat: Material):
	var particles := GPUParticles3D.new()
	particles.process_material = mat
	add_child(particles)
	particles.owner = self
