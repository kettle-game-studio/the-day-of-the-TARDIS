extends Node

func get_stats():
	var dirs = DirAccess.get_directories_at("user://shader_cache")
	var stats: Array[String] = []
	for dir in dirs:
		var count = 0
		for subdir in DirAccess.get_directories_at("user://shader_cache/"+dir):
			count += DirAccess.get_files_at("user://shader_cache/%s/%s" % [dir, subdir]).size()
		stats.push_back("%s: %d" % [dir.trim_suffix("ShaderGLES3"), count])
	return "\n".join(stats)

func clear_cache():
	var dirs = DirAccess.get_directories_at("user://shader_cache")
	for dir in dirs:
		for subdir in DirAccess.get_directories_at("user://shader_cache/"+dir):
			var d = DirAccess.open("user://shader_cache/%s/%s" % [dir, subdir])
			for file in DirAccess.get_files_at("user://shader_cache/%s/%s" % [dir, subdir]):
				d.remove(file)


func _init() -> void:
	clear_cache()
	_process(0)

var take_screenshots = false
var prev_stats = ""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var new_stats = get_stats()
	if new_stats != prev_stats:
		prev_stats = new_stats
		var time = Time.get_ticks_msec()
		print(time)
		print(new_stats)
		if take_screenshots:
			get_viewport().get_texture().get_image().save_png("user://shader_cache/%d.png" % time)
