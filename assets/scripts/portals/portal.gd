@tool
extends Node

@export var portal_vieport: SubViewport
@export var mesh: MeshInstance3D

signal teleport_activation(body: Area3D)

func _ready():
	var material = mesh.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("portal_camera", portal_vieport.get_texture())
	mesh.set_surface_override_material(0, material)

func _area_body_entered(body: Area3D):
	teleport_activation.emit(body)
