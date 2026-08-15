class_name SSTNodeUtils
extends Object

static func create(description: Dictionary) -> Node:
	var clazz: StringName = description[&"class"]
	var properties: Dictionary = description[&"properties"]
	var node := ClassDB.instantiate(clazz)
	for property in properties:
		node.set(property, properties.get(property))
	return node

static func get_node_path(node: Node) -> NodePath:
	if node.is_inside_tree():
		return node.get_path()
	return _extract_path(node)

static func _extract_path(node: Node) -> NodePath:
	if node.get_parent() == null:
		return NodePath(node.name)
	return NodePath(String(_extract_path(node.get_parent())) + "/" + node.name)

static func get_description(node: Node) -> Dictionary:
	var owner := node.owner
	var original_scene := node.scene_file_path
	var owner_path := get_node_path(owner) if owner != null else null
	var path := get_node_path(node)
	var clazz := node.get_class()
	var script := node.get_script()
	var script_path := (script as Script).resource_path if script != null else null
	return {
		&"owner": owner_path,
		&"path": path,
		&"scene": original_scene,
		&"class": clazz,
		&"script": script_path,
		&"properties": copy_propierties(node, { }, [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]),
	}


static func owners_chain(node: Node, arr: Array[Dictionary] = []) -> Array[Dictionary]:
	if node.get_parent() != null:
		owners_chain(node.get_parent(), arr)
	arr.push_back(get_description(node))
	return arr

static func copy_recursive(source_node: Node, destination_node: Node, destination_scene_root: Node) -> void:
	var dst := clone_node_shallow(source_node)
	dst.name = get_node_path(source_node).get_concatenated_names().replace("/", "_")
	destination_node.add_child(dst)
	dst.owner = destination_scene_root
	if dst is Node3D:
		(dst as Node3D).global_transform = (source_node as Node3D).global_transform
	elif dst is Node2D:
		(dst as Node2D).global_transform = (source_node as Node2D).global_transform


static func copy_from_root(source_node: Node, destination_scene_root: Node) -> Node:
	if source_node.get_parent() == null:
		return destination_scene_root
	var parent := copy_from_root(source_node.get_parent(), destination_scene_root)
	var existed_copy := parent.find_child(source_node.name, false, false)
	if existed_copy:
		return existed_copy
	var dst := clone_node_shallow(source_node)
	dst.name = source_node.name
	parent.add_child(dst)
	dst.owner = destination_scene_root
	if dst is Node3D:
		(dst as Node3D).transform = (source_node as Node3D).transform
	elif dst is Node2D:
		(dst as Node2D).transform = (source_node as Node2D).transform
	return dst


static func clone_node_shallow(src: Node) -> Node:
	var dst := Node.new() if src.get_class() == "" else ClassDB.instantiate(src.get_class())

	copy_propierties(src, dst)

	return dst


static func copy_propierties(src: Node, dst = { }, type_filter: Array[Variant.Type] = []):
	# copy built-in properties only
	if not src.has_method("get"):
		return
	for p in src.get_property_list():
		if p.usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if not type_filter.is_empty() and not (p.type in type_filter):
			continue
		var name = p.name
		if name == "script":
			continue
		var value = src.get(name)
		if value == ClassDB.class_get_property_default_value(src.get_class(), name):
			continue
		if value is Resource:
			value = value.duplicate_deep()
			value.resource_local_to_scene = true
			value.resource_path = ""
		if dst is Dictionary or dst.has_method("set"):
			dst.set(name, value)
	return dst

static func disable_culling(node: VisualInstance3D):
	RenderingServer.instance_set_ignore_culling(node.get_instance(), true)
