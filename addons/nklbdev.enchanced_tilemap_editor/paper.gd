extends Object
# TODO оптимизировать работу с "бумагой", чтобы при работе с инструментом
# не перерисовывать все заново на каждом движении

const Iterators = preload("iterators.gd")

const CELL_X_FLIPPED = 1
const CELL_Y_FLIPPED = 2
const CELL_TRANSPOSED = 4

const QUAD = PoolVector2Array([
	Vector2.LEFT + Vector2.UP,   Vector2.UP,   Vector2.RIGHT + Vector2.UP,
	Vector2.LEFT,                Vector2.ZERO, Vector2.RIGHT,
	Vector2.LEFT + Vector2.DOWN, Vector2.DOWN, Vector2.RIGHT + Vector2.DOWN
])

const EMPTY_CELL_DATA: PoolIntArray = PoolIntArray([-1])

#signal changes_committed(backup)
#signal changes_reset(backup)

var _is_input_freezed: bool
var _adjustments: Array = [ToolButton.new()]
func get_adjustments() -> Array: # of Control
	return _adjustments

var pattern_offset: Vector2
var half_offset_type: int setget , __get_half_offset_type
func __get_half_offset_type() -> int:
	return __tile_map.cell_half_offset

var __tile_map: TileMap
var __backup: Dictionary
var __previous_data_for_update_bitmask_area: Array

func has_changes() -> bool:
	return not __backup.empty()

func is_cell_changed(map_cell: Vector2) -> bool:
	return __backup.has(map_cell)

func _init() -> void:
	_adjustments[0].icon = preload("res://addons/nklbdev.enchanced_tilemap_editor/icons/paint_tool_contour.svg")
	__previous_data_for_update_bitmask_area.resize(9)

func process_input_event_key(event: InputEventKey) -> bool:
#	print("paper is indifferent")
	return false

func set_up(tile_map: TileMap) -> void:
	assert(__tile_map == null)
	__tile_map = tile_map

func tear_down() -> void:
	__backup.clear()
	__tile_map = null
	pass

func get_map_cell_data(map_cell: Vector2, original: bool = false) -> PoolIntArray:
	return __backup.get(map_cell, __get_current_map_cell_data(map_cell)) \
		if original else __get_current_map_cell_data(map_cell)

func __get_current_map_cell_data(map_cell: Vector2) -> PoolIntArray:
	# 0 - tile_id
	# 1 - transform
	# 2 - autotile_coord.x
	# 3 - autotile_coord.y
	var tile_id: int = __tile_map.get_cellv(map_cell)
	var data = PoolIntArray()
	if tile_id < 0:
		data.resize(1)
		data[0] = tile_id
		return data
	data.resize(4)
	data[0] = tile_id
	var x: int = map_cell.x
	var y: int = map_cell.y
	data[1] = 0
	if __tile_map.is_cell_x_flipped(x, y):
		data[1] |= CELL_X_FLIPPED
	if __tile_map.is_cell_y_flipped(x, y):
		data[1] |= CELL_Y_FLIPPED
	if __tile_map.is_cell_transposed(x, y):
		data[1] |= CELL_TRANSPOSED
	var autotile_coord = __tile_map.get_cell_autotile_coord(x, y)
	data[2] = autotile_coord.x
	data[3] = autotile_coord.y
	return data

func set_map_cell_data(map_cell: Vector2, data: PoolIntArray) -> void:
	if not __backup.has(map_cell):
		__backup[map_cell] = get_map_cell_data(map_cell)
	if data[0] == TileMap.INVALID_CELL:
		__tile_map.set_cellv(map_cell, data[0])
	else:
		__tile_map.set_cellv(map_cell, data[0], data[1] & CELL_X_FLIPPED, data[1] & CELL_Y_FLIPPED, data[1] & CELL_TRANSPOSED, Vector2(data[2], data[3]))

func update_bitmask_area(map_cell: Vector2) -> void:
	for i in range(9):
		__previous_data_for_update_bitmask_area[i] = get_map_cell_data(map_cell + QUAD[i])
	__tile_map.update_bitmask_area(map_cell)
	var data_map_cell: Vector2
	var previous_data: PoolIntArray
	for i in range(9):
		data_map_cell = map_cell + QUAD[i]
		previous_data = __previous_data_for_update_bitmask_area[i]
		if previous_data != get_map_cell_data(data_map_cell):
			__backup[data_map_cell] = previous_data

func update_bitmask_region(start: Vector2 = Vector2.ZERO, end: Vector2 = Vector2.ZERO) -> void:
	var affected_rect: Rect2 = \
		__tile_map.get_used_rect() \
		if not start.round() and not end.round() else \
		Rect2(start, end - start).grow(1).clip(__tile_map.get_used_rect())
	var previous_datas: Array
	previous_datas.resize(affected_rect.get_area())
	var affected_rect_map_cell_iterator = Iterators.rect(affected_rect) #: Iterators.Iterator
	var index: int = 0
	for map_cell in affected_rect_map_cell_iterator:
		previous_datas[index] = get_map_cell_data(map_cell)
		index += 1
	__tile_map.update_bitmask_region(start, end)
	index = 0
	var previous_data: PoolIntArray
	for map_cell in affected_rect_map_cell_iterator:
		previous_data = previous_datas[index]
		if previous_data != get_map_cell_data(map_cell):
			__backup[map_cell] = previous_data
		index += 1

func commit_changes() -> void:
	# Create undoredo
#	emit_signal("changes_committed", __backup)
	__backup.clear()

func reset_map_cell(map_cell: Vector2) -> void:
	if map_cell in __backup:
		var data = __backup[map_cell]
		if data[0] == TileMap.INVALID_CELL:
			__tile_map.set_cellv(map_cell, data[0])
		else:
			__tile_map.set_cellv(map_cell, data[0], data[1] & CELL_X_FLIPPED, data[1] & CELL_Y_FLIPPED, data[1] & CELL_TRANSPOSED, Vector2(data[2], data[3]))
		__backup.erase(map_cell)

func reset_changes() -> void:
	for map_cell in __backup:
		# code duplication from set_cell_data for more performance
		var data = __backup[map_cell]
		if data[0] == TileMap.INVALID_CELL:
			__tile_map.set_cellv(map_cell, data[0])
		else:
			__tile_map.set_cellv(map_cell, data[0], data[1] & CELL_X_FLIPPED, data[1] & CELL_Y_FLIPPED, data[1] & CELL_TRANSPOSED, Vector2(data[2], data[3]))
	__backup.clear()

func get_tile_set() -> TileSet:
	return __tile_map.tile_set



func freeze_input() -> void:
	_is_input_freezed = true
func resume_input() -> void:
	_is_input_freezed = false













static func create_cell_data(tile_id: int, cell_x_flipped: bool = false, cell_y_flipped: bool = false, cell_transposed: bool = false, subtile_coord: Vector2 = Vector2.ZERO) -> PoolIntArray:
	var data = PoolIntArray()
	if tile_id < 0:
		data.resize(1)
		data[0] = tile_id
		return data
	data.resize(4)
	data[0] = tile_id
	data[1] = 0
	if cell_x_flipped:
		data[1] |= CELL_X_FLIPPED
	if cell_y_flipped:
		data[1] |= CELL_Y_FLIPPED
	if cell_transposed:
		data[1] |= CELL_TRANSPOSED
	data[2] = subtile_coord.x
	data[3] = subtile_coord.y
	return data
