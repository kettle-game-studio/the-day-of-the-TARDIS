extends Node

var Settings := preload("res://addons/shader_stutter_tracker/settings.gd")
const PLUGIN_DATA_DIR := "user://shader_stutter_tracker"
const ACTIVE_LOGS_SUBDIR := "logs"

signal new_tick_processed
signal new_shaders_compiled(report: Dictionary)

func logs_rotation():
	DirAccess.make_dir_recursive_absolute(PLUGIN_DATA_DIR)
	var oldest_logs := ""
	var logs_count := 0
	var current_time := Time.get_datetime_string_from_system().replace(":", ".")
	var root := DirAccess.open(PLUGIN_DATA_DIR)
	if root.dir_exists(ACTIVE_LOGS_SUBDIR):
		root.rename(ACTIVE_LOGS_SUBDIR, "%s_%s" % [ACTIVE_LOGS_SUBDIR, current_time])
	var max_logs: int = settings.preseve_last_n_logs.value
	var logs := Array(root.get_directories()).filter(func (s: String): return s.begins_with(ACTIVE_LOGS_SUBDIR))
	if max_logs >= 0 && max_logs < logs.size():
		for dir in logs.slice(max_logs):
			root.remove(dir)
	root.make_dir(ACTIVE_LOGS_SUBDIR)

func _init() -> void:
	settings.add_to_project_settings()
	logs_rotation()
	if settings.clear_cache_on_start.value:
		SSTShaderCacheService.clear_cache()
	prev_stats = SSTShaderCacheService.get_stats()
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_monitor(shader_key: String) -> void:
	var keys := shader_key.split("Shader")
	var name := &"shaders_cache_%s/%s" % [keys[1], keys[0]]
	if not Performance.has_custom_monitor(name):
		Performance.add_custom_monitor(name, get_shaders_count, [shader_key])

func _ready() -> void:
	for shader in prev_stats:
		register_monitor(shader)	

var settings := Settings.new()
var prev_stats: Dictionary[String, int] = {}
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	work.call_deferred()

func work():
	var new_stats := SSTShaderCacheService.get_stats()
	if new_stats != prev_stats:
		var frame_number := Engine.get_process_frames()
		var new_shaders := SSTShaderCacheService.diff(prev_stats, new_stats)
		var scene_path := PLUGIN_DATA_DIR.path_join(ACTIVE_LOGS_SUBDIR).path_join("%d.tscn" % frame_number)
		for key in new_shaders:
			register_monitor(key)
		new_shaders_compiled.emit({
			"frame": {
				"number": frame_number,
				"scene_path": scene_path,
				},
			"new_shaders": new_shaders
		})
		var save_scene: bool = settings.save_scenes.value
		var saved := save_scene
		
		if save_scene:
			var packed_scene := SSTVisibleTracker.copy_visible_as_scene()
			saved = ResourceSaver.save(packed_scene, scene_path) == Error.OK
		var screenshot := get_viewport().get_texture().get_image()
		
		var report := {
			"frame": {
				"number": frame_number,
				"scene_path": scene_path,
				"scene_saved": saved,
				"screenshot": screenshot.save_png_to_buffer(),
			},
			"new_shaders": new_shaders,
			"nodes": SSTVisibleTracker.report(),
		}
		#print(report)
		EngineDebugger.send_message("shader_stutter_tracker:stutter_event", [report])
		prev_stats = new_stats
		
	SSTVisibleTracker.clear()
	new_tick_processed.emit()

func get_shaders_count(name: StringName) -> int:
	return prev_stats.get(name, 0)
