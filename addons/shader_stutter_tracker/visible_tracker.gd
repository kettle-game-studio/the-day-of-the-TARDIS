extends Node

const TrackOnScreen := preload("res://addons/shader_stutter_tracker/track_on_screen.gd")

var saw_triggers: Dictionary[Dictionary, int] = { }
var on_screen_triggers: Array[Node] = []
var on_screen_enviroments: Array[WorldEnvironment] = []
var saw_keys: Dictionary[String, Dictionary] = { }


func _ready() -> void:
	Performance.add_custom_monitor(
		&"shaders/new_triggers",
		func():
			return saw_keys.size(),
	)
	# Performance.add_custom_monitor(&"shaders/new_triggers", get_new_triggers_on_screen_count)
	add_existed_nodes.call_deferred(get_tree().current_scene)
	get_tree().node_added.connect(_on_node_added)
	process_mode = Node.PROCESS_MODE_ALWAYS


func report() -> Array:
	return on_screen_triggers.map(
		func(n: Node):
			return n.get_meta(&"Report"),
	)


func clear() -> void:
	on_screen_triggers.clear()


func copy_visible_as_scene() -> PackedScene:
	var packed_scene = PackedScene.new()
	var root = Node.new()
	root.name = "root"
	var active_camera := get_viewport().get_camera_3d()
	if active_camera and active_camera.environment != null:
		add_new_triggers(active_camera, ShaderTriggerCandidate.from(active_camera.environment))
	else:
		for env in on_screen_enviroments:
			add_new_triggers(env, ShaderTriggerCandidate.from(env.environment))
	for item in on_screen_triggers:
		var node := SSTNodeUtils.copy_from_root(item, root)
		node.set_meta(&"Report", item.get_meta(&"Report"))
	assert(packed_scene.pack(root) == Error.OK)
	root.free()
	return packed_scene


func add_existed_nodes(node):
	for child in node.get_children():
		add_existed_nodes(child)
		_on_node_added(child)


func on_enter_visible(node: VisualInstance3D):
	add_new_triggers(node, ShaderTriggerCandidate.from(node))


func add_new_triggers(node: Node, triggers: Array[ShaderTriggerCandidate]):
	var filtered = triggers.filter(
		func(t):
			return !saw_triggers.has(t.key),
	)
	if filtered.is_empty():
		return
	if not add_new_triggers_force(node, filtered):
		return
	var time = Time.get_ticks_msec()
	for t in filtered:
		saw_triggers[t.key] = time


func add_new_triggers_force(node: Node, triggers: Array[ShaderTriggerCandidate]):
	if node in on_screen_triggers:
		return false
	node.set_meta(
		&"Report",
		{
			"tree_nodes": SSTNodeUtils.owners_chain(node),
			"triggers": triggers.map(
				func(t: ShaderTriggerCandidate):
					return t.to_dict(),
			),
		},
	)
	on_screen_triggers.push_back(node)
	return true


func get_new_triggers_on_screen_count() -> int:
	return on_screen_triggers.size()


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


class ShaderTriggerCandidate:
	var type := &"NODE"
	var shaders: Array[StringName]
	var path: String
	var key: Dictionary
	var resources_chain: Array[Resource]


	func _init(
		type: StringName,
		shaders: Array[StringName],
		path: String,
		key: Dictionary = { "path": path },
		resources_chain: Array[Resource] = [],
	):
		self.type = type
		self.shaders = shaders
		self.path = path
		self.key = key
		self.resources_chain = resources_chain


	func to_dict() -> Dictionary:
		return {
			"path": path,
			"type": type,
			"class": key["class"],
			"shaders": shaders,
			"resources": resources_chain.map(
				func(e: Resource):
					return { "path": e.resource_path, "class": e.get_class() },
			),
			"keys": key,
		}


	static func from(obj: Object) -> Array[ShaderTriggerCandidate]:
		var collector := ShaderTriggers.new()
		if obj is VisualInstance3D:
			collector.add_from_visual_instance_3d(obj)
		elif obj is GridMap:
			collector.add_from_grid_map(obj)
		elif obj is Environment:
			collector.add_from_environment(obj)
		return collector.triggers


	static func from_or_unknown(obj: Object) -> Array[ShaderTriggerCandidate]:
		var triggers := from(obj)
		if not triggers.is_empty():
			return triggers
		if obj is Node:
			var node := obj as Node
			return [
				ShaderTriggerCandidate.new(
					&"NODE",
					["UNKNOWN"],
					node.get_path(),
					{ "class": node.get_class(), "path": node.get_path() },
				)
			]
		return []


