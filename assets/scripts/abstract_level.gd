extends Node3D
class_name AbstractLevel

signal level_finished(level: AbstractLevel)
signal level_restart(level: AbstractLevel)
signal level_failed(level: AbstractLevel)

@export var player: PlayerController
@export var portal_controller: PortalController
@export var dalek_home: Node3D
@export var start_point: Node3D

var present: Timezone
var future: Timezone
var clock = 0.0
var finished = false
var game: Game

var start_timezone: Timezone

var player_room:
	get:
		return portal_controller.player_room

# Called when the node enters the scene tree for the first time.
func _ready():
	failed_timer = Timer.new()
	add_child(failed_timer)
	failed_timer.one_shot = true
	failed_timer.stop()
	failed_timer.timeout.connect(_on_check_fail)
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
	if dalek.timezone == present:
		future.spawn_dalek_corpse(dalek.dalek_id, dalek.global_transform.translated(portal_controller._get_to_future_shift()))
	check_fail()

func _on_present_daleks_died(timezone: Timezone):
	finish_level()

func _on_check_fail():
	if present.alive_daleks_map.size() == 1 && future.alive_daleks_map.size() == 0:
		level_failed.emit(self)

func check_fail():
	failed_timer.start(5)

var failed_timer: Timer
func _on_future_daleks_died(timezone: Timezone):
	check_fail()

func finish_level():
	if finished:
		return
	finished = true
	level_finished.emit(self)

func restart():
	failed_timer.stop()
	finished = false
	present.restart()
	future.restart()
	clock = 0.0
	portal_controller.disable_portal()
	portal_controller.player_room = start_timezone.roomType
	player.global_transform = start_point.global_transform
	level_restart.emit(self)
