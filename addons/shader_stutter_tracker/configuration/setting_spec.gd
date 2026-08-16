class_name SSTSettingSpec
extends RefCounted

var prefix: StringName = ""
var name: StringName
var default: Variant
var hint: PropertyHint
var hint_string: String
var basic: bool

var full_name: String:
	get:
		return prefix + name
var value:
	get ():
		if ProjectSettings.has_setting(full_name):
			return ProjectSettings.get_setting_with_override(full_name)
		return default
	set(val):
		ProjectSettings.set_setting(full_name, val)
var property_info:
	get ():
		return {
			"name": full_name,
			"type": typeof(default),
			"hint": hint,
			"hint_string": hint_string,
		}


func _init(
	name: StringName,
	default: Variant,
	hint: PropertyHint = PropertyHint.PROPERTY_HINT_NONE,
	hint_string: String = "",
	basic: bool = true,
) -> void:
	self.name = name
	self.default = default
	self.basic = basic
	self.hint = hint
	self.hint_string = hint_string


class Group:
	var group_name: String


	func _init(name: String):
		group_name = name
