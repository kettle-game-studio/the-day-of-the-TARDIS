extends CanvasLayer
class_name UIContoller

@export var ui_dialog: RichTextLabel
@export var ui_avatar: TextureRect
@onready var ui_container = $DialogPanel
@onready var continue_timer = $ContinueTimer
@onready var debug = $Label
@onready var cursor = $Cursor
@onready var menu = $Menu
@onready var dialog_progress = $DialogPanel/UI/ProgressBar
@export var doctorTexture: Texture2D
@export var tardisTexture: Texture2D
@export var settings: GlobalSettings

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
	menu.hide()
	formats.Doctor.avatar = doctorTexture
	formats.TARDIS.avatar = tardisTexture
	continue_timer.timeout.connect(func(): if settings.dialog_auto_continue: _continue_dialog.emit(false))

func display_speech_line(line: Dictionary):
	var who = line.get("who")
	ui_dialog.text = formats[who].format % line.get("text")
	ui_avatar.texture = formats[who].avatar
	ui_container.show()

signal _continue_dialog(full_skip: bool)

func _input(event):
	if Input.is_action_just_pressed("next_dialog"):
		_continue_dialog.emit(false)
	elif Input.is_action_just_pressed("skip_dialog"):
		_continue_dialog.emit(true)
	elif Input.is_action_just_pressed("escape"):
		menu.open()

func _async_dialog(dialog):
	for line in dialog:
		display_speech_line(line)
		continue_timer.start(15)
		var _skip_dialog_flag = await _continue_dialog
		continue_timer.stop()
		if _skip_dialog_flag:
			break
	dialog_finished.emit()
	hide_speech()

# : Array[Dictionary]
func play_dialog(dialog):
	_async_dialog(dialog)

func _process(delta):
	if settings.dialog_auto_continue:
		dialog_progress.value = 100.0-continue_timer.time_left/15.0*100
		if !dialog_progress.visible:
			dialog_progress.show()
	elif dialog_progress.visible:
		dialog_progress.hide()
	

func hide_speech():
	ui_container.hide()

