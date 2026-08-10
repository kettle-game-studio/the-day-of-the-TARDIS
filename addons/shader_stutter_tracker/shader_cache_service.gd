class_name SSTShaderCacheService


static func get_stats() -> Dictionary[String, int]:
	var dirs := DirAccess.get_directories_at("user://shader_cache")
	var stats: Dictionary[String, int] = { }
	for dir in dirs:
		if not dir.contains("Shader"):
			continue
		var count = 0
		for subdir in DirAccess.get_directories_at("user://shader_cache/" + dir):
			count += DirAccess.get_files_at("user://shader_cache/%s/%s" % [dir, subdir]).size()
		stats[dir] = count
	return stats


static func clear_cache():
	var dirs := DirAccess.get_directories_at("user://shader_cache")
	for dir in dirs:
		for subdir in DirAccess.get_directories_at("user://shader_cache/" + dir):
			var d := DirAccess.open("user://shader_cache/%s/%s" % [dir, subdir])
			for file in DirAccess.get_files_at("user://shader_cache/%s/%s" % [dir, subdir]):
				d.remove(file)


static func diff(
	old: Dictionary[String, int],
	new: Dictionary[String, int],
) -> Dictionary[String, int]:
	var d := old.duplicate()
	for key in d.keys():
		d[key] = new.get_or_add(key, 0) - d[key]
	for key in new.keys():
		if !d.has(key):
			d[key] = new[key]
	var res: Dictionary[String, int] = { }
	for key in d.keys():
		var v = d[key]
		if v != 0:
			res[key] = v
	return res
