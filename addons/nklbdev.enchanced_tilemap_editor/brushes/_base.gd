extends Object

const Common = preload("../common.gd")
const Paper = preload("../paper.gd")

enum {
	CELL_TYPE_HEX = 0,
	CELL_TYPE_TET = 1,
	CELL_TYPE_MAP = 2,
	CELL_TYPE_PAT = 3,
}

var _drawing_settings: Common.DrawingSettings

var cell_type: int setget __set_cell_type
func __set_cell_type(value: int) -> void:
	if value == cell_type:
		return
	cell_type = value
	# Do something

func _init(drawing_settings: Common.DrawingSettings) -> void:
	_drawing_settings = drawing_settings



















func paint(cell: Vector2, paper: Paper) -> void:
	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
	# порядкового номера (идентификатора?) рисовательного действия и координат
	match cell_type:
		CELL_TYPE_HEX: _paint_hex_cell(cell, paper)
		CELL_TYPE_TET: _paint_tet_cell(cell, paper)
		CELL_TYPE_MAP: _paint_map_cell(cell, paper)
		CELL_TYPE_PAT: _paint_pat_cell(cell, paper)
		_: assert(false)

const __quarter: Vector2 = Vector2.ONE / 4
const __half: Vector2 = Vector2.ONE / 2
func draw(cell: Vector2, overlay: Control, half_offset: int) -> void:
	match cell_type:
		CELL_TYPE_HEX: overlay.draw_rect(Rect2(cell / 4, __quarter), _drawing_settings.drawn_cells_color)
		CELL_TYPE_TET: overlay.draw_rect(Rect2(cell / 2 - __quarter, __half), _drawing_settings.drawn_cells_color)
		CELL_TYPE_MAP: overlay.draw_rect(Rect2(cell + Common.get_half_offset(cell, half_offset), Vector2.ONE), _drawing_settings.drawn_cells_color)
		CELL_TYPE_PAT: _draw_pat_cell(cell, overlay, half_offset)
		_: assert(false)

func get_cell(world_position: Vector2, half_offset: int) -> Vector2:
	match cell_type:
		CELL_TYPE_HEX: return _get_hex_cell(world_position)
		CELL_TYPE_TET: return _get_tet_cell(world_position)
		CELL_TYPE_MAP: return _get_map_cell(world_position, half_offset)
		CELL_TYPE_PAT: return _get_pat_cell(world_position, half_offset)
	assert(false)
	return Vector2.ZERO

func _get_hex_cell(world_position: Vector2) -> Vector2:
	return (world_position * 4).floor()

func _get_tet_cell(world_position: Vector2) -> Vector2:
	return (world_position * 2 + __quarter).floor()

func _get_map_cell(world_position: Vector2, half_offset: int) -> Vector2:
	return (world_position - Common.get_half_offset(world_position.floor(), half_offset)).floor()



func _paint_hex_cell(hex_cell: Vector2, paper: Paper) -> void:
	assert(false)

func _paint_tet_cell(tet_cell: Vector2, paper: Paper) -> void:
	assert(false)

func _paint_map_cell(map_cell: Vector2, paper: Paper) -> void:
	assert(false)

func _paint_pat_cell(pat_cell: Vector2, paper: Paper) -> void:
	assert(false)



func _get_pat_cell(world_position: Vector2, half_offset: int) -> Vector2:
	assert(false)
	return Vector2.ZERO



func _draw_pat_cell(cell: Vector2, overlay: Control, half_offset: int) -> void:
	assert(false)








#const HALF_OFFSETS: PoolVector2Array = PoolVector2Array([
#	#TileMap.HALF_OFFSET_X = 0
#	Vector2( 0,   0), Vector2( 0,    0  ),
#	Vector2( 0.5, 0), Vector2( 0.5,  0  ),
#	#TileMap.HALF_OFFSET_Y = 1
#	Vector2( 0,   0), Vector2( 0,    0.5),
#	Vector2( 0,   0), Vector2( 0,    0.5),
#	#TileMap.HALF_OFFSET_DISABLED = 2
#	Vector2( 0,   0), Vector2( 0,    0  ),
#	Vector2( 0,   0), Vector2( 0,    0  ),
#	#TileMap.HALF_OFFSET_NEGATIVE_X = 3
#	Vector2( 0,   0), Vector2( 0,    0  ),
#	Vector2(-0.5, 0), Vector2(-0.5,  0  ),
#	#TileMap.HALF_OFFSET_NEGATIVE_Y = 4
#	Vector2( 0,   0), Vector2( 0,   -0.5),
#	Vector2( 0,   0), Vector2( 0,   -0.5),
#])
#
## tet cell position and quarter
#static func get_tet_cell_by_hex_cell(hex_cell: Vector2) -> Vector3:
#	hex_cell = hex_cell.floor()
#	var tet_cell = ((hex_cell + Vector2.ONE) / 2).floor()
#	return Vector3(tet_cell.x, tet_cell.y, posmod(hex_cell.x, 2) + posmod(hex_cell.y, 2) * 2)

