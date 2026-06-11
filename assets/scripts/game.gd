extends Node3D
class_name Game

@export
var death_dialogs: Array[Dialog]
@export
var restart_dialogs: Array[Dialog]

var levels: Array[AbstractLevel] = []
var dialogs: Array[DialogZone] = []
var current_level = 0
var died_count = 0
var debug: Label
var play_time = 0.0

signal end_game()

@onready var dalek_cemetery = $DalekCemetery
@onready var player: PlayerController = $Player
@onready var portal_controller = $PortalController
@onready var ui = $UI

@export var preload_scenes: Array[PackedScene]


var shaders_node = Node3D.new()

func _ready():
	debug = ui.debug
	player.killed.connect(_on_player_is_killed)
	var lvls_nodes = find_children("*", "AbstractLevel")
	for node in lvls_nodes:
		var level = node as AbstractLevel
		levels.push_back(level)
		level.dalek_home = dalek_cemetery
		level.player = player
		level.portal_controller = portal_controller
		level.level_finished.connect(_on_level_finished)
		level.level_failed.connect(_on_level_failed)
		level.game = self
	debug.text = "%d level" % current_level
	levels[0].restart()
	var dialogs_nodes = find_children("*", "DialogZone")
	for node in dialogs_nodes:
		var zone = node as DialogZone
		dialogs.push_back(zone)
		zone.player_entered.connect(_on_dialog)
	shaders_node.name = "SHADERS"
	player.camera.add_child(shaders_node)
	shaders_node.position.z = -1
	compile_shaders(shaders_node, preload_scenes)
	await get_tree().create_timer(1).timeout
	#remove_shaders()

func remove_shaders():
	shaders_node.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	play_time += delta
	
var debug_mode = false
func _input(event):
	if Input.is_action_just_pressed("restart_level"):
		restart_level(current_level)
		debug.text = "%d level\n%d died" % [current_level, died_count]
	elif debug_mode:
		for i in range(0, min(10, levels.size())):
			if Input.is_key_label_pressed(KEY_0 + i):
				restart_level(i)
				break
	if Input.is_action_just_pressed("debug_mode"):
		debug_mode = !debug_mode
		if debug_mode:
			debug.show()
		else:
			debug.hide()

func restart_level(i: int):
	if i == 0 || (!debug_mode && i == levels.size() - 1):
		return
	levels[i].restart()
	current_level = i
	player.state = PlayerController.State.PLAY
	debug.text = "%d level\n%d died" % [current_level, died_count]

func _on_level_finished(level: AbstractLevel):
	if level == levels[current_level]:
		if current_level < levels.size() - 1:
			current_level += 1
			debug.text = "%d level\n%d died" % [current_level, died_count]
		else:
			debug.text = "WIN\n%d died" % died_count
			end_game.emit()
			

func _on_level_failed(_level):
	ui.play_dialog(restart_dialogs.pick_random())


func _on_player_is_killed(_killer):
	levels[current_level].restart()
	ui.play_dialog(death_dialogs.pick_random())
	died_count += 1
	debug.text = "%d level\n%d died" % [current_level, died_count]

var shoted_zones = {}
func _on_dialog(zone: DialogZone):
	if zone.one_shot && shoted_zones.has(zone):
		return
	shoted_zones[zone] = true
	player.state = zone.player_state_in_dialog
	ui.play_dialog(zone.speech)
	await ui.dialog_finished
	player.state = zone.player_state_after
	if player.state == PlayerController.State.INTRO:
		player.screwdriver.close()
	

func compile_shaders(node, scenes: Array[PackedScene]):
	copy_all_renderable_from_scenes(scenes, node)
	return
	for scene in scenes:
		var inst = scene.instantiate()
		inst.process_mode = Node.PROCESS_MODE_DISABLED
		node.call_deferred("add_child", inst)
	return
	var materials = get_all_materials_from_scenes(scenes)
	for key in materials:
		var new_mesh: MeshInstance3D = MeshInstance3D.new()
		new_mesh.add_to_group("mesh")
		new_mesh.mesh = QuadMesh.new()
		new_mesh.set_surface_override_material(0, materials[key])
		new_mesh.name = key
		#new_mesh.position = Vector3(GameManager.boundary.left + GameManager.boundary_margin / 2, 0, GameManager.boundary.bottom - GameManager.boundary_margin / 2)
		node.call_deferred("add_child", new_mesh)


func remove_quads():
	# remove temporary meshes that were used to force the shader compiling
	for mesh in get_tree().get_nodes_in_group("mesh"):
		mesh.queue_free()
		
func get_all_children(in_node, array := []):
	array.push_back(in_node)
	for child in in_node.get_children():
		array = get_all_children(child, array)
	return array


func get_all_materials_from_scenes(scenes):
	var materials = {}  # dictionary to return only unique materials
	for scene in scenes:
		for material in get_all_materials(scene.instantiate()):
			materials[str(material.get_rid().get_id())] = material
	return materials


func get_all_materials(source_node):
	var materials = []
	for child in get_all_children(source_node):
		if child is MeshInstance3D:
			var mesh: MeshInstance3D = child as MeshInstance3D
			for i in mesh.get_surface_override_material_count():
				# we need only active materials
				var material = mesh.get_active_material(i)
				if material != null and is_instance_valid(material):
					materials.append(material)
		if child is GPUParticles3D:
			var particle: GPUParticles3D = child as GPUParticles3D
			var material = particle.draw_pass_1.surface_get_material(0)
			if material != null and is_instance_valid(material):
				materials.append(material)
		if child is CPUParticles3D:
			var particle: CPUParticles3D = child as CPUParticles3D
			var material = particle.mesh.surface_get_material(0)
			if material != null and is_instance_valid(material):
				materials.append(material)
	return materials

func copy_all_renderable_from_scenes(scenes, destination_node):
	for scene in scenes:
		copy_all_renderable(scene.instantiate(), destination_node)

func copy_all_renderable(source_node: Node, destination_node: Node):
	var materials = []
	for child in get_all_children(source_node):
		if child is MeshInstance3D:
			var mesh: MeshInstance3D = child as MeshInstance3D
			child.reparent(destination_node, false)
			#destination_node.add_child(child)
		if child is GPUParticles3D:
			#var particle: GPUParticles3D = child as GPUParticles3D
			#var material = particle.draw_pass_1.surface_get_material(0)
			#if material != null and is_instance_valid(material):
				#materials.append(material)
			child.reparent(destination_node, false)
			#destination_node.add_child(child)
		if child is CPUParticles3D:
			#var particle: CPUParticles3D = child as CPUParticles3D
			#var material = particle.mesh.surface_get_material(0)
			#if material != null and is_instance_valid(material):
				#materials.append(material)
			child.reparent(destination_node, false)
			#destination_node.add_child(child)
	return materials
