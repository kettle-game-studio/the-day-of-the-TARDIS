@tool
extends SubViewport

func _process(delta):
	var new_size = DisplayServer.window_get_size()
	if size != new_size:
		size = new_size	;
