extends Node3D
class_name DalekCorpse


var dalek_id = 0
var killed = false
var disappearance_time = 1.
var translated_from: Vector3
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
var particles_material: ShaderMaterial

# Called when the node enters the scene tree for the first time.
var lifetime = 1
var material: ShaderMaterial
func _ready():
	particles.lifetime = disappearance_time/2.
	material = mesh_body.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("color", color)
	mesh_body.set_surface_override_material(0, material)
	mesh_head.set_surface_override_material(0, material)
	if !killed:
		particles.emitting = true		
		lifetime = 0.0
		remove_child(explosion)
		particles_material = particles.process_material
		particles_material = particles_material.duplicate()
		particles.process_material = particles_material
		call_deferred("set_particles_settings")

func set_particles_settings():
	particles_material.set_shader_parameter("color", color)
	particles_material.set_shader_parameter("start_point", translated_from)
	particles_material.set_shader_parameter("end_point", global_position)
	particles_material.set_shader_parameter("end_dirt", material.get_shader_parameter("dirty"))
	if from_corpse:
		particles_material.set_shader_parameter("start_dirt", material.get_shader_parameter("dirty"))
		particles_material.set_shader_parameter("start_height", 0.8)
	

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
	corpse.translated_from = global_position
	corpse.from_corpse = true
	get_parent().add_child(corpse)
	corpse.global_transform = where
	return corpse
