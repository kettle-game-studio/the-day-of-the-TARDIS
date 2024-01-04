extends Node3D

@export var bullet_prefab: PackedScene
@export var scene: Node3D

@onready var bullet_pivot = $BulletPivot
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fire():
	var bullet = bullet_prefab.instantiate()
	scene.add_child(bullet)
	bullet.global_position = bullet_pivot.global_position
	bullet.global_rotation = bullet_pivot.global_rotation
