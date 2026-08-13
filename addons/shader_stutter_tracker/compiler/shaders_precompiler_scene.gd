extends Node

@export var next_scene: PackedScene
@onready var precompiler := $ShaderPrecompiler
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func run_next_scene() -> void:
	await get_tree().process_frame
	#await get_tree().process_frame
	#await debug_scene(next_scene)
	#get_tree().quit()
	#return
	get_tree().change_scene_to_packed(next_scene)
