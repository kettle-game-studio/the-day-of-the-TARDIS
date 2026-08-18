@tool
class_name SSTScenesCompilerConfig
extends SSTCompilerConfig

# Scan scenes for triggers on build export
@export var rescan_on_export := false
# Scan scenes for triggers on play in editor
@export var rescan_on_play := false

@export var scenes: Array[PackedScene]:
	get:
		return _scenes
	set(value):
		_scenes = value
		emit_changed()

var _refreshing := false

var _scenes: Array[PackedScene] = []
var _refreshed := false


func get_materials() -> Array[Material]:
	_lazy_rescan()
	return super.get_materials()


func get_environments() -> Array[Environment]:
	_lazy_rescan()
	return super.get_environments()


func get_nodes() -> Array[Dictionary]:
	_lazy_rescan()
	return super.get_nodes()


func refresh(save = true):
	clear()
	add_from_scenes(scenes)
	emit_changed()
	if resource_path != "":
		ResourceSaver.save(self, resource_path)


func add_all_scenes():
	scenes.clear()
	var scene_exts := ResourceLoader.get_recognized_extensions_for_type("PackedScene")
	_scan_scenes("res://assets", scene_exts, scenes)
	emit_changed()


func get_scenes_in_folder(folder_path: String) -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	var scene_exts := ResourceLoader.get_recognized_extensions_for_type("PackedScene")
	_scan_scenes(folder_path, scene_exts, result)
	return result


func _scan_scenes(folder_path: String, scene_exts: Array, result: Array[PackedScene]) -> void:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path := folder_path.path_join(file_name)

			if dir.current_is_dir():
				_scan_scenes(full_path, scene_exts, result)
			else:
				var ext := file_name.get_extension().to_lower()
				if ext in scene_exts:
					var scene := load(full_path)
					if scene is PackedScene:
						print(full_path)
						result.append(scene)

		file_name = dir.get_next()

	dir.list_dir_end()


func _on_export():
	if rescan_on_export:
		refresh(false)


func _lazy_rescan():
	if Engine.is_editor_hint() or not OS.has_feature("editor_runtime"):
		return
	if _refreshing:
		return
	if rescan_on_play and not _refreshed:
		_refreshing = true
		refresh(false)
		_refreshed = true
		_refreshing = false
