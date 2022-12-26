extends Object

const Iterators = preload("iterators.gd")

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
	SUBTRACTION = 3,
	BACKWARD_SUBTRACTION = 4
}

enum InstrumentMode { # FLAGS
	NONE = 0,
	MODE_A = 1,
	MODE_B = 2,
	MODE_C = 4,
}

enum PatternType {
	FOREGROUND = 1
	BACKGROUND = 2
}

const HALF_OFFSETS: PoolVector2Array = PoolVector2Array([
	#TileMap.HALF_OFFSET_X = 0
	Vector2( 0,   0), Vector2( 0,    0  ),
	Vector2( 0.5, 0), Vector2( 0.5,  0  ),
	#TileMap.HALF_OFFSET_Y = 1
	Vector2( 0,   0), Vector2( 0,    0.5),
	Vector2( 0,   0), Vector2( 0,    0.5),
	#TileMap.HALF_OFFSET_DISABLED = 2
	Vector2( 0,   0), Vector2( 0,    0  ),
	Vector2( 0,   0), Vector2( 0,    0  ),
	#TileMap.HALF_OFFSET_NEGATIVE_X = 3
	Vector2( 0,   0), Vector2( 0,    0  ),
	Vector2(-0.5, 0), Vector2(-0.5,  0  ),
	#TileMap.HALF_OFFSET_NEGATIVE_Y = 4
	Vector2( 0,   0), Vector2( 0,   -0.5),
	Vector2( 0,   0), Vector2( 0,   -0.5),
])

static func get_half_offset(map_cell: Vector2, half_offset_type: int) -> Vector2:
	return HALF_OFFSETS[half_offset_type * 4 + posmod(map_cell.x, 2) + posmod(map_cell.y, 2) * 2]

class DrawingSettings:
	var display_grid_enabled: bool
	var cursor_color: Color
	var drawn_cells_color: Color
	var grid_color: Color
	var axis_color: Color
	var axis_fragment_radius: int
	var grid_fragment_radius: int setget __set_grid_fragment_radius
	var grid_fragment_radius_squared: int
	func __set_grid_fragment_radius(value: int) -> void:
		grid_fragment_radius = value
		grid_fragment_radius_squared = value * value

class ValueHolder:
	var value setget __set_value
	func __set_value(v) -> void:
		if v == value:
			return
		value = v
		emit_signal("value_changed")
	signal value_changed

class Pattern:
	var size: Vector2
	var offset: Vector2 setget __set_offset
	func __set_offset(value: Vector2) -> void:
		offset = value.posmodv(size)
	var transform_flags: int
	var data: Array # tile_id, transform_flags, subtile_coord.x, subtile_coord_y

	func _init(size: Vector2, data: PoolIntArray) -> void:
		assert(size.x > 0 and size.y > 0)
		assert(data.size() == size.x * size.y * 4)
		self.size = size
		self.data = data

	var __temp_map_cell_data: PoolIntArray = PoolIntArray([0, 0, 0, 0])
	func get_map_cell_data(map_cell: Vector2) -> PoolIntArray:
		var internal_map_cell = (map_cell - offset).posmodv(size)
		var data_address = (internal_map_cell.x + internal_map_cell.y * size.x) * 4
		return PoolIntArray(data.slice(data_address, data_address + 4))
#		var data_address = (internal_map_cell.x + internal_map_cell.y * size.x) * 4
#		for data_offset in 4:
#			__temp_map_cell_data[data_offset] = data[data_address + data_offset]
#		return __temp_map_cell_data

# working with tilemaps

