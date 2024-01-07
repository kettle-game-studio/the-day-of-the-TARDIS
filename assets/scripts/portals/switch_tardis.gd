extends Node


@export var area: Area3D
@export var portal_controller: PortalController


func _ready():
	area.body_entered.connect(callback)


func callback(x):
	portal_controller.switch_tardis()
