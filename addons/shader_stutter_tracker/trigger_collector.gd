class_name SSTTriggerCollector
extends RefCounted

var saw_triggers: Dictionary[Dictionary, int] = { }
var on_screen_triggers: Array[Node] = []
var saw_keys: Dictionary[String, Dictionary] = { }

func report() -> Array:
	return on_screen_triggers.map(
		func(n: Node):
			return n.get_meta(&"Report"),
	)

func clear() -> void:
	on_screen_triggers.clear()

func size() -> int:
	return saw_keys.size()

func copy_as_scene() -> PackedScene:
	var packed_scene = PackedScene.new()
	var root = Node.new()
	root.name = "root"
	for item in on_screen_triggers:
		var node := SSTNodeUtils.copy_from_root(item, root)
		node.set_meta(&"Report", item.get_meta(&"Report"))
	assert(packed_scene.pack(root) == Error.OK)
	root.free()
	return packed_scene

func add_new_triggers(node: Node, triggers: Array[SSTTriggerCandidate]):
	var filtered = triggers.filter(
		func(t):
			return !saw_triggers.has(t.key),
	)
	if filtered.is_empty():
		return
	if not add_new_triggers_force(node, filtered):
		return
	var time = Time.get_ticks_msec()
	for t in filtered:
		saw_triggers[t.key] = time

func add_node_as_trigger_force(node: Node):
	pass

func add_new_triggers_force(node: Node, triggers: Array[SSTTriggerCandidate]):
	if node in on_screen_triggers:
		return false
	node.set_meta(
		&"Report",
		{
			"tree_nodes": SSTNodeUtils.owners_chain(node),
			"triggers": triggers.map(
				func(t: SSTTriggerCandidate):
					return t.to_dict(),
			),
		},
	)
	on_screen_triggers.push_back(node)
	return true
