@tool
extends Node
class_name TardisPortal

@export var portal_viewport: SubViewport
@export var mesh: MeshInstance3D

var material: ShaderMaterial

func _ready():
	if mesh == null || portal_viewport == null:
		return
	material = mesh.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("portal_camera", portal_viewport.get_texture())
	mesh.set_surface_override_material(0, material)
