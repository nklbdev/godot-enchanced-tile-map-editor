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
var cell_type: int setget __set_cell_type
func __set_cell_type(value: int) -> void:
	if value == cell_type:
		return
	cell_type = value
	# Do something

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










enum {
	CELL_TYPE_HEX = 0,
	CELL_TYPE_TET = 1,
	CELL_TYPE_MAP = 2,
}

const CELL_TYPE_SIZES: PoolVector2Array = PoolVector2Array([
	Vector2.ONE / 4, # CELL_HEX = 1,
	Vector2.ONE / 2, # CELL_TET = 2,
	Vector2.ONE / 1, # CELL_MAP = 3
])

const CELL_TYPE_OFFSETS: PoolVector2Array = PoolVector2Array([
	  Vector2.ZERO,    # CELL_HEX = 1,
	- Vector2.ONE / 4, # CELL_TET = 2,
	  Vector2.ZERO,    # CELL_MAP = 3
])

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

# tet cell position and quarter
static func get_tet_cell_by_hex_cell(hex_cell: Vector2) -> Vector3:
	hex_cell = hex_cell.floor()
	var tet_cell = ((hex_cell + Vector2.ONE) / 2).floor()
	return Vector3(tet_cell.x, tet_cell.y, posmod(hex_cell.x, 2) + posmod(hex_cell.y, 2) * 2)

const __sections_in_hex_cell_result: PoolVector3Array = PoolVector3Array([Vector3.ZERO])
func get_sections_in_cell(cell: Vector2, _cell_type: int = cell_type) -> PoolVector3Array:
	match _cell_type:
		CELL_TYPE_HEX:
			__sections_in_hex_cell_result[0] = get_section_in_hex_cell(cell)
			return __sections_in_hex_cell_result
		CELL_TYPE_TET: return get_sections_in_tet_cell(cell)
		CELL_TYPE_MAP: return get_sections_in_map_cell(cell)
		_: return PoolVector3Array()

const __sections_in_tet_cell_result: PoolVector3Array = PoolVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
func get_sections_in_tet_cell(tet_cell: Vector2) -> PoolVector3Array:
	var hex_cell = tet_cell * 2 - Vector2.ONE
	__sections_in_tet_cell_result[0] = get_section_in_hex_cell(hex_cell)
	__sections_in_tet_cell_result[1] = get_section_in_hex_cell(hex_cell + Vector2.RIGHT)
	__sections_in_tet_cell_result[2] = get_section_in_hex_cell(hex_cell + Vector2.DOWN)
	__sections_in_tet_cell_result[3] = get_section_in_hex_cell(hex_cell + Vector2.ONE)
	return __sections_in_tet_cell_result

const __sections_in_map_cell_result: PoolVector3Array = PoolVector3Array([
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
func get_sections_in_map_cell(map_cell: Vector2) -> PoolVector3Array:
	__sections_in_map_cell_result[0] = Vector3(map_cell.x, map_cell.y, 0)
	__sections_in_map_cell_result[1] = Vector3(map_cell.x, map_cell.y, 1)
	__sections_in_map_cell_result[2] = Vector3(map_cell.x, map_cell.y, 2)
	__sections_in_map_cell_result[3] = Vector3(map_cell.x, map_cell.y, 3)
	__sections_in_map_cell_result[4] = Vector3(map_cell.x, map_cell.y, 4)
	__sections_in_map_cell_result[5] = Vector3(map_cell.x, map_cell.y, 5)
	__sections_in_map_cell_result[6] = Vector3(map_cell.x, map_cell.y, 6)
	__sections_in_map_cell_result[7] = Vector3(map_cell.x, map_cell.y, 7)
	__sections_in_map_cell_result[8] = Vector3(map_cell.x, map_cell.y, 8)
	return __sections_in_map_cell_result

func get_section_in_hex_cell(hex_cell: Vector2) -> Vector3:
	var regular_grid_position = hex_cell.floor() / 4
	var offsetted_grid_position: Vector2 = regular_grid_position - HALF_OFFSETS[
		4 * __tile_map.cell_half_offset +
		posmod(floor(regular_grid_position.x), 2) +
		posmod(floor(regular_grid_position.y), 2) * 2]
	var section = (offsetted_grid_position.posmod(1) * 2 + Vector2.ONE / 2).floor()
	return Vector3(floor(offsetted_grid_position.x), floor(offsetted_grid_position.y), section.x + section.y * 3)

func get_half_offsetted_map_cell_position(map_cell: Vector2) -> Vector2:
	return map_cell + HALF_OFFSETS[__tile_map.cell_half_offset * 4 + posmod(map_cell.x, 2) + posmod(map_cell.y, 2) * 2]

var __quarter: Vector2 = Vector2.ONE / 4
var __half: Vector2 = Vector2.ONE / 2
func get_cell_world_rect(cell: Vector2, _cell_type: int = cell_type) -> Rect2:
	match _cell_type:
		CELL_TYPE_HEX: return Rect2(cell / 4, __quarter)
		CELL_TYPE_TET: return Rect2(cell / 2 - __quarter, __half)
		CELL_TYPE_MAP: return Rect2(cell + HALF_OFFSETS[__tile_map.cell_half_offset * 4 + posmod(cell.x, 2) + posmod(cell.y, 2) * 2], Vector2.ONE)
	assert(false)
	return Rect2()

func get_cell_by_hex_cell(hex_cell: Vector2, _cell_type: int = cell_type) -> Vector2:
	return get_cell_in_world(hex_cell / 4, _cell_type)

func get_cell_in_world(world_position: Vector2, _cell_type: int = cell_type) -> Vector2:
	match _cell_type:
		CELL_TYPE_HEX: return (world_position * 4).floor()
		CELL_TYPE_TET: return (world_position * 2 + __half).floor()
		CELL_TYPE_MAP: return (world_position - HALF_OFFSETS[
			__tile_map.cell_half_offset * 4 +
			posmod(floor(world_position.x), 2) +
			posmod(floor(world_position.y), 2) * 2]).floor()
	assert(false)
	return Vector2.ZERO








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