static func copy_cell(
	source: TileMap, source_cell: Vector2,
	destination: TileMap, destination_cell: Vector2,
	force: bool = false) -> void:
	var tile_set = source.tile_set
	var x = source_cell.x
	var y = source_cell.y
	assert(tile_set == destination.tile_set, "Unable to copy cell: tile maps have different tile sets!")
	var tile_id = source.get_cellv(source_cell)
	if tile_id == TileMap.INVALID_CELL and not force:
		return
	destination.set_cellv(
		destination_cell,
		tile_id,
		source.is_cell_x_flipped(x, y),
		source.is_cell_y_flipped(x, y),
		source.is_cell_transposed(x, y),
		source.get_cell_autotile_coord(x, y))

static func copy_region(source: TileMap, region: Rect2, destination: TileMap, destination_position: Vector2, mask: TileMap = null, mask_offset: Vector2 = Vector2.ZERO, force: bool = false) -> void:
	var step_x = sign(region.size.x)
	for offset_y in range(0, region.size.y, sign(region.size.y)):
		for offset_x in range(0, region.size.x, step_x):
			var offset = Vector2(offset_x, offset_y)
			if mask == null or mask.get_cellv(destination_position + offset - mask_offset) == 0:
				copy_cell(source, region.position + offset, destination, destination_position + offset, force)

static func paste(source: TileMap, destination: TileMap, destination_position: Vector2, mask: TileMap = null, mask_offset: Vector2 = Vector2.ZERO) -> void:
	for cell in source.get_used_cells():
		if mask == null or mask.get_cellv(destination_position + cell - mask_offset) == 0:
			copy_cell(source, cell, destination, destination_position + cell)

static func copy_region_optimized(source: TileMap, region: Rect2, destination: TileMap, destination_position: Vector2, force: bool = false) -> void:
	# dangerous: checking equality instead of difference!
	var step_x = sign(region.size.x)
	var step_y = sign(region.size.y)
	var source_position = region.position
	while source_position.y != region.end.y:
		while source_position.x != region.end.x:
			copy_cell(source, source_position, destination, destination_position)
			source_position.x += step_x
			destination_position.x += step_x
		source_position.y += step_y
		destination_position.y += step_y

# Find nodes

static func find_node_by_class(root: Node, classname: String) -> Node:
	if root.is_class(classname):
		return root
	for child in root.get_children():
		var node = find_node_by_class(child, classname)
		if node:
			return node
	return null

static func find_node_by_predicate(root: Node, predicate: Iterators.Predicate) -> Node:
	if predicate.fit(root):
		return root
	for child in root.get_children():
		var node = find_node_by_predicate(child, predicate)
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
	if node:
		return "%s: %s%s" % [node.name, node.get_class(), (", " + node.text if "text" in node else "")]
	else:
		return "Null"

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

static func resize_texture(texture: Texture, scale: float) -> Texture:
	
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

# line drawing

static func line(start: Vector2, finish: Vector2) -> Array:
	var points = [start]
	var path = (finish - start).abs()
	var steps = max(path.x, path.y)
	for step in range(steps):
		points.append(start.linear_interpolate(finish, (step + 1.0) / steps).round())
	return points

# Line code based on Alois Zingl work released under the
# MIT license http://members.chello.at/easyfilter/bresenham.html
static func algo_line_continuous(start: Vector2, finish: Vector2) -> Array:
	var path = finish - start
	var abs_path = path.abs()
	var dx = abs_path.x
	var dy = -abs_path.y
	var sx: int = 1 if path.x > 0 else -1
	var sy: int = 1 if path.y > 0 else -1
	var err: int = dx + dy
	var e2: int              # error value e_xy
	var points = []

	while true:
		points.append(start)
		e2 = 2 * err
		if e2 >= dy:         # e_xy + e_x > 0
			if start.x == finish.x:
				break
			err += dy
			start.x += sx
		if e2 <= dx:         # e_xy + e_y < 0
			if start.y == finish.y:
				break
			err += dx
			start.y += sy
	return points

# polygon filling

class HorizontalLineConsumer:
	func push_line(y: int, x_from: int, x_to: int) -> void:
		pass

class CellFiller:
	extends Iterators.Action
	var position: Vector2
	func perform() -> void:
		pass
