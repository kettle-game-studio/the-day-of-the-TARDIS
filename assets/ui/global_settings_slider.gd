extends HSlider

@export var field_name: String
@export var settings: GlobalSettings

var bus_index
func _ready():
	value = settings[field_name]
	value_changed.connect(_on_value_changed)

func _on_value_changed(value: float):
	settings[field_name] = value
