extends Object

const Iterators = preload("iterators.gd")
const Serialization = preload("serialization.gd")

const PLUGIN_FOLDER = "res://addons/nklbdev.enchanced_tilemap_editor/"

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

const EMPTY_CELL_DATA: PoolIntArray = PoolIntArray([TileMap.INVALID_CELL, 0, 0, 0])
const FORCE_EMPTY_CELL_DATA: PoolIntArray = PoolIntArray([TileMap.INVALID_CELL - 1, 0, 0, 0])

static func limit_area(size: Vector2, area_limit: float) -> Vector2:
	var area: float = abs(size.x * size.y)
	if area <= area_limit:
		return size
	var abs_aspect = abs(size.aspect())
	return Vector2(sqrt(area_limit * abs_aspect) * sign(size.x), sqrt(area_limit / abs_aspect) * sign(size.y))


const MODIFIER_KEYS: PoolIntArray = PoolIntArray([KEY_CONTROL, KEY_ALT, KEY_SHIFT, KEY_META])
const ALL_MODIFIER_KEYS: int = KEY_CONTROL | KEY_ALT | KEY_SHIFT | KEY_META
static func get_current_modifiers() -> int:
	var modifiers: int
	for key in MODIFIER_KEYS:
		if Input.is_key_pressed(key):
			modifiers |= key
	return modifiers

