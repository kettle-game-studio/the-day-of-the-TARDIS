extends Container
class_name Menu

func _input(event):
	if Input.is_action_just_pressed("escape"):
		call_deferred("resume")		

@onready var main_menu = $MarginContainer/MainMenu

class MenuItem:
	var text: String
	var callback: Callable
	func _init(t: String, c: Callable):
		text = t
		callback = c
	func activate():
		callback.call()

func resume():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func quit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func open():
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	main_menu.get_child(0).grab_focus()

func _ready():
	pass


func _process(delta):
	pass
