extends Node

const TrackOnScreen := preload("res://addons/shader_stutter_tracker/track_on_screen.gd")


var saw_triggers: Dictionary[Dictionary, int] = {}
var on_screen_triggers: Array[Node] = []
var on_screen_enviroments: Array[WorldEnvironment] = []
var saw_keys: Dictionary[String,Dictionary] = {}

func report() -> Array:
	return on_screen_triggers.map(func (n: Node): return n.get_meta(&"Report"))

func _ready() -> void:
	Performance.add_custom_monitor(&"shaders/new_triggers", func(): return saw_keys.size())
	# Performance.add_custom_monitor(&"shaders/new_triggers", get_new_triggers_on_screen_count)
	add_existed_nodes.call_deferred(get_tree().current_scene)
	get_tree().node_added.connect(_on_node_added)
	ShaderTriggers.prepare()
	process_mode = Node.PROCESS_MODE_ALWAYS

func clear() -> void:
	on_screen_triggers.clear()

func copy_visible_as_scene() -> PackedScene:
	var packed_scene = PackedScene.new()
	var root = Node.new()
	root.name = "root"
	var active_camera := get_viewport().get_camera_3d()
	if active_camera and active_camera.environment != null:
		var triggers := ShaderTriggers.new()
		triggers.add_from_environment(active_camera.environment)
		add_new_triggers(active_camera, triggers)
	else:
		for env in on_screen_enviroments:
			var triggers := ShaderTriggers.new()
			triggers.add_from_environment(env.environment)
			add_new_triggers(env, triggers)
	for item in on_screen_triggers:
		var node := copy_from_root(item, root)
		node.set_meta(&"Report", item.get_meta(&"Report"))
	assert(packed_scene.pack(root) == Error.OK)
	root.free()
	return packed_scene
			
func copy_all(source_node: Node, destination_node: Node, destination_scene_root: Node):
	var dst := clone_node_shallow(source_node)
	dst.name = source_node.get_path().get_concatenated_names().replace("/", "_")
	destination_node.add_child(dst)
	dst.owner = destination_scene_root
	if dst is Node3D:
		(dst as Node3D).global_transform = (source_node as Node3D).global_transform
	elif dst is Node2D:
		(dst as Node2D).global_transform = (source_node as Node2D).global_transform


func copy_from_root(source_node: Node, destination_scene_root: Node) -> Node:
	if source_node.get_parent() == null:
		return destination_scene_root
	var parent := copy_from_root(source_node.get_parent(), destination_scene_root)
	var existed_copy := parent.find_child(source_node.name, false, false)
	if existed_copy:
		return existed_copy
	var dst := clone_node_shallow(source_node)
	dst.name = source_node.name
	parent.add_child(dst)
	dst.owner = destination_scene_root
	if dst is Node3D:
		(dst as Node3D).transform = (source_node as Node3D).transform
	elif dst is Node2D:
		(dst as Node2D).transform = (source_node as Node2D).transform
	return dst


static func clone_node_shallow(src: Node) -> Node:
	var dst := Node.new() if src.get_class() == "" else ClassDB.instantiate(src.get_class())

	copy_propierties(src, dst)
	
	return dst

static func copy_propierties(src: Node, dst = {}, type_filter: Array[Variant.Type] = []):
	# copy built-in properties only
	if not src.has_method("get"):
		return
	for p in src.get_property_list():
		if p.usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if not type_filter.is_empty() and not (p.type in type_filter):
			continue
		var name = p.name
		if name == "script":
			continue
		var value = src.get(name)
		if value == ClassDB.class_get_property_default_value(src.get_class(), name):
			continue
		if dst is Dictionary or dst.has_method("set"):
			dst.set(name, value)
	return dst


func add_existed_nodes(node):
	for child in node.get_children():
		add_existed_nodes(child)
		_on_node_added(child)

