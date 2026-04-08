extends RefCounted


static func get_feedback(node: Node) -> Node:
	if node == null or node.get_tree() == null:
		return null
	return node.get_tree().get_first_node_in_group("feedback")
