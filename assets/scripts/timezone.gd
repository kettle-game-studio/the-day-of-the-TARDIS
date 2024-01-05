@tool
extends Node3D
class_name Timezone

enum RoomType{ PRESENT, FUTURE }

@export var roomType: RoomType
var daleks: Array[Dalek] = []
# Initialized by parent
var level: AbstractLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	var daleks_nodes = find_children("*", "Dalek")
	for node in daleks_nodes:
		var dalek = node as Dalek
		daleks.push_back(dalek)
		dalek.timezone = self
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _get_configuration_warnings():
	var warnings = []
	if !(get_parent_node_3d() is AbstractLevel):
		warnings.push_back("Timezone should be child of Level class")
	return warnings
