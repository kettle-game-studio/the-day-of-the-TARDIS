extends Node3D
class_name DalekCorpse

@onready var label = $SubViewport/Panel/Label

var dalek_id = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = "RIP Dalek %d" % [dalek_id]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
