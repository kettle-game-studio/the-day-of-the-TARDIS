extends Node3D
class_name AbstractLevel

signal level_finished(level: AbstractLevel)

@export var player: PlayerController
@export var portal_controller: PortalController
@export var dalek_home: Node3D
@export var start_point: Node3D

var present: Timezone
var future: Timezone
var clock = 0.0

var start_timezone: Timezone

var player_room:
	get:
		return portal_controller.player_room

# Called when the node enters the scene tree for the first time.
func _ready():
	var timezones = find_children("*", "Timezone")
	assert(timezones.size() == 2, "Incorrect timezones count")
	present = timezones.filter(func(z): return z.roomType == Timezone.RoomType.PRESENT)[0]
	present.level = self
	future = timezones.filter(func(z): return z.roomType == Timezone.RoomType.FUTURE)[0]
	future.level = self
	
	present.all_daleks_died.connect(_on_present_daleks_died)
	if start_point.get_parent_node_3d() == present:
		start_timezone = present
	elif start_point.get_parent_node_3d() == future:
		start_timezone = future
	else:
		assert(false, "PLAYER SPAWN POINT SHOULD BE TIMEZONE CHILD")

	for dalek in present.daleks:
		dalek.killed.connect(_on_dalek_killed)
	for dalek in future.daleks:
		dalek.killed.connect(_on_dalek_killed)		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	clock+=delta

func _on_dalek_killed(dalek: Dalek, bullet: BulletContoller):
	if dalek.timezone == present && future.alive_daleks_map.has(dalek.dalek_id):
		var future_dalek = future.alive_daleks_map[dalek.dalek_id]
		future_dalek.die(null, dalek.global_transform.translated(portal_controller._get_to_future_shift()))

func _on_present_daleks_died(timezone: Timezone):
	level_finished.emit(self)

func restart():
	present.restart()
	future.restart()
	clock = 0.0
	portal_controller.disable_portal()
	portal_controller.player_room = start_timezone.roomType
	player.global_transform = start_point.global_transform
