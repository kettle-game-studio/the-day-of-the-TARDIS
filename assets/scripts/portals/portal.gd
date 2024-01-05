@tool
extends Node
class_name Portal

@export var portal_viewport: SubViewport
@export var mesh: MeshInstance3D

signal teleport_activation(body: Area3D)

func _ready():
	if mesh == null || portal_viewport == null:
		return
	var material = mesh.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("portal_camera", portal_viewport.get_texture())
	mesh.set_surface_override_material(0, material)

func _area_body_entered(body: Area3D):
	teleport_activation.emit(body)
