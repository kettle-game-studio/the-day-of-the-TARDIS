extends RichTextLabel
class_name InputSyncedLabel
@export_multiline var raw_text: String:
	get:
		return _raw_text
	set(value):
		_raw_text = value
		_redraw_text()
	
var _raw_text: String = ""

func _redraw_text(_new_device = null):
	text = InputDeviceLocaliser.format_actions(_raw_text)

func _init() -> void:
	bbcode_enabled = true

func _ready() -> void:
	_redraw_text()

func _enter_tree() -> void:
	InputDeviceLocaliser.device_changed.connect(_redraw_text)

func _exit_tree() -> void:
	InputDeviceLocaliser.device_changed.disconnect(_redraw_text)	