const CELL_HALF_OFFSETS: PoolVector2Array = PoolVector2Array([
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

const CELL_HALF_OFFSET_SIGNS: PoolIntArray = PoolIntArray([1, 1, 0, -1, -1])
const CELL_HALF_OFFSET_AXES: PoolVector2Array = PoolVector2Array([Vector2.RIGHT, Vector2.DOWN, Vector2.RIGHT, Vector2.RIGHT, Vector2.DOWN])

static func get_cell_half_offset(map_cell: Vector2, cell_half_offset_type: int) -> Vector2:
	return CELL_HALF_OFFSETS[cell_half_offset_type * 4 + posmod(map_cell.x, 2) + posmod(map_cell.y, 2) * 2]

class ValueHolder:
	var value setget __set_value
	func __set_value(val) -> void:
		if val != value:
			value = val
			emit_signal("value_changed")
	signal value_changed()
	func _init(val = null) -> void:
		value = val

class Settings:
	const __plugin_settings_section = "enchanced_tile_map_editor/"

	var __disposed: bool

	var display_grid_enabled: bool
	var cursor_color: Color
	var selection_color: Color
	var drawn_cells_color: Color
	var grid_color: Color
	var pattern_grid_color: Color
	var axis_color: Color
	var axis_fragment_radius: int
	var grid_fragment_radius: int
	var pattern_grid_fragment_radius: int
	var drawing_area_limit: int
	var palette_zoom_step_factor: float
	
	signal settings_changed
	
	var __editor_settings: EditorSettings
	var __editor_settings_registry: Array
	var __project_settings_registry: Array
	
	func _init(editor_settings: EditorSettings) -> void:
		__editor_settings = editor_settings
		__register_editor_setting("display_grid_enabled", "editors/tile_map/display_grid")
		__register_editor_setting("grid_color", "editors/tile_map/grid_color")
		__register_editor_setting("axis_color", "editors/tile_map/axis_color")
		__register_project_setting("cursor_color", "cursor_color", TYPE_COLOR, Color(1, 0.5, 0.25, 0.5))
		__register_project_setting("selection_color", "selection_color", TYPE_COLOR, Color(0.2, 0.8, 1, 0.4))
		__register_project_setting("drawn_cells_color", "drawn_cells_color", TYPE_COLOR, Color(1, 0.5, 0.25, 0.25))
		__register_project_setting("pattern_grid_color", "pattern_grid_color", TYPE_COLOR, Color(1, 0.5, 0.25, 0.25))
		__register_project_setting("grid_fragment_radius", "grid_fragment_radius", TYPE_INT, 10)
		__register_project_setting("pattern_grid_fragment_radius", "pattern_grid_fragment_radius", TYPE_INT, 10)
		__register_project_setting("axis_fragment_radius", "axis_fragment_radius", TYPE_INT, 20)
		__register_project_setting("drawing_area_limit", "drawing_area_limit", TYPE_INT, 128 * 128)
		__register_project_setting("palette_zoom_step_factor", "palette_zoom_step_factor", TYPE_REAL, 1.25)
		ProjectSettings.connect("project_settings_changed", self, "__rescan_project_settings")
		editor_settings.connect("settings_changed", self, "__rescan_editor_settings")
		__scan_editor_settings()
		__scan_project_settings()
	func dispose() -> void:
		assert(not __disposed)
		ProjectSettings.disconnect("project_settings_changed", self, "__rescan_project_settings")
		__editor_settings.disconnect("settings_changed", self, "__rescan_editor_settings")
		__editor_settings = null
		__disposed = true
	
	func __register_editor_setting(property_name: String, setting_path: String) -> void:
		__editor_settings_registry.append({ property_name = property_name, setting_path = setting_path })
	
	func __register_project_setting(property_name: String, setting_path_in_plugin_section: String, setting_type: int, default_value) -> void:
		__project_settings_registry.append({ property_name = property_name, setting_path_in_plugin_section = setting_path_in_plugin_section, setting_type = setting_type, default_value = default_value })

	func __rescan_project_settings() -> void:
		if __scan_project_settings():
			emit_signal("settings_changed")
	func __scan_project_settings() -> bool:
		var settings_changed: bool
		var need_save_project_settings: bool
		for setting in __project_settings_registry:
			var setting_path = __plugin_settings_section + setting.setting_path_in_plugin_section
			if ProjectSettings.has_setting(setting_path):
				var value = ProjectSettings.get_setting(setting_path)
				if value != get(setting.property_name):
					settings_changed = true
					set(setting.property_name, value)
			else:
				ProjectSettings.set_setting(setting_path, setting.default_value)
				ProjectSettings.add_property_info({
					"name": setting_path,
					"type": setting.setting_type,
					# "hint": PROPERTY_HINT_COL,
					# "hint_string": "Color of cursor"
					})
				ProjectSettings.set_initial_value(setting_path, setting.default_value)
				need_save_project_settings = true
		if need_save_project_settings:
			var err = ProjectSettings.save()
			if err: push_error("Can't save project settings")
		return settings_changed
	
	func __rescan_editor_settings() -> void:
		if __scan_editor_settings():
			emit_signal("settings_changed")
	func __scan_editor_settings() -> bool:
		var settings_changed: bool
		for setting in __editor_settings_registry:
			var value = __editor_settings.get_setting(setting.setting_path)
			if value != get(setting.property_name):
				settings_changed = true
				set(setting.property_name, value)
		return settings_changed

static func draw_axis_fragment(cell: Vector2, overlay: Control, cell_half_offset_type: int, settings: Settings):
	var axis_color: Color = settings.axis_color
	var cell_position: Vector2
	for i in settings.axis_fragment_radius + 1:
		axis_color.a = settings.axis_color.a * (1 - float(i) / settings.axis_fragment_radius)
		var direction = Vector2.RIGHT
		for r in 4:
			cell_position = cell + direction * i
			cell_position += get_cell_half_offset(cell_position, cell_half_offset_type)
			overlay.draw_line(cell_position, cell_position + direction, axis_color)
			direction = direction.tangent()

static func create_shortcut(scancode_with_modifiers: int) -> ShortCut:
	var event = InputEventKey.new()
	event.pressed  = true
	event.echo     = false
	event.unicode  = scancode_with_modifiers & KEY_CODE_MASK
	event.scancode = scancode_with_modifiers & KEY_CODE_MASK
	event.shift    = scancode_with_modifiers & KEY_MASK_SHIFT
	event.alt      = scancode_with_modifiers & KEY_MASK_ALT
	event.control  = scancode_with_modifiers & KEY_MASK_CTRL
	event.meta     = scancode_with_modifiers & KEY_MASK_META
	event.command  = scancode_with_modifiers & KEY_MASK_CMD
	var shortcut = ShortCut.new()
	shortcut.shortcut = event
	return shortcut

# working with tilemaps

const __right_twice = Vector2.RIGHT * 2
const __down_twice = Vector2.DOWN * 2
static func get_cell_base_transform(tile_map: TileMap) -> Transform2D:
	# hack to skip half-offsetted row or column
	var zero: Vector2 = tile_map.map_to_world(Vector2.ZERO)
	return Transform2D(
		(tile_map.map_to_world(__right_twice) - zero) / 2,
		(tile_map.map_to_world(__down_twice)  - zero) / 2,
		zero)

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

const CELL_HALF_OFFSET_TYPES: Array = [null, null, null, null, null]

const __STATICS: Array = []
enum Statics {
	EDITOR_INTERFACE = 0
	EDITOR_SETTINGS = 1
	EDITOR_SCALE = 2,
	SETTINGS = 3,
	MAX = 4
}
const TILE_COLORS = PoolColorArray([
	Color(1, 1, 0.3),     # SINGLE_TILE = 0
	Color(0.3, 0.6, 1),   # AUTO_TILE   = 1
	Color(0.8, 0.8, 0.8), # ATLAS_TILE  = 2
])
const SUBTILE_COLOR = Color(0.3, 0.7, 0.6)
const SHADOW_COLOR = SUBTILE_COLOR * Color(1, 1, 1, 0.4)
const SELECTED_RECT_COLOR = Color.white
const SELECTION_RECT_COLOR = Color.lightskyblue


static func set_up_statics(editor_interface: EditorInterface) -> void:
	if (__STATICS.size() > 0):
		return
	var editor_settings = editor_interface.get_editor_settings()
	__STATICS.resize(Statics.MAX)
	__STATICS[Statics.EDITOR_INTERFACE] = editor_interface
	__STATICS[Statics.EDITOR_SETTINGS] = editor_settings
	__STATICS[Statics.EDITOR_SCALE] = editor_interface.get_editor_scale()
	__STATICS[Statics.SETTINGS] = Settings.new(editor_settings)
	for i in 5:
		CELL_HALF_OFFSET_TYPES[i] = CellHalfOffsetType.new(i)
	CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_X].opposite = CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_NEGATIVE_X]
	CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_NEGATIVE_X].opposite = CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_X]
	CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_Y].opposite = CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_NEGATIVE_Y]
	CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_NEGATIVE_Y].opposite = CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_Y]
	CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_DISABLED].opposite = CELL_HALF_OFFSET_TYPES[TileMap.HALF_OFFSET_DISABLED]

