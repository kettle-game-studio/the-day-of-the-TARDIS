extends Container
class_name Menu

var sections: Dictionary = {}

func _input(event):
	if Input.is_action_just_pressed("escape"):
		call_deferred("back_menu")

var menu_stack: Array[MenuSection] = []

func _ready():
	var menu_nodes = find_children("*", "MenuSection")
	for node in menu_nodes:
		var section  = node as MenuSection
		section.deactivate()
		sections[section.section_name] = node

func back_menu():
	var active_section = menu_stack.pop_back()
	active_section.deactivate()
	if menu_stack.size() == 0:
		resume()
		return
	menu_stack[menu_stack.size()-1].activate()

func resume():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func quit_game():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func open(section_name = ""):
	if !get_tree().paused:
		get_tree().paused= true
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if menu_stack.size() > 0:
		menu_stack[menu_stack.size()-1].deactivate()
	var current_section = sections[section_name]
	current_section.activate()
	menu_stack.push_back(current_section)

func _process(delta):
	pass
