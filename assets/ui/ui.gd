extends CanvasLayer
class_name UIContoller

@export var ui_dialog: InputSyncedLabel
@export var ui_avatar: TextureRect
@onready var ui_container = $DialogPanel
@onready var continue_timer = $ContinueTimer
@onready var debug = $Label
@onready var cursor = $Cursor
@onready var menu = $Menu
@onready var dialog_progress = $DialogPanel/UI/ProgressBar
@export var settings: GlobalSettings

@export var dialog_actors: Array[Actor]

var formats = {}

signal dialog_finished()

@export var controls_help_container: Container

@export
var controls_label: RichTextLabel
func _ready():
	hide_speech()
	menu.hide()
	continue_timer.timeout.connect(func(): if settings.dialog_auto_continue: _continue_dialog.emit(false))

	InputDeviceLocaliser.render_actions_table(controls_label)
	for actor in dialog_actors:
		formats[actor.name] = actor


func display_speech_line(line: Remark):
	var who = line.who
	ui_dialog.raw_text = formats[who].formatting % line.text
	ui_avatar.texture = formats[who].avatar
	ui_container.show()


signal _continue_dialog(full_skip: bool)

func _input(event):
	if event.is_action_pressed("next_dialog"):
		_continue_dialog.emit(false)
	elif event.is_action_pressed("skip_dialog"):
		_continue_dialog.emit(true)
	elif event.is_action_pressed("escape"):
		menu.open()

func _async_dialog(dialog :Dialog):
	for line in dialog.remarks:
		display_speech_line(line)
		continue_timer.start(15)
		var _skip_dialog_flag = await _continue_dialog
		continue_timer.stop()
		if _skip_dialog_flag:
			break
	dialog_finished.emit()
	hide_speech()

# : Array[Dictionary]
func play_dialog(dialog: Dialog):
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
