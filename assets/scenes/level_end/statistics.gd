extends Node3D

@export var level: AbstractLevel
@onready var deaths = $Deaths
@onready var time = $Time
# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred("subscibe")

func subscibe():
	level.game.end_game.connect(update_stats)

func update_stats():
	var g = level.game
	time.text = "Время:\n\n%s" % [beautify_time(roundi(g.play_time))]
	deaths.text = "Смерти:\n\n%s" % [g.died_count]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func beautify_time(time: int) -> String:
	var seconds = beautify_number((time) % 60)
	var minutes = beautify_number((time / 60) % 60)
	var hours = beautify_number(time / 60 / 60)
	return "%s:%s:%s" % [hours, minutes, seconds]

func beautify_number(num: int) -> String:
	if num < 10:
		return "0%d" % num
	else:
		return "%d" % num
