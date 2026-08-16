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
	EditorInterface.inspect_object(null)
	EditorInterface.inspect_object(res)
