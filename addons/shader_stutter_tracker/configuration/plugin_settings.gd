class_name SSTPluginSettings
extends RefCounted

const PREFIX := "shader_stutter_tracker/"

var base := BaseSettings.new()
var shader_watcher := SSTShaderWatcher.Settings.new("shader_watcher/")
var report := SSTReportService.Settings.new("logs/")

var settings: Array[SSTSettingSpec]


func _init():
	settings = _get_settings_list()


func add_to_project_settings():
	for setting in settings:
		if not ProjectSettings.has_setting(setting.name):
			ProjectSettings.set_setting(setting.name, setting.default)
			ProjectSettings.set_initial_value(setting.name, setting.default)
			if Engine.is_editor_hint():
				ProjectSettings.add_property_info(setting.property_info)
				ProjectSettings.set_as_basic(setting.name, setting.basic)


func delete_from_project_settings():
	for setting in settings:
		if ProjectSettings.has_setting(setting.name):
			ProjectSettings.set_setting(setting.name, null)


func _get_settings_list() -> Array[SSTSettingSpec]:
	var res: Array[SSTSettingSpec] = []
	for property in get_property_list():
		if property["type"] == TYPE_OBJECT && self[property.name] is SSTSettingSpec.Group:
			var group := self[property.name] as SSTSettingSpec.Group
			var prefix := PREFIX + group.group_name
			for p in group.get_property_list():
				if p["type"] == TYPE_OBJECT && group[p.name] is SSTSettingSpec:
					var s := group[p.name] as SSTSettingSpec
					s.prefix = prefix
					res.push_back(s)
	return res


class BaseSettings:
	extends SSTSettingSpec.Group

	func _init():
		super._init("")


	var preserve_settings := SSTSettingSpec.new("preserve_settings_when_disabled", false)
