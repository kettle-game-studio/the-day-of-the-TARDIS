class_name SSTCompilerConfig
extends Resource

var _materials: Array[Material] = []
var _environments: Array[Environment] = []
var _nodes: Array[Dictionary] = []

@export var materials: Array[Material]:
	get:
		return _materials
	set(value):
		_materials = value
		emit_changed()

@export var environments: Array[Environment]:
	get:
		return _environments
	set(value):
		_environments = value
		emit_changed()

@export var nodes: Array[Dictionary]:
	get:
		return _nodes
	set(value):
		_nodes = value
		emit_changed()


func add_triggers(nodes_report: Array):
	for node in nodes_report:
		for trigger in node["triggers"]:
			if trigger["type"] == SSTTriggerCandidate.Type.RESOURCE:
				var path = trigger["path"]
				var resource := load(path)
				if resource is Material:
					materials.push_back(resource)
				if resource is Shader:
					var shader := resource as Shader
					var mat := ShaderMaterial.new()
					mat.shader = shader
					materials.push_back(mat)
				if resource is Environment:
					environments.push_back(resource)
			else:
				nodes.push_back(node["tree_nodes"].back())
	emit_changed()


func clear():
	materials.clear()
	environments.clear()
	nodes.clear()
	emit_changed()


func add_from_scenes(scenes: Array[PackedScene]):
	var collector := SSTTriggerCollector.new()
	for scene in scenes:
		var root := scene.instantiate()
		_extract(root, collector)
		add_triggers(collector.report())
		collector.clear()
		root.free()


static func _extract(node: Node, collector: SSTTriggerCollector):
	collector.add_new_triggers(node, SSTTriggerCandidate.from(node))
	for child in node.get_children():
		_extract(child, collector)
