# AsyncResourceLoader
# Loads resources asynchronously using coroutines

class_name AsyncResourceLoader
extends Reference

var resource
var loader_node: Node


# AsyncResourceLoader.new(resource: String|ResourceInteractiveLoader|PackedScene|Node, loader_node: Node)
# Loads a resource with special logic for smooth scene loading.
# resource (String|ResourceInteractiveLoader|PackedScene|Node): Resource to load
# loader_node (Node): Node used to load the scene. This will allow nodes to be added one-by-one
func _init(resource, loader_node: Node = null):
	self.resource = resource
	self.loader_node = loader_node


# call_func()
# Loads a resource using yields at different stages so user can control the flow
# Resource can be in any stage such as String for file path, PackedScenes, Node
# There is logic to add nodes 1 at a time for smooth scenes loading
func call_func():
	if resource is String:
		resource = ResourceLoader.load_interactive(resource)

	if resource is ResourceInteractiveLoader:
		var result := OK
		while result == OK:
			yield()
			result = resource.poll()
		resource = resource.get_resource()
		yield()

	if resource is PackedScene:
		resource = resource.instance()
		yield()

	if not loader_node:
		return resource

	if resource is Node:
		var node = resource
		resource = []
		orphan_prefabs(node, resource)

	if resource is Array and loader_node:
		for orphan in resource:
			yield()
			orphan.remove_from_parent()
		for orphan in resource:
			yield()
			loader_node.add_child(orphan.node)
			loader_node.remove_child(orphan.node)
			orphan.add_to_parent()
		return resource[resource.size() - 1].node


func orphan_prefabs(node: Node, orphans: Array):
	for child in node.get_children():
		orphan_prefabs(child, orphans)

	if node.filename:
		var orphan := Orphan.new(node.get_parent(), node.get_position_in_parent(), node)
		orphans.append(orphan)


class Orphan:
	var parent: Node
	var index: int
	var node: Node

	func _init(p_parent: Node, p_index: int, p_node: Node) -> void:
		parent = p_parent
		index = p_index
		node = p_node

	func remove_from_parent():
		if parent:
			parent.remove_child(node)

	func add_to_parent():
		if parent:
			parent.add_child(node)
			parent.move_child(node, index)

	func _to_string() -> String:
		return "{0}[{1}]={2}".format([parent, index, node])