static func tear_down_statics() -> void:
	assert(__STATICS.size() != 0)
	__STATICS[Statics.SETTINGS].dispose()
	__STATICS.clear()

static func get_static(index: int):
	return __STATICS[index]

static func get_icon_file_path(icon_name: String) -> String:
	return "%sicons/%s.svg" % [PLUGIN_FOLDER, icon_name]

static func get_icon(icon_name: String) -> Texture:
	return resize_texture(load(get_icon_file_path(icon_name)), __STATICS[Statics.EDITOR_SCALE] / 4)

static func has_icon(icon_name: String) -> bool:
	var path = get_icon_file_path(icon_name)
	var res = ResourceLoader.exists(get_icon_file_path(icon_name))
	return res

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

enum HalfOffsetOrientation {
	NOT_OFFSETTED = 0,
	HORIZONTAL_OFFSETTED = 1,
	VERTICAL_OFFSETTED = 2,
}

enum HalfOffsetOrientationFlags {
	NOT_OFFSETTED = 1,
	HORIZONTAL_OFFSETTED = 2,
	VERTICAL_OFFSETTED = 4,
}

enum HalfOffsetCompatibilityFlags {
	NOT_OFFSETTED = 1,
	HORIZONTAL_OFFSETTED = 2,
	VERTICAL_OFFSETTED = 4,
	OFFSETTED = 6,
	ALL = 7
}

class CellHalfOffsetType:
	var index: int
	var transposed: bool
	var orientation: int
	var offset_sign: int
	var line_direction: Vector2
	var column_direction: Vector2
	var offset: Vector2
	var opposite: CellHalfOffsetType
	var cell_regular_scale: Vector2
	var offset_orientation: int
	var offset_orientation_flag: int
	func _init(index_: int) -> void:
		index = index_
		transposed = index in [TileMap.HALF_OFFSET_Y, TileMap.HALF_OFFSET_NEGATIVE_Y]
		orientation = VERTICAL if transposed else HORIZONTAL
		offset_sign = 1 if index < 2 else (-1 if index > 2 else 0)
		line_direction = conv(Vector2.RIGHT)
		column_direction = conv(Vector2.DOWN)
		offset = line_direction * 0.5 * offset_sign
		cell_regular_scale = line_direction + column_direction * (1 if index == TileMap.HALF_OFFSET_DISABLED else (sqrt(3) / 2))
		offset_orientation = HalfOffsetOrientation.NOT_OFFSETTED if index == TileMap.HALF_OFFSET_DISABLED else \
			(HalfOffsetOrientation.VERTICAL_OFFSETTED if transposed else HalfOffsetOrientation.HORIZONTAL_OFFSETTED)
		offset_orientation_flag = pow(2, offset_orientation)
	func get_line(cell: Vector2) -> int:
		return int(cell.x if transposed else cell.y)
	func get_column(cell: Vector2) -> int:
		return int(cell.y if transposed else cell.x)
	func conv(v: Vector2) -> Vector2:
		return Vector2(v.y, v.x) if transposed else v
	func _to_string() -> String:
		return "%s{index: %s, transposed: %s, offset_sign: %s, line_direction: %s, column_direction: %s, offset: %s}" % \
			[get_class(), index, transposed, offset_sign, line_direction, column_direction, offset]

