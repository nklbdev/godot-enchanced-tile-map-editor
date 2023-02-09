extends Object

const Serialization = preload("serialization.gd")

enum Rotation {
	ROTATE_60,
	ROTATE_90,
	ROTATE_120,
	ROTATE_180,
	ROTATE_240,
	ROTATE_270,
	ROTATE_300
}

enum Flipping {
	FLIP_0,
	FLIP_30,
	FLIP_45,
	FLIP_60,
	FLIP_90,
	FLIP_120,
	FLIP_135,
	FLIP_150,
}

const __ROTATIONS_RECT: PoolIntArray = PoolIntArray([0, 1, 0, 2, 0, 3, 0])
const __ROTATIONS_HEX:  PoolIntArray = PoolIntArray([1, 0, 2, 3, 4, 0, 5])

const __FLIPPINGS_RECT: PoolIntArray = PoolIntArray([0, -1,  1, -1,  2, -1,  3, -1])
const __FLIPPINGS_HEX:  PoolIntArray = PoolIntArray([0,  1, -1,  2,  3,  4, -1,  5])

enum CellTransform {
	ROTATE_90,
	ROTATE_180,
	ROTATE_270,
	FLIP_0,
	FLIP_45,
	FLIP_90,
	FLIP_135,
}

class Pattern:
	const Common = preload("common.gd")
	
	const FLIPPING_BASES: PoolVector2Array = PoolVector2Array([
		Vector2.RIGHT, Vector2.UP,    # 0
		Vector2.DOWN,  Vector2.RIGHT, # 135
		Vector2.LEFT,  Vector2.DOWN,  # 90
		Vector2.UP,    Vector2.LEFT,  # 45
	])

	const ROTATION_BASES: PoolVector2Array = PoolVector2Array([
		Vector2.DOWN, Vector2.LEFT,  # 270
		Vector2.LEFT, Vector2.UP,    # 180
		Vector2.UP,   Vector2.RIGHT, # 90
	])
	
	
	var size: Vector2
	var cells: Dictionary
	signal changed

	const __temp_map_cell_data: PoolIntArray = PoolIntArray([0, 0, 0, 0])
	func _init(size: Vector2 = Vector2.ZERO, data: PoolIntArray = []) -> void:
		assert(size == size.abs())
		assert(size.x * size.y * 4 == data.size())
		self.size = size
		var i: int
		for y in size.y: for x in size.x:
			__temp_map_cell_data[0] = data[i]
			__temp_map_cell_data[1] = data[i + 1]
			__temp_map_cell_data[2] = data[i + 2]
			__temp_map_cell_data[3] = data[i + 3]
			cells[Vector2(x, y)] = __temp_map_cell_data
			i += 4

	func create_icon(tile_map: TileMap, icon_size: Vector2) -> Texture:
		return null

	func get_origin_map_cell(world_position: Vector2, ruler_grid_map: TileMap) -> Vector2:
		if size == Vector2.ONE:
			return ruler_grid_map.world_to_map(world_position)
		var linear_size: Vector2 = ruler_grid_map.cell_half_offset_type.conv(size)
		return ruler_grid_map.world_to_map(
			world_position + ruler_grid_map.cell_half_offset_type.conv(
				(Vector2.ONE - linear_size + Vector2.RIGHT *
				((int(linear_size.y > 1) + (int(linear_size.y) & 1)) * ruler_grid_map.cell_half_offset_type.offset)) / 2))

	func rotate_ccw(steps: int, cell_half_offset: int) -> void:
		if cell_half_offset == TileMap.HALF_OFFSET_DISABLED:
			__rotate_ccw_rect(__ROTATIONS_RECT[steps])
		else:
			__rotate_ccw_hex(__ROTATIONS_HEX[steps], cell_half_offset)

	func flip(dir: int, cell_half_offset: int) -> void:
		if cell_half_offset == TileMap.HALF_OFFSET_DISABLED:
			__flip_rect(__FLIPPINGS_RECT[dir])
		else:
			__flip_hex(__FLIPPINGS_HEX[dir], cell_half_offset)

	func transform_cells(cell_transform: int) -> void:
		match cell_transform:
			CellTransform.ROTATE_90: for cell in cells.keys(): cells[cell][1] = Common.rotate_cell_transform(cells[cell][1], 1)
			CellTransform.ROTATE_180: for cell in cells.keys(): cells[cell][1] = Common.rotate_cell_transform(cells[cell][1], 2)
			CellTransform.ROTATE_270: for cell in cells.keys(): cells[cell][1] = Common.rotate_cell_transform(cells[cell][1], 3)
			CellTransform.FLIP_0: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_Y_FLIPPED
			CellTransform.FLIP_45: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_TRANSPOSED
			CellTransform.FLIP_90: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_X_FLIPPED
			CellTransform.FLIP_135: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_X_FLIPPED | Common.CELL_Y_FLIPPED | Common.CELL_TRANSPOSED
		emit_signal("changed")



	func __rotate_ccw_rect(steps: int) -> void: # RectangularRotations
		steps = (posmod(steps, 4) - 1) * 2
		if steps >= 0:
			__transform_rect(ROTATION_BASES[steps], ROTATION_BASES[steps + 1])

	func __flip_rect(dir: int) -> void:
		dir = posmod(dir, 4) * 2
		__transform_rect(FLIPPING_BASES[dir], FLIPPING_BASES[dir + 1])

	func __transform_rect(base_x, base_y) -> void:
		var new_cells: Dictionary
		var transform: Transform2D = Transform2D(base_x, base_y, Vector2.ZERO)
		var new_cell: Vector2
		var position: Vector2 = Vector2.INF
		var end: Vector2 = -Vector2.INF
		for cell in cells.keys():
			new_cell = transform.xform(cell).round()
			position.x = min(position.x, new_cell.x)
			position.y = min(position.y, new_cell.y)
			end.x = max(end.x, new_cell.x)
			end.y = max(end.y, new_cell.y)
			new_cells[new_cell] = cells[cell]
		cells.clear()
		size = end - position + Vector2.ONE
		for cell in new_cells.keys():
			cells[cell - position] = new_cells[cell]
		emit_signal("changed")


	func __rotate_ccw_hex(steps: int, cell_half_offset: int) -> void:
		__transform_hex(0, 1, 2, steps, false, cell_half_offset)

	func __flip_hex(dir: int, cell_half_offset: int) -> void:
		__transform_hex(1, 0, 2, posmod(dir + cell_half_offset % 3, 6) + 1, true, cell_half_offset)

	func __transform_hex(idx_x: int, idx_y: int, idx_z: int, steps: int, paired: bool, cell_half_offset: int) -> void:
		steps = posmod(steps, 6)
		var sig: int = 1 - (steps & 1) * 2

		if paired:
			steps = posmod(1 - steps, 3) 

		idx_x = (idx_x + steps) % 3
		idx_y = (idx_y + steps) % 3
		idx_z = (idx_z + steps) % 3

		var new_cells: Dictionary
		var new_cell: Vector2
		var position: Vector2 = Vector2.INF
		for cell in cells.keys():
			var hex: Vector3 = Common.map_to_cube(cell, cell_half_offset)
			hex = sig * Vector3(hex[idx_x], hex[idx_y], hex[idx_z])
			position.x = min(position.x, hex.x)
			position.y = min(position.y, hex.y)
			new_cells[hex] = cells[cell]
		cells.clear()
		var cube_position: Vector3 = Vector3(position.x, position.y, -position.x-position.y)
		position = Vector2.INF
		var new_new_cells: Dictionary
		for hex in new_cells.keys():
			new_cell = Common.cube_to_map(hex - cube_position, cell_half_offset)
			position.x = min(position.x, new_cell.x)
			position.y = min(position.y, new_cell.y)
			new_new_cells[new_cell] = new_cells[hex]
		size = -Vector2.INF
		for cell in new_new_cells.keys():
			new_cell = cell - position
			cells[new_cell] = new_new_cells[cell]
			size.x = max(size.x, new_cell.x)
			size.y = max(size.y, new_cell.y)
		size += Vector2.ONE
		emit_signal("changed")


