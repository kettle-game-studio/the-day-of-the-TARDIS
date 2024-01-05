extends Node3D
class_name AbstractLevel

@export var player: PlayerController
var portal_controller: PortalController
var present: Timezone
var future: Timezone

# Called when the node enters the scene tree for the first time.
func _ready():
	var timezones = find_children("*", "Timezone")
	assert(timezones.size() == 2, "Incorrect timezones count")
	present = timezones.filter(func(z): return z.roomType == Timezone.RoomType.PRESENT)[0]
	present.level = self
	future = timezones.filter(func(z): return z.roomType == Timezone.RoomType.FUTURE)[0]
	future.level = self
	portal_controller = find_children("*", "PortalController")[0] as PortalController
	portal_controller.present_base = present
	portal_controller.future_base = future

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
