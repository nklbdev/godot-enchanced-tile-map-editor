extends Object

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

var __tile_map: TileMap
var __backup: Dictionary
var __previous_data_for_update_bitmask_area: Array

func _init(tile_map: TileMap) -> void:
	__tile_map = tile_map
	__previous_data_for_update_bitmask_area.resize(9)

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

func commit_changes():
	# Create undoredo
	__backup.clear()

func reset_changes():
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


func get_half_offset() -> int:
	return __tile_map.cell_half_offset
















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
