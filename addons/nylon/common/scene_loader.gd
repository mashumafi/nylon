extends Reference

var scene
var loader_node : Node

func _init(p_scene, p_loader_node: Node):
    scene = p_scene
    loader_node = p_loader_node

func call_func():
    if scene is String:
        scene = ResourceLoader.load_interactive(scene)

    if scene is ResourceInteractiveLoader:
        var result := OK
        while result == OK:
            yield()
            result = scene.poll()
        scene = scene.get_resource()
        yield()

    if scene is PackedScene:
        scene = scene.instance()
        yield()

    if scene is Node:
        var node = scene
        scene = []
        orphan_prefabs(node, scene)

    if scene is Array:
        for orphan in scene:
            yield()
            orphan.remove_from_parent()
        for orphan in scene:
            yield()
            loader_node.add_child(orphan.node)
            loader_node.remove_child(orphan.node)
            orphan.add_to_parent()
        return scene[scene.size()-1].node

func orphan_prefabs(node: Node, orphans: Array):
    for child in node.get_children():
        orphan_prefabs(child, orphans)

    if node.filename:
        var orphan := Orphan.new(node.get_parent(), node.get_position_in_parent(), node)
        orphans.append(orphan)

class Orphan:
    var parent : Node
    var index : int
    var node : Node

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
