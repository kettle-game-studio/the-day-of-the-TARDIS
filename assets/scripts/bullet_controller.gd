extends Area3D
class_name BulletContoller

@export var speed = 6;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_move_direction():
	return -global_transform.basis.z
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position+= get_move_direction()*delta*speed
