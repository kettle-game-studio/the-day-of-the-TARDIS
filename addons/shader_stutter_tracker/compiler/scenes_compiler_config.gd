@tool
class_name SSTScenesCompilerConfig
extends SSTCompilerConfig

var _scenes: Array[PackedScene] = []

@export var scenes: Array[PackedScene]:
	get:
		return _scenes
	set(value):
		_scenes = value
		emit_changed()

func refresh():
	clear()
	add_from_scenes(scenes)
	emit_changed()
	if resource_path != "":
		ResourceSaver.save(self, resource_path)
