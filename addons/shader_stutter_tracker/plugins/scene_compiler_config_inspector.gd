@tool
extends EditorInspectorPlugin


func _can_handle(object):
	return object is SSTScenesCompilerConfig


func _parse_property(
	object: Object,
	_type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags,
	_wide: bool,
):
	if name == "scenes":
		_add_rescan_button(object)
		_add_collect_scenes_button(object)
	return false


func _add_rescan_button(object):
	var b := Button.new()
	b.text = "Rescan scenes"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_custom_control(b)
	b.pressed.connect(
		func():
			_on_refresh_pressed(object),
	)
func _on_refresh_pressed(res: SSTScenesCompilerConfig):
	res.refresh()
	_refresh_ui(res)

func _add_collect_scenes_button(object):
	var b := Button.new()
	b.text = "Add all scenes"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_custom_control(b)
	b.pressed.connect(
		func():
			_on_collect_scenes_pressed(object),
	)

func _refresh_ui(res):
	await EditorInterface.get_base_control().get_tree().process_frame
	EditorInterface.inspect_object(null)
	EditorInterface.inspect_object(res)

func _on_collect_scenes_pressed(res: SSTScenesCompilerConfig):
	res.add_all_scenes()
	_refresh_ui(res)