class ShaderTriggers:
	var triggers: Array[ShaderTriggerCandidate] = []
	var savedmats := { }

	static var _prepared := false


	static func prepare() -> void:
		var classes := [&"BaseMaterial3D", &"Light3D", &"Environment"]
		classes.append_array(ClassDB.get_inheriters_from_class(&"Light3D"))
		for clazz in classes:
			trigger_properties_by_class[clazz] = []
			for property in ClassDB.class_get_property_list(clazz, true):
				var type: Variant.Type = property["type"]
				var hint: PropertyHint = property["hint"]
				var name: String = property["name"]
				if (
					(type == TYPE_BOOL or hint == PROPERTY_HINT_ENUM)
					and !name.ends_with("_texture_channel")
				):
					trigger_properties_by_class[clazz].push_back(StringName(name))
		_prepared = true


	static var trigger_properties_by_class: Dictionary[StringName, Array] = { }
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
		if not _prepared:
			prepare()
		for p in trigger_properties_by_class[clazz]:
			key[p] = source.get(p)


	func add_material(mat: Material, prev_resources: Array[Resource] = []):
		if mat == null:
			return
		var resources := prev_resources.duplicate()
		resources.push_back(mat)
		var key := { "class": mat.get_class() }
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
			var k := { "class": "Shader", "path": path, "mode": sh.shader.get_mode() }
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
			triggers.push_back(
				ShaderTriggerCandidate.new(&"RESOURCE", shader_types, path, k, resources)
			)
			return
		else:
			key["path"] = mat.resource_path
		var path := mat.resource_path
		if savedmats.has(key):
			return
		savedmats[key] = true
		triggers.push_back(
			ShaderTriggerCandidate.new(&"RESOURCE", shader_types, path, key, resources)
		)


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


	func add_from_visual_instance_3d(node: VisualInstance3D):
		# Decal: all decals are drowed by one shader, so just ignore it
		if node is Decal:
			triggers.push_back(ShaderTriggerCandidate.new(&"NODE", [&"Scene"], node.get_path()))
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
				var key := { "class": "Label3D" }
				for p in label3d_trigger_properties:
					key[p] = l.get(p)
				triggers.push_back(
					ShaderTriggerCandidate.new(&"NODE", [&"Scene", &"CanvasSdf"], l.get_path(), key)
				)
			# SpriteBase3D
			elif gi is SpriteBase3D:
				var s := gi as SpriteBase3D
				var key := { "class": gi.get_class() }
				for p in sprite3d_trigger_properties:
					key[p] = s.get(p)
				triggers.push_back(
					ShaderTriggerCandidate.new(&"NODE", [&"Scene"], s.get_path(), key)
				)
		# Rest subtypes don't use materials (todo: check)
		# GPUParticlesAttractor3D
		# GPUParticlesCollision3D
		if node is Light3D:
			if (node as Light3D).editor_only:
				return
			var key := { "class": node.get_class() }
			fill_keys_by_properties(node, key, &"Light3D")
			fill_keys_by_properties(node, key, node.get_class())
			triggers.push_back(
				ShaderTriggerCandidate.new(&"NODE", [&"LIGHT"], node.get_path(), key)
			)

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
		if env.background_mode in [
			Environment.BGMode.BG_CLEAR_COLOR,
			Environment.BGMode.BG_COLOR,
			Environment.BGMode.BG_SKY,
		]:
			shader_types.push_back(&"Sky")
		if env.background_mode == Environment.BGMode.BG_SKY:
			if env.sky:
				add_material(env.sky.sky_material, prev_resources)
		if (env.fog_enabled or env.volumetric_fog_enabled) and &"Sky" not in shader_types:
			shader_types.push_back(&"Sky")
		if env.adjustment_enabled:
			shader_types.push_back(&"Post")
		if env.glow_enabled:
			shader_types.push_back(&"Glow")
		if shader_types.size() != 0:
			triggers.push_back(
				ShaderTriggerCandidate.new(
					&"RESOURCE",
					shader_types,
					env.resource_path,
					key,
					prev_resources,
				)
			)
