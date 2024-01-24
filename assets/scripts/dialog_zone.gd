extends Area3D
class_name DialogZone

signal player_entered(zone: DialogZone)

@export var player_state_in_dialog = PlayerController.State.DIALOG
@export var player_state_after = PlayerController.State.PLAY
@export var one_shot = true
@export var speech: Array[Dictionary] = [{"who": "TARDIS", "text": "WHORP"}]


func _on_body_entered(body):
	player_entered.emit(self)
