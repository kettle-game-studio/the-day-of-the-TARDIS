extends Node3D
class_name AbstractLevel

@export var player: PlayerController
@export var portal_controller: PortalController
var present: Timezone
var future: Timezone
var clock = 0.0

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
		future_dalek.die()
