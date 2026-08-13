@tool
extends EditorExportPlugin

func _begin_customize_resources(platform: EditorExportPlatform, features: PackedStringArray):
	print(platform)
	print(features)
	var t := Resource.new()
	ResourceSaver.save(t, "res://assets/TEST_EXPORT.tres")
	return false
