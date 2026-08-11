class_name SSTShaderCacheService

const CACHE_DIR := "user://shader_cache"


## Returns statistics about the number of cached shader files per directory.
static func get_stats() -> Dictionary[String, int]:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		return {}

	var dirs := DirAccess.get_directories_at(CACHE_DIR)
	var stats: Dictionary[String, int] = {}
	
	for dir in dirs:
		if not dir.contains("Shader"):
			continue
		
		var count := 0
		var dir_path := CACHE_DIR + "/" + dir
		
		for subdir in DirAccess.get_directories_at(dir_path):
			count += DirAccess.get_files_at(dir_path + "/" + subdir).size()
			
		stats[dir] = count
	return stats


## Clears all files within the shader cache directories.
static func clear_cache() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		return

	var dirs := DirAccess.get_directories_at(CACHE_DIR)
	for dir in dirs:
		var dir_path := CACHE_DIR + "/" + dir
		for subdir in DirAccess.get_directories_at(dir_path):
			var subdir_path := dir_path + "/" + subdir
			var d := DirAccess.open(subdir_path)
			if d:
				for file in DirAccess.get_files_at(subdir_path):
					d.remove(file)


## Calculates the difference between two statistics dictionaries.
static func diff(
	old: Dictionary[String, int],
	new: Dictionary[String, int],
) -> Dictionary[String, int]:
	var res: Dictionary[String, int] = {}
	
	# Combine all keys from both dictionaries
	var all_keys := old.keys()
	for key in new.keys():
		if not all_keys.has(key):
			all_keys.append(key)
	
	for key in all_keys:
		var diff_val: int = new.get_or_add(key, 0) - old.get_or_add(key, 0)
		if diff_val != 0:
			res[key] = diff_val
			
	return res
