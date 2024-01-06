extends Node3D
class_name Timezone

enum RoomType{ PRESENT, FUTURE }

signal all_daleks_died(timezone: Timezone)

@export var roomType: RoomType

var daleks: Array[Dalek] = []
var alive_daleks_map: Dictionary = {}
var corpses: Array[DalekCorpse] = []
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

func _on_dalek_died(dalek: Dalek, corpse: DalekCorpse, reason: BulletContoller):
	alive_daleks_map.erase(dalek.dalek_id)
	corpses.push_back(corpse)
	if alive_daleks_map.size() == 0:
		all_daleks_died.emit(self)

func restart():
	for corpse in corpses:
		corpse.get_parent_node_3d().remove_child(corpse)
	corpses.clear()
	alive_daleks_map.clear()
	for dalek in daleks:
		dalek.restart()
		alive_daleks_map[dalek.dalek_id] = dalek