func _on_node_added(node: Node):
	if node.get_script() == TrackOnScreen:
		return
	if node is VisualInstance3D:
		var t = TrackOnScreen.new(node, on_enter_visible.bind(node))
		node.add_child(t)
	if node is WorldEnvironment:
		on_screen_enviroments.push_back(node)
		node.tree_exited.connect(func (): on_screen_enviroments.erase(node))

func on_enter_visible(node: VisualInstance3D):
	var triggers := ShaderTriggers.new()
	triggers.add_from_visual_instance_3d(node)
	add_new_triggers(node, triggers)

func add_new_triggers(node: Node, triggers: ShaderTriggers):
	var filtered = triggers.triggers.filter(func(t): return !saw_triggers.has(t.key))
	if filtered.is_empty():
		return
	if not add_new_triggers_force(node, filtered):
		return
	var time = Time.get_ticks_msec()
	for t in filtered:
		saw_triggers[t.key] = time

func add_new_triggers_force(node: Node, triggers: Array[TriggerV1]):
	if node in on_screen_triggers:
		return false
	node.set_meta(&"Report", {
		"tree_nodes": owners_chain(node),
		"triggers": triggers.map(func (t: TriggerV1): return {
				"path": t.path, 
				"type": t.type, 
				"class": t.key["class"],
				"shaders": t.shaders,
				"resources": t.resources_chain.map(func (e: Resource): return {
					"path": e.resource_path,
					"class": e.get_class(),
				}),
				"keys": t.key,
		}),
	})
	on_screen_triggers.push_back(node)
	return true

func get_new_triggers_on_screen_count() -> int:
	return on_screen_triggers.size()


class TriggerV1:
	var type := &"NODE"
	var shaders: Array[StringName]
	var path: String
	var key: Dictionary
	var resources_chain: Array[Resource];
	func _init(type: StringName, 
			shaders: Array[StringName], 
			path: String, 
			key: Dictionary = { "path": path }, 
			resources_chain: Array[Resource] = []):
		self.type = type
		self.shaders = shaders
		self.path = path
		self.key = key
		self.resources_chain = resources_chain

