extends RefCounted

class Setting:
	const prefix = "shader_stutter_tracker"
	func _init(
			name: String, 
			default: Variant, 
			hint: PropertyHint = PropertyHint.PROPERTY_HINT_NONE,
			hint_string: String = "",
			basic: bool = true,
		) -> void:
		self.name = prefix+"/"+name
		self.default = default
		self.basic = basic
		self.hint = hint
		self.hint_string = hint_string
	var name: StringName
	var default: Variant
	var hint: PropertyHint
	var hint_string: String
	var basic: bool
	var value:
		get():
			if ProjectSettings.has_setting(name):
				return ProjectSettings.get_setting_with_override(name)
			return default
		set(val):
			ProjectSettings.set_setting(name, val)
	var property_info:
		get():
			return {
				"name": name,
				"type": typeof(default),
				"hint": hint,
				"hint_string": hint_string,
			}

var preserve_settings := Setting.new("preserve_settings_when_disabled", false)
var clear_cache_on_start := Setting.new("clear_cache_on_run", true)
var save_screenshots := Setting.new("save_screenshots", true)
var save_scenes := Setting.new("save_scenes", true)
var preseve_last_n_logs := Setting.new("preserve_last_logs", 3)

var settings: Array[Setting]

func _init():
	settings = _get_settings_list()
	
func _get_settings_list() -> Array[Setting]:
	var res: Array[Setting] = [];
	for property in get_property_list():
		if property["type"] == TYPE_OBJECT && self[property.name] is Setting:
			res.push_back(self[property.name])
	return res

func add_to_project_settings():
	for setting in settings:
		if not ProjectSettings.has_setting(setting.name):
			ProjectSettings.set_setting(setting.name, setting.default)
		ProjectSettings.set_initial_value(setting.name, setting.default)
		# TODO: check is editor
		ProjectSettings.add_property_info(setting.property_info)
		ProjectSettings.set_as_basic(setting.name, setting.basic)

func delete_from_project_settings():
	for setting in settings:
		if ProjectSettings.has_setting(setting.name):
			ProjectSettings.set_setting(setting.name, null)
