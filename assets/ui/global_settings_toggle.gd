extends Button

@export var field_name: String
@export var settings: GlobalSettings

func _ready():
	toggle_mode = true
	set_pressed_no_signal(settings[field_name])

func _toggled(value: bool):
	settings[field_name] = value
