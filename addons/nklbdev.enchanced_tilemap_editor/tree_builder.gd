extends Object

class __Builder:
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

	func with_props(props: Dictionary) -> __Builder:
		__props.merge(props, true)
		return self

	func with_children(children: Array) -> __Builder:
		__children_builders.append_array(children)
		return self

	func connected(signal_name: String, method_name: String, binds: Array = []) -> __Builder:
		__connections.append({ signal_name = signal_name, method_name = method_name, binds = binds })
		return self

	func with_overrides(overrides: Dictionary) -> __Builder:
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

class __BuilderRoot:
	extends __Builder
	func _init(root: Node, node: Node, root_property_name: String = "", signal_subscriber: Object = null) \
		.(root, node, root_property_name, signal_subscriber) -> void:
		pass
	func node(node: Node, root_property_name: String = "") -> __Builder:
		return __Builder.new(_root, node, root_property_name)

static func tree(tree_root: Node, signal_subscriber: Object = null) -> __BuilderRoot:
	return __BuilderRoot.new(tree_root, tree_root, "", signal_subscriber)