#const __sections_in_hex_cell_result: PoolVector3Array = PoolVector3Array([Vector3.ZERO])
#func get_sections_in_cell(cell: Vector2, _cell_type: int = cell_type) -> PoolVector3Array:
#	match _cell_type:
#		CELL_TYPE_HEX:
#			__sections_in_hex_cell_result[0] = get_section_in_hex_cell(cell)
#			return __sections_in_hex_cell_result
#		CELL_TYPE_TET: return get_sections_in_tet_cell(cell)
#		CELL_TYPE_MAP: return get_sections_in_map_cell(cell)
#		_: return PoolVector3Array()

#const __sections_in_tet_cell_result: PoolVector3Array = PoolVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
#func get_sections_in_tet_cell(tet_cell: Vector2) -> PoolVector3Array:
#	var hex_cell = tet_cell * 2 - Vector2.ONE
#	__sections_in_tet_cell_result[0] = get_section_in_hex_cell(hex_cell)
#	__sections_in_tet_cell_result[1] = get_section_in_hex_cell(hex_cell + Vector2.RIGHT)
#	__sections_in_tet_cell_result[2] = get_section_in_hex_cell(hex_cell + Vector2.DOWN)
#	__sections_in_tet_cell_result[3] = get_section_in_hex_cell(hex_cell + Vector2.ONE)
#	return __sections_in_tet_cell_result

#const __sections_in_map_cell_result: PoolVector3Array = PoolVector3Array([
#	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
#	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
#	Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
#func get_sections_in_map_cell(map_cell: Vector2) -> PoolVector3Array:
#	__sections_in_map_cell_result[0] = Vector3(map_cell.x, map_cell.y, 0)
#	__sections_in_map_cell_result[1] = Vector3(map_cell.x, map_cell.y, 1)
#	__sections_in_map_cell_result[2] = Vector3(map_cell.x, map_cell.y, 2)
#	__sections_in_map_cell_result[3] = Vector3(map_cell.x, map_cell.y, 3)
#	__sections_in_map_cell_result[4] = Vector3(map_cell.x, map_cell.y, 4)
#	__sections_in_map_cell_result[5] = Vector3(map_cell.x, map_cell.y, 5)
#	__sections_in_map_cell_result[6] = Vector3(map_cell.x, map_cell.y, 6)
#	__sections_in_map_cell_result[7] = Vector3(map_cell.x, map_cell.y, 7)
#	__sections_in_map_cell_result[8] = Vector3(map_cell.x, map_cell.y, 8)
#	return __sections_in_map_cell_result

#func get_section_in_hex_cell(hex_cell: Vector2) -> Vector3:
#	var regular_grid_position = hex_cell.floor() / 4
#	var offsetted_grid_position: Vector2 = regular_grid_position - HALF_OFFSETS[
#		4 * __tile_map.cell_half_offset +
#		posmod(floor(regular_grid_position.x), 2) +
#		posmod(floor(regular_grid_position.y), 2) * 2]
#	var section = (offsetted_grid_position.posmod(1) * 2 + Vector2.ONE / 2).floor()
#	return Vector3(floor(offsetted_grid_position.x), floor(offsetted_grid_position.y), section.x + section.y * 3)

#func get_half_offsetted_map_cell_position(map_cell: Vector2) -> Vector2:
#	return map_cell + HALF_OFFSETS[__tile_map.cell_half_offset * 4 + posmod(map_cell.x, 2) + posmod(map_cell.y, 2) * 2]

#var __quarter: Vector2 = Vector2.ONE / 4
#var __half: Vector2 = Vector2.ONE / 2
#func get_cell_world_rect(cell: Vector2, _cell_type: int = cell_type) -> Rect2:
#	match _cell_type:
#		CELL_TYPE_HEX: return Rect2(cell / 4, __quarter)
#		CELL_TYPE_TET: return Rect2(cell / 2 - __quarter, __half)
#		CELL_TYPE_MAP: return Rect2(cell + HALF_OFFSETS[__tile_map.cell_half_offset * 4 + posmod(cell.x, 2) + posmod(cell.y, 2) * 2], Vector2.ONE)
#	assert(false)
#	return Rect2()
#
#func get_cell_by_hex_cell(hex_cell: Vector2, _cell_type: int = cell_type) -> Vector2:
#	return get_cell_in_world(hex_cell / 4, _cell_type)
#
#func get_cell_in_world(world_position: Vector2, _cell_type: int = cell_type) -> Vector2:
#	match _cell_type:
#		CELL_TYPE_HEX: return (world_position * 4).floor()
#		CELL_TYPE_TET: return (world_position * 2 + __half).floor()
#		CELL_TYPE_MAP: return (world_position - HALF_OFFSETS[
#			__tile_map.cell_half_offset * 4 +
#			posmod(floor(world_position.x), 2) +
#			posmod(floor(world_position.y), 2) * 2]).floor()
#	assert(false)
#	return Vector2.ZERO
