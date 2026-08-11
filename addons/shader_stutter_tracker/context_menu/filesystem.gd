@tool
extends EditorContextMenuPlugin


func _popup_menu(paths):
	init_save_dialog()
	if paths.size() == 1 and (paths[0].ends_with(".tscn") or paths[0].ends_with(".scn")):
		add_context_menu_item("Extract triggers...", extract)


func extract(paths):
	var scene_path: String = paths[0]
	var scene: PackedScene = load(scene_path)
	var root := scene.instantiate()
	var collector := SSTTriggerCollector.new()
	_extract(root, collector)
	var res := ShadersCompilerConfig.new()
	res.add_triggers(collector.report())
	var file := scene_path.get_basename() + "_triggers.tres"
	ResourceSaver.save(res, file)
	root.free()


func _extract(node: Node, collector: SSTTriggerCollector):
	collector.add_new_triggers(node, SSTTriggerCandidate.from(node))
	for child in node.get_children():
		_extract(child, collector)

var save_dialog: EditorFileDialog

func init_save_dialog() -> void:
	if save_dialog == null:
		save_dialog = EditorFileDialog.new()
		save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		save_dialog.title = "Сохранить файл"
		save_dialog.file_selected.connect(_on_file_selected)
		EditorInterface.get_base_control().add_child(save_dialog)

func _on_file_selected(path: String) -> void:
	print(path)

func _exit_tree() -> void:
	if is_instance_valid(save_dialog):
		if save_dialog.file_selected.is_connected(_on_file_selected):
			save_dialog.file_selected.disconnect(_on_file_selected)
		save_dialog.queue_free()
		save_dialog = null
