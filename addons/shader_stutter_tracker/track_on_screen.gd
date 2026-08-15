extends VisibleOnScreenNotifier3D

var watchable: VisualInstance3D
var worked = false


func _init(target: VisualInstance3D, on_enter: Callable):
	watchable = target
	assert(screen_entered.connect(on_enter, CONNECT_ONE_SHOT) == 0)
	screen_entered.connect(_test, CONNECT_ONE_SHOT)


func _ready() -> void:
	if watchable is GPUParticles3D or watchable is CPUParticles3D:
		aabb = watchable.visibility_aabb
	else:
		aabb = watchable.get_aabb()


func _test():
	worked = true
