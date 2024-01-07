extends CanvasLayer
class_name UIContoller

@export var ui_dialog: RichTextLabel
@export var ui_avatar: TextureRect
@onready var ui_container = $DialogPanel
@onready var display_timer = $DisplayTimer
@onready var debug = $Label
@export var doctorTexture: Texture2D
@export var tardisTexture: Texture2D

var formats = {
	"Doctor": {
		"format": "%s"
	},
	"TARDIS": {
		"format": "[i]%s[/i]"
	}
}

signal dialog_finished()

func _ready():
	hide_speech()
	formats.Doctor.avatar = doctorTexture
	formats.TARDIS.avatar = tardisTexture
	display_timer.timeout.connect(hide_speech)

func display_speech_line(line: Dictionary, display_time = -1):
	var who = line.get("who")
	ui_dialog.text = formats[who].format % line.get("text")
	ui_avatar.texture = formats[who].avatar
	ui_container.show()
	if display_time > 0:
		display_timer.start(display_time)

signal _continue_dialog()
var _skip_dialog_flag = false
func _input(event):
	if Input.is_action_just_pressed("next_dialog"):
		_skip_dialog_flag = false
		_continue_dialog.emit()
	elif Input.is_action_just_pressed("skip_dialog"):
		_skip_dialog_flag = true
		_continue_dialog.emit()
		
func _async_dialog(dialog: Array[Dictionary]):
	for line in dialog:
		display_speech_line(line)
		print_debug(line)
		await _continue_dialog
		if _skip_dialog_flag:
			break
	dialog_finished.emit()
	hide_speech()

func play_dialog(dialog: Array[Dictionary]):
	_async_dialog(dialog)

func _process(delta):
	pass

func hide_speech():
	ui_container.hide()
