extends Node3D

@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func open():
	animation_player.play("open_door")	
	
func close():
	animation_player.play("close_door")	

func reset():
	animation_player.play("RESET")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
