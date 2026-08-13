@tool
class_name SSTScenesCompilerConfig
extends SSTCompilerConfig

# Auto rescan scenes for materials on build export
@export var rescan_on_export := false
# Auto rescan scenes for materials on play in editor
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
