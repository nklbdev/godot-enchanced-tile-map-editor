extends Object

const plugin_folder = "res://addons/nklbdev.enchanced_tilemap_editor/"

enum DrawingTypes {
	PASTE,
	ERASE,
	CLONE,
	FILL
}

enum SelectionTypes {
	RECT,
	LASSO,
	POLYGON,
	CONTINOUS,
	SAME
}

enum PatternFillingTypes {
	FREE,
	TILED, # need origin point
}

enum TilePatternToolTypes {
	SELECTION = 0,
	DRAWING = 1
}

enum Transformations {
	CLEAR_TRANSFORM = -1
	ROTATE_CLOCKWISE = 0,
	ROTATE_COUNTERCLOCKWISE = 1,
	FLIP_HORIZONTALLY = 2,
	FLIP_VERTICALLY = 3,
	TRANSPOSE
}

enum SelectionActions {
	CUT = 0,
	COPY = 1,
	DELETE = 2
}

enum SelectionCombineOperations {
	REPLACEMENT = 0,
	UNION = 1,
	INTERSECTION = 2,
	FORWARD_SUBTRACTION = 3,
	BACKWARD_SUBTRACTION = 4
}

enum ShapeLayouts { # FLAGS
	SIMPLE = 0,
	REGULAR = 1,
	CENTERED = 2,
}

class SelectionSettings:
	const BORDER_COLOR: Color = Color(1, 0, 0, 1)
	const FILL_COLOR: Color = Color(1, 0, 0, 0.5)
	const BORDER_WIDTH: float = 2.0

const RectangleCellEnumerator = preload("cell_enumerators/rectangle.gd")

static func create_blank_button(tooltip: String, icon: Texture, scancode_with_modifiers: int = 0):
	var tool_button = ToolButton.new()
	tool_button.focus_mode = Control.FOCUS_NONE
	tool_button.hint_tooltip = tooltip
	tool_button.icon = icon
	if scancode_with_modifiers != 0:
		var event = InputEventKey.new()
		event.pressed = true
		event.echo = false
		event.shift = scancode_with_modifiers & KEY_MASK_SHIFT
		event.alt = scancode_with_modifiers & KEY_MASK_ALT
		event.meta = scancode_with_modifiers & KEY_MASK_META
		event.control = scancode_with_modifiers & KEY_MASK_CTRL
		event.command = scancode_with_modifiers & KEY_MASK_CMD
		event.scancode = scancode_with_modifiers & KEY_CODE_MASK
		var short_cut = ShortCut.new()
		short_cut.shortcut = event
		tool_button.shortcut = short_cut
		tool_button.shortcut_in_tooltip = true
	return tool_button

# Find nodes

static func find_node_by_class(root: Node, classname: String) -> Node:
	if root.is_class(classname):
		return root
	for child in root.get_children():
		var node = find_node_by_class(child, classname)
		if node:
			return node
	return null

static func find_nodes_by_class(root: Node, classname: String) -> Node:
	var results = []
	if root.is_class(classname):
		results.append(root)
	for child in root.get_children():
		results.append_array(find_nodes_by_class(child, classname))
	return results

static func get_child_by_class(root: Node, classname: String) -> Node:
	for child in root.get_children():
		if child.is_class(classname):
			return child
	return null

static func find_children_by_class(root: Node, classname: String) -> Node:
	var results = []
	for child in root.get_children():
		if child.is_class(classname):
			results.append(child)
	return results

# nodes inspection

static func to_string_pretty(node: Node) -> String:
	return "%s: %s%s" % [node.name, node.get_class(), (", " + node.text if "text" in node else "")]

static func print_node_path_pretty(node: Node) -> void:
	var results = []
	while node != null:
		results.append(to_string_pretty(node))
		node = node.get_parent()
	results.invert()
	for result in results:
		print(result)

static func print_node_tree_pretty(node: Node, indent = "") -> void:
	print(indent + to_string_pretty(node))
	var children_indent = indent + "    "
	for child in node.get_children():
		print_node_tree_pretty(child, children_indent)

# Other

static func get_first_key_with_value(dict: Dictionary, value, default):
	for key in dict.keys():
		if dict.get(key) == value:
			return key
	return default

static func resize_button_texture(texture: Texture, scale: float) -> Texture:
	var image = texture.get_data() as Image
	var new_size = image.get_size() * scale
	image.resize(round(new_size.x), round(new_size.y))
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)
	return new_texture

static func lerp_fade(total: int, fade: int, position: float) -> float:
	if position < fade: return inverse_lerp(0, fade, position)
	if position > (total - fade): return inverse_lerp(total, total - fade, position)
	return 1.0

static func rect_world_to_map(rect: Rect2, tile_map: TileMap) -> Rect2:
	var result = Rect2()
	result.position = tile_map.world_to_map(rect.position)
	result.end = tile_map.world_to_map(rect.end)
	return result

static func rect_map_to_world(rect: Rect2, tile_map: TileMap) -> Rect2:
	var result = Rect2()
	result.position = tile_map.map_to_world(rect.position)
	result.end = tile_map.map_to_world(rect.end)
	return result

const PRINT_LOG: bool = false
static func print_log(arg) -> void:
	if PRINT_LOG:
		print(arg)
	
