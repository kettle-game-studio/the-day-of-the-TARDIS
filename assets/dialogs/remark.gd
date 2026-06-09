class_name Remark
extends Resource

@export var who: String
@export var text: String

func _init(p_who = "ТАРДИС", p_text = "") -> void:
	who = p_who
	text = p_text
