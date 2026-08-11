@tool
extends EditorPlugin

const SHADER_WATCHER_AUTOLOAD_NAME = "SSTShaderStutterWatcher"
const VISIBLE_TRACKER_AUTOLOAD_NAME = "SSTVisibleTracker"

const DebuggerPlugin := preload("res://addons/shader_stutter_tracker/debug/debugger_plugin.gd")

var settings := preload("res://addons/shader_stutter_tracker/settings.gd").new()
var context_menu := preload("res://addons/shader_stutter_tracker/context_menu/filesystem.gd").new()
var debugger := DebuggerPlugin.new()


func _enter_tree():
	add_debugger_plugin(debugger)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, context_menu)


func _exit_tree():
	remove_context_menu_plugin(context_menu)
	remove_debugger_plugin(debugger)


func _enable_plugin():
	settings.add_to_project_settings()
	add_autoload_singleton(
		SHADER_WATCHER_AUTOLOAD_NAME,
		"res://addons/shader_stutter_tracker/cache_watcher.gd",
	)
	add_autoload_singleton(
		VISIBLE_TRACKER_AUTOLOAD_NAME,
		"res://addons/shader_stutter_tracker/visible_tracker.gd",
	)


func _disable_plugin():
	remove_autoload_singleton(VISIBLE_TRACKER_AUTOLOAD_NAME)
	remove_autoload_singleton(SHADER_WATCHER_AUTOLOAD_NAME)
	if not settings.preserve_settings.value:
		settings.delete_from_project_settings()
