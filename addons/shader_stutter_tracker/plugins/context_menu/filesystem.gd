@tool
extends EditorContextMenuPlugin

var save_dialog: EditorFileDialog

var _resource_to_save: SSTScenesCompilerConfig


func _exit_tree() -> void:
	if is_instance_valid(save_dialog):
		if save_dialog.file_selected.is_connected(_on_file_selected):
			save_dialog.file_selected.disconnect(_on_file_selected)
		save_dialog.queue_free()
		save_dialog = null


func _popup_menu(paths):
	var scenes: Array[PackedScene] = []
	var has_scenes := false
	for path in paths:
		if (path.ends_with(".tscn") or path.ends_with(".scn")):
			has_scenes = true
			break
	if has_scenes:
		_init_save_dialog()
		add_context_menu_item("Brute-force analysis...", _bruteforce)
		add_context_menu_item("Extract triggers from scenes...", _extract)

const BRUTE_FORCE_DEBUG = preload("uid://bv3kp7tsv0ml4")
const BruteForceDebug = preload("uid://nbnn1kdbeqk8")

func _bruteforce(paths):
	var tmp := BRUTE_FORCE_DEBUG.instantiate() as BruteForceDebug
	tmp.scenes = _get_scenes(paths)
	var pack := PackedScene.new()
	pack.pack(tmp)
	var tmp_project_dir := "res://.godot/shader_stutter_tracker/tmp"
	DirAccess.make_dir_recursive_absolute(tmp_project_dir)
	var filepath := tmp_project_dir + "/" + "bruteforce.scn"
	ResourceSaver.save(pack, filepath)
	EditorInterface.play_custom_scene(filepath)
func _get_scenes(paths) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for path in paths:
		if not (path.ends_with(".tscn") or path.ends_with(".scn")):
			continue
		print(path)
		var scene_path: String = path
		var scene: PackedScene = load(scene_path)
		scenes.push_back(scene)
	return scenes

func _extract(paths):
	var scenes := _get_scenes(paths)
	# var file := scene_path.get_basename() + "_triggers.tres"
	var res := SSTScenesCompilerConfig.new()
	res.scenes = scenes
	res.refresh()
	_save_to_user_file(res)


func _init_save_dialog() -> void:
	if save_dialog == null:
		save_dialog = EditorFileDialog.new()
		save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		save_dialog.title = "Save SSTScenesCompilerConfig"
		save_dialog.file_selected.connect(_on_file_selected)
		save_dialog.add_filter("*.tres", "Godot Resource")
		save_dialog.add_filter("*.res", "Binary Resource")
		EditorInterface.get_base_control().add_child(save_dialog)


func _save_to_user_file(res: SSTScenesCompilerConfig):
	_resource_to_save = res
	save_dialog.popup_file_dialog()


func _on_file_selected(path: String) -> void:
	_resource_to_save.take_over_path(path)
	ResourceSaver.save(_resource_to_save, path)
