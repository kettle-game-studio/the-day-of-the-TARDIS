extends Node3D
class_name DalekCorpse


var dalek_id = 0
var killed = false
@onready var explosion = $Explosion
# Called when the node enters the scene tree for the first time.
func _ready():
	if !killed:
		remove_child(explosion)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
