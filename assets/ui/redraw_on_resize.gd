extends RichTextLabel


var windows_size = Vector2i(0, 0)
func _process(delta):
	if DisplayServer.window_get_size() != windows_size:
		windows_size = DisplayServer.window_get_size()
		add_text(" ")
		print_debug(text)
