extends Node3D
class_name AbstractLevel

@export var player: PlayerController
@export var portal_controller: PortalController
var present: Timezone
var future: Timezone

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