const Common = preload("common.gd")
static func serialize(pattern: Pattern) -> String:
	var data: PoolIntArray
	data.resize(pattern.cells.size() * 6)
	var cell_data: PoolIntArray
	var i: int
	for cell in pattern.cells.keys():
		cell_data = pattern.cells[cell]
		data[i    ] = cell.x
		data[i + 1] = cell.y
		data[i + 2] = cell_data[0]
		data[i + 3] = cell_data[1]
		data[i + 4] = cell_data[2]
		data[i + 5] = cell_data[3]
		i += 6
	return to_json({
		size = Serialization.serialize(pattern.size),
		data = data
	})

static func deserialize(serialized_data: String) -> Pattern:
	var raw_data = parse_json(serialized_data)
	var pattern: Pattern = Pattern.new()
	pattern.size = Serialization.deserialize(raw_data.size, TYPE_VECTOR2)
	var cell_data: PoolIntArray = PoolIntArray([0, 0, 0, 0])
	for i in range(0, raw_data.data.size(), 6):
		cell_data[0] = raw_data.data[i + 2]
		cell_data[1] = raw_data.data[i + 3]
		cell_data[2] = raw_data.data[i + 4]
		cell_data[3] = raw_data.data[i + 5]
		pattern.cells[Vector2(raw_data.data[i], raw_data.data[i + 1])] = cell_data
	return pattern
