extends EditorDebuggerPlugin

const DebugTabScene := preload("res://addons/shader_stutter_tracker/debug/debug_tab.tscn")
const DebugTab := preload("res://addons/shader_stutter_tracker/debug/debug_tab.gd")

var session_tabs: Dictionary[int, DebugTab] = { }


func clear_session(session_id: int):
	session_tabs[session_id].clear()


func _has_capture(capture):
	return capture == "shader_stutter_tracker"


func _capture(message, data, session_id):
	if message == "shader_stutter_tracker:stutter_event":
		var report: Dictionary = data[0]
		var tab := session_tabs[session_id]
		tab.add_frame(report)
		return true
	return false


func _setup_session(session_id):
	var session := get_session(session_id)
	var tab := DebugTabScene.instantiate()
	tab.name = "Shader Freeze Tracker"
	session_tabs[session_id] = tab
	session.add_session_tab(tab)
	session.started.connect(clear_session.bind(session_id))
