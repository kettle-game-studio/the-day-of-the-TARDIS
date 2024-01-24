extends Node3D
class_name DalekCorpse


var dalek_id = 0
var killed = false
var disappearance_time = 1.

enum State {
	APPEAR, DISAPPEAR
}
var state = State.APPEAR

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
	if state == State.APPEAR && lifetime < 1.:
		lifetime+=delta/disappearance_time
		material.set_shader_parameter("disappearance", min(1.0, lifetime))
	elif state == State.DISAPPEAR:
		lifetime-=delta/disappearance_time
		material.set_shader_parameter("disappearance", min(1.0, lifetime))
		if lifetime < 0.:
			get_parent().remove_child(self)

# Return new corps
func move_to(where: Transform3D):
	state = State.DISAPPEAR
	var corpse = self.duplicate()
	corpse.dalek_id = dalek_id
	corpse.killed = false
	corpse.color = color
	corpse.disappearance_time = disappearance_time
	get_parent().add_child(corpse)
	corpse.global_transform = where
	return corpse
