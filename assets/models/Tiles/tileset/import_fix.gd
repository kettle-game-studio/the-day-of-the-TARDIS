@tool
extends Node3D

@export_tool_button("FIX") var fix_ = fix
const TILESET_MATERIAL = preload("uid://bku6j6oditrrh")
const MESH_LIBRARY = preload("uid://gall0t587rlm")
const TILESET_GLASS_MATERIAL = preload("uid://cav8qac5am725")
const MESH_LIBRARY_BREAK = preload("uid://ddta8vtrlxsia")
const TILESET_GLASS_MATERIAL_BREAK = preload("uid://dp2nwexgydsrg")
const TILESET_MATERIAL_BREAK = preload("uid://dypjbjdkq2fbx")

func fix():
	fix_library(MESH_LIBRARY, TILESET_MATERIAL, TILESET_GLASS_MATERIAL)
	fix_library(MESH_LIBRARY_BREAK, TILESET_MATERIAL_BREAK, TILESET_GLASS_MATERIAL_BREAK)

# Called when the node enters the scene tree for the first time.
func fix_library(mesh_library: MeshLibrary, tileset_material: Material, glass_material: Material):
	print(mesh_library, " ", tileset_material, glass_material)
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
		var mesh := (load("res://assets/models/Tiles/models/"+file_name).duplicate() as ArrayMesh)
		if true:
			var surface := mesh.surface_get_arrays(0)
			var primitive_type := mesh.surface_get_primitive_type(0)
			var arr = surface[Mesh.ARRAY_VERTEX]
			for i in range(arr.size()):
				var point = arr[i]
				for axis in ["x", "z"]:
					if abs(0.5 - point[axis]) < 0.001:
						point[axis] = 0.501
					elif abs(-0.5 - point[axis]) < 0.001:
						point[axis] = -0.501
				arr[i] = point
			mesh.clear_surfaces()
			mesh.add_surface_from_arrays(primitive_type, surface)
		if mesh_name.ends_with("Glass"):
			mesh.surface_set_material(0, glass_material)
		else:
			mesh.surface_set_material(0, tileset_material)
			
		mesh_library.set_item_mesh(name_id_mapping[mesh_name], mesh)
		mesh_library.take_over_path(mesh_library.resource_path)
