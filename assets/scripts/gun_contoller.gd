extends Node3D
class_name Gun

@export var bullet_prefab: PackedScene
@export var scene: Node3D
@export var reload_time = 1

@onready var bullet_pivot = $BulletPivot
@onready var timer = $Timer
@onready var shoot_audio_stream = $AudioStreamPlayer3D
var can_fire = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fire():
	if !can_fire:
		return
	shoot_audio_stream.play()
	can_fire = false
	timer.start(reload_time)
	var bullet = bullet_prefab.instantiate()
	scene.add_child(bullet)
	bullet.global_position = bullet_pivot.global_position
	bullet.global_rotation = bullet_pivot.global_rotation

func _reload_on_time():
	can_fire = true
