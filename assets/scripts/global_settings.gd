extends Resource
class_name GlobalSettings

@export var mouse_sensitivity: float:
	get:
		return _mouse_sensitivity
	set(value):
		if(value!=_mouse_sensitivity):
			_mouse_sensitivity = value
			emit_changed()

@export var audio_sounds_volume: float:
	get:
		return db_to_linear(AudioServer.get_bus_volume_db(_sounds_bus_index))
	set(value):
		AudioServer.set_bus_volume_db(_sounds_bus_index, linear_to_db(value))

var _sounds_bus_index: int
var _mouse_sensitivity = 0.5
func _init():
	_sounds_bus_index = AudioServer.get_bus_index("Sounds")
