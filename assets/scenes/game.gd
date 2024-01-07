extends Node3D

var levels: Array[AbstractLevel] = []
var current_level = 0
var died_count = 0
@onready var debug = $Label

@onready var dalek_cemetery = $DalekCemetery
@onready var player = $Player
@onready var portal_controller = $PortalController
# Called when the node enters the scene tree for the first time.
func _ready():
	player.killed.connect(_on_player_is_killed)
	var lvls_nodes = find_children("*", "AbstractLevel")
	for node in lvls_nodes:
		var level = node as AbstractLevel
		levels.push_back(level)
		level.dalek_home = dalek_cemetery
		level.player = player
		level.portal_controller = portal_controller
		level.level_finished.connect(_on_level_finished)
	debug.text = "%d level" % current_level
	levels[0].restart()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if Input.is_action_just_pressed("restart_level"):
		levels[current_level].restart()
		debug.text = "%d level\n%d died" % [current_level,	died_count]
	else:
		for i in range(0, min(10, levels.size())):
			if Input.is_key_label_pressed(KEY_0+i):
				levels[i].restart()
				current_level = i
				debug.text = "%d level\n%d died" % [current_level,	died_count]
				break

func _on_level_finished(level: AbstractLevel):
	if level == levels[current_level]:
		if current_level < levels.size() - 1:
			current_level+=1
			debug.text = "%d level\n%d died" % [current_level,	died_count]
		else:
			debug.text = "WIN\n%d died" % died_count

func _on_player_is_killed(_killer):
	died_count+=1
	debug.text = "%d level\n%d died" % [current_level,	died_count]
	levels[current_level].restart()
