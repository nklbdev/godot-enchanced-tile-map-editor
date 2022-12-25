extends Object

#var __tree_root: Node
#var __signal_subscriber: Object
#func _init(tree_root: Node, signal_subscriber: Object = null) -> void:
#	__tree_root = tree_root
#	__signal_subscriber = signal_subscriber if signal_subscriber else __tree_root
#func build(props: Dictionary = {}, children: Array = [], connections: Array = []) -> void:
#	n(__tree_root, "", props, children, connections)
#func n(node: Node, store_in_root_property: String, props: Dictionary = {}, children: Array = [], connections: Array = []) -> Node:
#	for key in props.keys():
#		node.set(key, props[key])
#	for child in children:
#		node.add_child(child)
#	for connection in connections:
#		node.connect(connection.signal_name, __signal_subscriber, connection.method_name, connection.binds)
#	if store_in_root_property:
#		__tree_root.set(store_in_root_property, node)
#	return node

#func build(props: Dictionary = {}, children: Array = [], connections: Array = []) -> void:
#	node(__tree_root).with_props(props).with_overrides()
#	n(__tree_root, "", props, children, connections)
#func n(node: Node, store_in_root_property: String, props: Dictionary = {}, children: Array = [], connections: Array = []) -> Node:
#	for key in props.keys():
#		node.set(key, props[key])
#	for child in children:
#		node.add_child(child)
#	for connection in connections:
#		node.connect(connection.signal_name, __signal_subscriber, connection.method_name, connection.binds)
#	if store_in_root_property:
#		__tree_root.set(store_in_root_property, node)
#	return node





#func node(node: Node, root_property_name: String = "") -> NodeBuilder:
#	return NodeBuilder.new(__tree_root, node, root_property_name)

class NodeBuilder:
	var _root: Node
	var __signal_subscriber: Object
	var __node: Node
	var __root_property_name: String
	var __props: Dictionary
	var __children_builders: Array # of NodeBuilder
	var __constant_overrides: Dictionary
	var __connections: Array

	func _init(root: Node, node: Node, root_property_name: String = "", signal_subscriber: Object = null) -> void:
		_root = root
		__node = node
		__root_property_name = root_property_name
		__signal_subscriber = signal_subscriber if signal_subscriber else root

	func with_props(props: Dictionary) -> NodeBuilder:
		__props.merge(props, true)
		return self

	func with_children(children: Array) -> NodeBuilder:
		__children_builders.append_array(children)
		return self

	func connected(signal_name: String, method_name: String, binds: Array = []) -> NodeBuilder:
		__connections.append({ signal_name = signal_name, method_name = method_name, binds = binds })
		return self

	func with_overrides(overrides: Dictionary) -> NodeBuilder:
		__constant_overrides.merge(overrides, true)
		return self

	func build() -> Node:
		if __root_property_name:
			_root.set(__root_property_name, __node)
		for prop_name in __props.keys():
			__node.set(prop_name, __props[prop_name])
		for child_builder in __children_builders:
			__node.add_child(child_builder.build())
		for constant_name in __constant_overrides.keys():
			__node.add_constant_override(constant_name, __constant_overrides[constant_name])
		for connection in __connections:
			__node.connect(connection.signal_name, __signal_subscriber, connection.method_name, connection.binds)
		return __node

class NodeBuilderRoot:
	extends NodeBuilder
	func _init(root: Node, node: Node, root_property_name: String = "", signal_subscriber: Object = null) \
		.(root, node, root_property_name, signal_subscriber) -> void:
		pass
	func node(node: Node, root_property_name: String = "") -> NodeBuilder:
		return NodeBuilder.new(_root, node, root_property_name)

static func tree(tree_root: Node, signal_subscriber: Object = null) -> NodeBuilderRoot:
	return NodeBuilderRoot.new(tree_root, tree_root, "", signal_subscriber)
