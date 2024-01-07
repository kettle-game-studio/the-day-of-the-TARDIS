extends CanvasLayer
class_name UIContoller

@export var ui_dialog: RichTextLabel
@export var ui_avatar: TextureRect
@onready var ui_container = $DialogPanel
@onready var display_timer = $DisplayTimer
@onready var continue_timer = $ContinueTimer
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
	continue_timer.timeout.connect(func(): _continue_dialog.emit())

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

func _async_dialog(dialog, autoskip = false):
	for line in dialog:
		display_speech_line(line)
		if autoskip:
			continue_timer.start(5)
		await _continue_dialog
		continue_timer.stop()
		if _skip_dialog_flag:
			break
	dialog_finished.emit()
	hide_speech()

# : Array[Dictionary]
func play_dialog(dialog, autoskip = false):
	_async_dialog(dialog, autoskip)

func _process(delta):
	pass

func hide_speech():
	ui_container.hide()

