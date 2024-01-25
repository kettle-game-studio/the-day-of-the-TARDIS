extends Area3D

@export var level: AbstractLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body):
	var p = level.portal_controller
	level.player.global_position += p._get_room_shift()
	p.disable_portal()
	level.player.state = PlayerController.State.INTRO
