class_name ShadersCompilerConfig
extends Resource

@export var materials: Array[Material] = []
@export var environments: Array[Environment] = []
@export var nodes: Array[Dictionary] = []


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
