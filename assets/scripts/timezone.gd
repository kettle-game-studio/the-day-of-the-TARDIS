extends Node3D
class_name Timezone

enum RoomType{ PRESENT, FUTURE }

@export var roomType: RoomType

var daleks: Array[Dalek] = []
var alive_daleks_map: Dictionary = {}
# Initialized by parent
var level: AbstractLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	var daleks_nodes = find_children("*", "Dalek")
	for node in daleks_nodes:
		var dalek = node as Dalek
		daleks.push_back(dalek)
		dalek.timezone = self
		assert(!alive_daleks_map.has(dalek.dalek_id), "Dublicated dalek with id %d in %s" % [dalek.dalek_id, RoomType.keys()[roomType]])
		alive_daleks_map[dalek.dalek_id] = dalek
		dalek.died.connect(_on_dalek_died)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _get_configuration_warnings():
	var warnings = []
	if !(get_parent_node_3d() is AbstractLevel):
		warnings.push_back("Timezone should be child of Level class")
	return warnings

func _on_dalek_died(dalek: Dalek):
	
	alive_daleks_map.erase(dalek.dalek_id)
