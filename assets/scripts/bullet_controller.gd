extends Area3D
class_name BulletContoller

@export var speed = 6;
var ignore_bodies: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_move_direction():
	return -global_transform.basis.z
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position+= get_move_direction()*delta*speed


func _on_body_entered(body):
	if ignore_bodies.has(body):
		return
	if "_on_bullet" in body:
		body._on_bullet(self)
	get_parent().call_deferred("remove_child", self)