class ShaderTriggers:
	var triggers: Array[TriggerV1] = []
	static func prepare():
		var classes := [&"BaseMaterial3D", &"Light3D", &"Environment"]
		classes.append_array(ClassDB.get_inheriters_from_class(&"Light3D"))
		for clazz in classes:
			trigger_properties_by_class[clazz] = []
			for property in ClassDB.class_get_property_list(clazz, true):
				var type: Variant.Type = property["type"]
				var hint: PropertyHint = property["hint"]
				var name: String = property["name"]
				if (type == TYPE_BOOL or hint == PROPERTY_HINT_ENUM) and !name.ends_with("_texture_channel"):
					trigger_properties_by_class[clazz].push_back(StringName(name))
			print_rich(clazz, trigger_properties_by_class[clazz])
	static var trigger_properties_by_class: Dictionary[StringName, Array] = {}
	static var label3d_trigger_properties: Array[StringName] = [
		&"alpha_antialiasing_mode",
		&"alpha_cut",
		&"billboard",
		&"cast_shadow",
		&"double_sided",
		&"fixed_size",
		&"gi_mode",
		&"no_depth_test",
		&"shaded",
		&"texture_filter",
	]
	static var sprite3d_trigger_properties: Array[StringName] = [
		&"alpha_antialiasing_mode",
		&"alpha_cut",
		&"billboard",
		&"double_sided",
		&"fixed_size",
		&"no_depth_test",
		&"shaded",
		&"texture_filter",
		&"transparent",
	 ]
	static func fill_keys_by_properties(source: Object, key: Dictionary, clazz: StringName) -> void:
		for p in trigger_properties_by_class[clazz]:
			key[p] = source.get(p)
	var savedmats := {}
	func add_material(mat: Material, prev_resources: Array[Resource] = []):
		if mat == null:
			return
		var resources := prev_resources.duplicate()
		resources.push_back(mat)
		var key := {
				"class": mat.get_class()
			}
		var shader_types: Array[StringName] = []
		if mat is BaseMaterial3D:
			shader_types = [&"Scene"]
			fill_keys_by_properties(mat, key, &"BaseMaterial3D")
		elif mat is FogMaterial:
			shader_types = [&"Sky"]
		elif mat is PanoramaSkyMaterial:
			shader_types = [&"Sky"]
		elif mat is PhysicalSkyMaterial or mat is ProceduralSkyMaterial:
			key["path"] = mat.resource_path
			shader_types = [&"Sky"]
		elif mat is ParticleProcessMaterial:
			shader_types = [&"Particles", &"ParticlesCopy"]
		elif mat is ShaderMaterial:
			var sh := mat as ShaderMaterial
			var path := sh.shader.resource_path
			var k := {
				"class": "Shader",
				"path": path,
				"mode": sh.shader.get_mode(),
			}
			if savedmats.has(k):
				return
			savedmats[k] = true
			resources.push_back(sh.shader)
			shader_types = {
				# Mode used to draw all 3D objects.
				Shader.Mode.MODE_SPATIAL: [&"Scene"] as Array[StringName],
				# Mode used to draw all 2D objects.
				Shader.Mode.MODE_CANVAS_ITEM: [&"Canvas"] as Array[StringName],
				# Mode used to calculate particle information on a per-particle basis. Not used for drawing.
				Shader.Mode.MODE_PARTICLES: [&"Particles", &"ParticlesCopy"] as Array[StringName],
				# Mode used for drawing skies. Only works with shaders attached to Sky objects.
				Shader.Mode.MODE_SKY: [&"Sky"] as Array[StringName],
				# Mode used for setting the color and density of volumetric fog effect.
				Shader.Mode.MODE_FOG: [&"Sky"] as Array[StringName],
			}[sh.shader.get_mode()]
			triggers.push_back(TriggerV1.new(&"RESOURCE", shader_types, path, k, resources))
			return
		else:
			key["path"] = mat.resource_path
		var path := mat.resource_path
		if savedmats.has(key):
			return
		savedmats[key] = true
		triggers.push_back(TriggerV1.new(&"RESOURCE", shader_types, path, key, resources))
	
	func add_from_mesh(mesh: Mesh, resources: Array[Resource] = []):
		if mesh == null:
			return
		resources.push_back(mesh)
		for s in range(mesh.get_surface_count()):
			add_material(mesh.surface_get_material(s), resources)
		if mesh is PrimitiveMesh:
			var p := mesh as PrimitiveMesh
			add_material(p.material, resources)
		resources.pop_back()
	func add_from_grid_map(node: GridMap):
		var lib := node.mesh_library
		for id in lib.get_item_list():
			var mesh := lib.get_item_mesh(id)
			add_from_mesh(mesh, [lib])
		pass
	func add_from_visual_instance_3d(node: VisualInstance3D):
		# Decal: all decals are drowed by one shader, so just ignore it
		if node is Decal:
			triggers.push_back(TriggerV1.new(&"NODE", [&"Scene"], node.get_path()))
			return
		# FogVolume
		if node is FogVolume:
			# TODO: check in Mobile/Forward+ RenderingServer.FogVolumeShapeshape
			add_material(node.material)
			return
		# GeometryInstance3D
		if node is GeometryInstance3D:
			var gi := node as GeometryInstance3D
			add_material(gi.material_overlay)
			add_material(gi.material_override)
			# CPUParticles3D
			if gi is CPUParticles3D:
				var p := gi as CPUParticles3D
				add_from_mesh(p.mesh)
			# CSGShape3D
			elif gi is CSGShape3D:
				if "material" in gi:
					add_material(gi.material)
				if "mesh" in gi:
					add_from_mesh(gi.mesh)
			# GPUParticles3D
			elif gi is GPUParticles3D:
				var p := gi as GPUParticles3D
				add_material(p.process_material)
				for i in range(0, p.draw_passes):
					add_from_mesh(p.get_draw_pass_mesh(i))
			# MeshInstance3D
			elif gi is MeshInstance3D:
				var m := gi as MeshInstance3D
				for i in range(0, m.get_surface_override_material_count()):
					add_material(m.get_surface_override_material(i))
				add_from_mesh(m.mesh)
				if m.skin != null:
					for t in triggers:
						t.shaders.push_back(&"Skeleton")
			# MultiMeshInstance3D
			elif gi is MultiMeshInstance3D:
				var mm := gi as MultiMeshInstance3D
				if mm.multimesh != null:
					add_from_mesh(mm.multimesh.mesh)
			# Label3D
			elif gi is Label3D:
				var l := gi as Label3D
				var key := {"class": "Label3D"}
				for p in label3d_trigger_properties:
					key[p] = l.get(p)
				triggers.push_back(TriggerV1.new(&"NODE", [&"Scene", &"CanvasSdf"], l.get_path(), key))
			# SpriteBase3D
			elif gi is SpriteBase3D:
				var s := gi as SpriteBase3D
				var key := {"class": gi.get_class()}
				for p in sprite3d_trigger_properties:
					key[p] = s.get(p)
				triggers.push_back(TriggerV1.new(&"NODE", [&"Scene"], s.get_path(), key))
		# Rest subtypes don't use materials (todo: check)
		# GPUParticlesAttractor3D
		# GPUParticlesCollision3D
		if node is Light3D:
			if (node as Light3D).editor_only:
				return
			var key := {
				"class": node.get_class()
			}
			fill_keys_by_properties(node, key, &"Light3D")
			fill_keys_by_properties(node, key, node.get_class())
			triggers.push_back(TriggerV1.new(&"NODE", [&"LIGHT"], node.get_path(), key))
			
		# LightmapGI
		# OccluderInstance3D
		# OpenXRVisibilityMask
		# ReflectionProbe
		# RootMotionView
		# VisibleOnScreenNotifier3D
		# VoxelGI
	func add_from_environment(env: Environment):
		var prev_resources: Array[Resource] = [env]
		var shader_types: Array[StringName] = []
		var key := { "class": env.get_class() }
		fill_keys_by_properties(env, key, env.get_class())
		if env.background_mode in [Environment.BGMode.BG_CLEAR_COLOR, Environment.BGMode.BG_COLOR, Environment.BGMode.BG_SKY]:
			shader_types.push_back(&"Sky")
		if env.background_mode == Environment.BGMode.BG_SKY:
			if env.sky:
				add_material(env.sky.sky_material, prev_resources)
		if env.fog_enabled or env.volumetric_fog_enabled:
			shader_types.push_back(&"Sky")
		if env.adjustment_enabled:
			shader_types.push_back(&"Post")
		if env.glow_enabled:
			shader_types.push_back(&"Glow")
		if shader_types.size() != 0:
			triggers.push_back(TriggerV1.new(&"RESOURCE", shader_types, env.resource_path, key, prev_resources))

static func node_description(node: Node):
	var owner := node.owner
	var original_scene := node.scene_file_path
	var owner_path := owner.get_path() if owner != null else null
	var path := node.get_path()
	var clazz := node.get_class()
	var script := node.get_script()
	var script_path := (script as Script).resource_path if script != null else null
	return {
		"owner": owner_path,
		"path": path,
		"scene": original_scene,
		"class": clazz,
		"script": script_path,
		"properties": copy_propierties(node, {},  [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]),
	}

static func owners_chain(node: Node, arr: Array[Dictionary] = []) -> Array[Dictionary]:
	if node.get_parent() != null:
		owners_chain(node.get_parent(), arr)
	arr.push_back(node_description(node))
	return arr
