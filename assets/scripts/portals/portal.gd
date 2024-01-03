@tool
extends Node

@export var portal_vieport: SubViewport
@export var mesh: MeshInstance3D

func _ready():
	var material = mesh.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("portal_camera", portal_vieport.get_texture())
	mesh.set_surface_override_material(0, material)
