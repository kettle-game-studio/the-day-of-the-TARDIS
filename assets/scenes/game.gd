extends Node3D

var levels: Array[AbstractLevel] = []
var current_level = 0
@onready var debug = $Label

@onready var dalek_cemetery = $DalekCemetery
@onready var player = $Player
@onready var portal_controller = $PortalController
# Called when the node enters the scene tree for the first time.
func _ready():
	var lvls_nodes = find_children("*", "AbstractLevel")
	for node in lvls_nodes:
		var level = node as AbstractLevel
		levels.push_back(level)
		level.dalek_home = dalek_cemetery
		level.player = player
		level.portal_controller = portal_controller
		level.level_finished.connect(_on_level_finished)
	debug.text = "%d level" % current_level

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if Input.is_action_just_pressed("restart_level"):
		levels[current_level].restart()

func _on_level_finished(level: AbstractLevel):
	if level == levels[current_level]:
		if current_level < levels.size() - 1:
			current_level+=1
			debug.text = "%d level" % current_level	
		else:
			debug.text = "WIN"				
