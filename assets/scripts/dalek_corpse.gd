extends Node3D
class_name DalekCorpse


var dalek_id = 0
var killed = false
var disappearance_time = 1.
var translated_from: Vector3
var rotated_from: Vector3
var from_corpse = false

enum State {
	APPEAR, DISAPPEAR
}
var state = State.APPEAR

@export var color: Color

@onready var mesh_body = $Armature/Skeleton3D/DalekBreak
@onready var mesh_head = $Armature/Skeleton3D/DalekBeakHead
@onready var explosion = $Explosion
@onready var particles = $DalekTranslateParticles
@onready var collider = $Collider

var _lifetime = 1.0
var lifetime: float:
	get:
		return _lifetime
	set(value):
		_lifetime = value
		material.set_shader_parameter("disappearance", clamp(_lifetime, 0.0, 1.0))
		colliderShape.height = _lifetime*initialShapeHeight
		collider.position.y = _lifetime*initialColliderY

var material: ShaderMaterial
var particles_material: ShaderMaterial
var colliderShape: CylinderShape3D
var initialShapeHeight: float
var initialColliderY: float
func _ready():
	particles.lifetime = disappearance_time
	material = mesh_body.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("color", color)
	mesh_body.set_surface_override_material(0, material)
	mesh_head.set_surface_override_material(0, material)
	
	colliderShape = collider.shape.duplicate()
	collider.shape = colliderShape
	initialShapeHeight = colliderShape.radius
	initialColliderY = collider.position.y
	if !killed:
		particles.emitting = true
		remove_child(explosion)
		particles_material = particles.process_material
		particles_material = particles_material.duplicate()
		particles.process_material = particles_material
		lifetime = -1.0
		call_deferred("set_particles_settings")

func set_particles_settings():
	particles_material.set_shader_parameter("color", color)
	particles_material.set_shader_parameter("start_point", translated_from)
	particles_material.set_shader_parameter("start_rotation", rotated_from.y)
	particles_material.set_shader_parameter("end_point", global_position)
	particles_material.set_shader_parameter("end_rotation", global_rotation.y)
	particles_material.set_shader_parameter("end_dirt", material.get_shader_parameter("dirt"))
	if from_corpse:
		particles_material.set_shader_parameter("start_dirt", material.get_shader_parameter("dirt"))
		particles_material.set_shader_parameter("start_height", particles_material.get_shader_parameter("end_height"))
		particles_material.set_shader_parameter("start_neck", particles_material.get_shader_parameter("end_neck"))
	

func _process(delta):
	if state == State.APPEAR && lifetime < 1.:
		lifetime+=delta/disappearance_time
	elif state == State.DISAPPEAR:
		lifetime-=delta/disappearance_time
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
	corpse.translated_from = global_position
	corpse.rotated_from = global_rotation
	corpse.from_corpse = true
	get_parent().add_child(corpse)
	corpse.global_transform = where
	return corpse
