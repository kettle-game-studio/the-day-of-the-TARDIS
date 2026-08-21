@tool
extends Node3D

@export_tool_button("FIX") var fix_ = fix
const TILESET_MATERIAL = preload("uid://bku6j6oditrrh")
const MESH_LIBRARY = preload("uid://gall0t587rlm")
const TILESET_GLASS_MATERIAL = preload("uid://cav8qac5am725")

@export var mesh_library := MESH_LIBRARY
# Called when the node enters the scene tree for the first time.
func fix():
	var name_id_mapping: Dictionary[String, int] = {}
	for mesh_id in mesh_library.get_item_list():
		var mesh_name := mesh_library.get_item_name(mesh_id)
		name_id_mapping[mesh_name] = mesh_id
	var dir := DirAccess.open("res://assets/models/Tiles/models/")
	for file_name in dir.get_files():
		var mesh_name := file_name.split(".")[0].replace("_", "")
		if not name_id_mapping.has(mesh_name):
			#print(mesh_name, "SKIPPED")
			continue
		print(mesh_name, " ", name_id_mapping[mesh_name])
		var mesh: Mesh = load("res://assets/models/Tiles/models/"+file_name).duplicate()
		if mesh_name.ends_with("Glass"):
			mesh.surface_set_material(0, TILESET_GLASS_MATERIAL)
		else:
			mesh.surface_set_material(0, TILESET_MATERIAL)
			
		mesh_library.set_item_mesh(name_id_mapping[mesh_name], mesh)
	

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
