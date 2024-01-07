@tool
extends Node
class_name Portal

@export var portal_viewport: SubViewport
@export var mesh: MeshInstance3D

signal teleport_activation(portal: Portal, body: Area3D)
signal teleport_exit(portal: Portal, body: Area3D)
signal teleport_attacked(portal: Portal)

var material: ShaderMaterial

var shift_sign:
	get:
		if portal_viewport == null:
			return -1
		return 1

func _ready():
	if mesh == null || portal_viewport == null:
		return
	material = mesh.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("portal_camera", portal_viewport.get_texture())
	mesh.set_surface_override_material(0, material)

func _area_body_entered(body: Area3D):
	teleport_activation.emit(self, body)

func _area_body_exited(body: Area3D):
	teleport_exit.emit(self, body)


func _on_area_3d_body_entered(body):
	teleport_attacked.emit(self)

func set_opacity(value: float):
	material.set_shader_parameter("close", value)
