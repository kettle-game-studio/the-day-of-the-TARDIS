extends Node3D
class_name DalekCorpse


var dalek_id = 0
var killed = false
@export var color: Color

@onready var mesh_body = $Armature/Skeleton3D/DalekBreak
@onready var mesh_head = $Armature/Skeleton3D/DalekBeakHead
@onready var explosion = $Explosion
# Called when the node enters the scene tree for the first time.
var lifetime = 1
var material: ShaderMaterial
func _ready():
	material = mesh_body.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("color", color)
	mesh_body.set_surface_override_material(0, material)
	mesh_head.set_surface_override_material(0, material)
	if !killed:
		lifetime = 0.0
		remove_child(explosion)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if lifetime < 1.:
		lifetime+=delta/1.
		material.set_shader_parameter("disappearance", min(1.0, lifetime))