const CELL_X_FLIPPED: int = 1
const CELL_Y_FLIPPED: int = 2
const CELL_TRANSPOSED: int = 4
const CELL_CW1_ROTATED: int = CELL_TRANSPOSED | CELL_X_FLIPPED
const CELL_CW2_ROTATED: int = CELL_X_FLIPPED | CELL_Y_FLIPPED
const CELL_CW3_ROTATED: int = CELL_TRANSPOSED | CELL_Y_FLIPPED

const ROTATE_CCW: Transform2D = Transform2D(Vector2.UP, Vector2.RIGHT, Vector2.ZERO)
const ROTATE_CW: Transform2D = Transform2D(Vector2.DOWN, Vector2.LEFT, Vector2.ZERO)
const TRANSPOSE: Transform2D = Transform2D(Vector2.DOWN, Vector2.RIGHT, Vector2.ZERO)

const normal_rotation_matrix: PoolIntArray = PoolIntArray([
	0,
	CELL_X_FLIPPED | CELL_TRANSPOSED,
	CELL_X_FLIPPED | CELL_Y_FLIPPED,
	CELL_Y_FLIPPED | CELL_TRANSPOSED,
])
const mirrored_rotation_matrix: PoolIntArray = PoolIntArray([
	CELL_X_FLIPPED,
	CELL_X_FLIPPED | CELL_Y_FLIPPED | CELL_TRANSPOSED,
	CELL_Y_FLIPPED,
	CELL_TRANSPOSED,
])

static func is_flag_count_odd(flags: int) -> bool:
	return bool((((flags * 0x01_0101_0101_0101) & 0x40_2010_0804_0201) % 0x1FF) & 1)

static func rotate_cell_transform(cell_transform: int, steps: int) -> int:
	if is_flag_count_odd(cell_transform):
		# Odd number of flags activated = mirrored rotation
		for i in 4:
			if cell_transform == mirrored_rotation_matrix[i]:
				return mirrored_rotation_matrix[wrapi(i + steps, 0, 4)]
	else:
		# Even number of flags activated = normal rotation
		for i in 4:
			if cell_transform == normal_rotation_matrix[i]:
				return normal_rotation_matrix[wrapi(i + steps, 0, 4)]
	return 0 # never


const __cell_data_to_return: PoolIntArray = PoolIntArray([0, 0, 0, 0])
static func get_map_cell_data(tile_map: TileMap, map_cell: Vector2) -> PoolIntArray:
	# 0 - tile_id
	# 1 - transform
	# 2 - autotile_coord.x
	# 3 - autotile_coord.y
	var tile_id: int = tile_map.get_cellv(map_cell)
	if tile_id == TileMap.INVALID_CELL:
		__cell_data_to_return.fill(0)
	else:
		var x: int = int(map_cell.x)
		var y: int = int(map_cell.y)
		__cell_data_to_return[1] = \
			int(tile_map.is_cell_x_flipped(x, y)) * CELL_X_FLIPPED | \
			int(tile_map.is_cell_y_flipped(x, y)) * CELL_Y_FLIPPED | \
			int(tile_map.is_cell_transposed(x, y)) * CELL_TRANSPOSED
		var autotile_coord: Vector2 = tile_map.get_cell_autotile_coord(x, y)
		__cell_data_to_return[2] = autotile_coord.x
		__cell_data_to_return[3] = autotile_coord.y
	__cell_data_to_return[0] = tile_id
	return __cell_data_to_return

static func set_map_cell_data(tile_map: TileMap, map_cell: Vector2, data: PoolIntArray) -> void:
	# 0 - tile_id
	# 1 - transform
	# 2 - autotile_coord.x
	# 3 - autotile_coord.y
	if data.empty():
		return
	elif data[0] == TileMap.INVALID_CELL:
		tile_map.set_cellv(map_cell, TileMap.INVALID_CELL)
	else:
		tile_map.set_cellv(map_cell, data[0],
			data[1] & CELL_X_FLIPPED,
			data[1] & CELL_Y_FLIPPED,
			data[1] & CELL_TRANSPOSED,
			Vector2(data[2], data[3]))

static func map_to_cube(cell: Vector2, cell_half_offset: int) -> Vector3:
	var dir: int = cell_half_offset % 3 # 0 -> X, 1 -> Y
	cell[dir] -= (cell[dir ^ 1] + sign(cell_half_offset - 2) * (int(cell[dir ^ 1]) & 1)) / 2
	return Vector3(cell.x, cell.y, -cell.x-cell.y)

static func cube_to_map(hex: Vector3, cell_half_offset: int) -> Vector2:
	var dir: int = cell_half_offset % 3 # 0 -> X, 1 -> Y
	hex[dir] += (hex[dir ^ 1] + sign(cell_half_offset - 2) * (int(hex[dir ^ 1]) & 1)) / 2
	return Vector2(hex.x, hex.y)
