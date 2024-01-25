extends Container
class_name MenuSection

@export var section_name: String
@export var focus_on_open: Control
func activate():
	show()
	if focus_on_open != null:
		focus_on_open.grab_focus()

func deactivate():
	hide()
