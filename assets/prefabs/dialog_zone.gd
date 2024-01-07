extends Area3D
class_name DialogZone

signal player_entered(zone: DialogZone)

@export var speech: Array[Dictionary] = [{"who": "TARDIS", "text": "WHORP"}]



func _on_body_entered(body):
	player_entered.emit(self)
