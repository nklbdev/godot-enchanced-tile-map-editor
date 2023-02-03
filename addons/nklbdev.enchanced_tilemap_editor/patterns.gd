extends Object

const Serialization = preload("serialization.gd")

enum RectangularRotations {
	ROTATE_270,
	ROTATE_180,
	ROTATE_90,
	MAX
}

enum HexagonalRotations {
	ROTATE_300
	ROTATE_240,
	ROTATE_180,
	ROTATE_120,
	ROTATE_60,
	MAX
}

enum RectangularFlippings {
	FLIP_0,
	FLIP_45,
	FLIP_90,
	FLIP_135,
	MAX
}

enum HexagonalFlippings {
	FLIP_0,
	FLIP_30,
	FLIP_60,
	FLIP_90,
	FLIP_120,
	FLIP_150,
	MAX
}

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
	var cell_half_offset: int
	var used_cells_count: int
	var cells: Dictionary
	var bounds: Rect2

	func create_icon(tile_map: TileMap, icon_size: Vector2) -> Texture:
		return null

	func normalize() -> void:
		pass

	func rotate(rotation: int) -> void:
		pass

	func flip(flipping: int) -> void:
		pass

	func transform_cells(cell_transform: int) -> void:
		match cell_transform:
			CellTransform.ROTATE_90: for cell in cells.keys(): cells[cell][1] = Common.rotate_cell_transform(cells[cell][1], 1)
			CellTransform.ROTATE_180: for cell in cells.keys(): cells[cell][1] = Common.rotate_cell_transform(cells[cell][1], 2)
			CellTransform.ROTATE_270: for cell in cells.keys(): cells[cell][1] = Common.rotate_cell_transform(cells[cell][1], 3)
			CellTransform.FLIP_0: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_Y_FLIPPED
			CellTransform.FLIP_45: for cell in cells.keys(): cells[cell][1] ^= (Common.CELL_X_FLIPPED | Common.CELL_Y_FLIPPED | Common.CELL_TRANSPOSED)
			CellTransform.FLIP_90: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_X_FLIPPED
			CellTransform.FLIP_135: for cell in cells.keys(): cells[cell][1] ^= Common.CELL_TRANSPOSED

	func __get_cell_data(x: int, y: int) -> PoolIntArray:
		assert(false, "override needed")
		return PoolIntArray()

	func serialize() -> Dictionary:
		var repititions_count: int
		var compressed_data: Array
		var previous_cell_data: PoolIntArray
		var cell_data: PoolIntArray
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x):
				cell_data = cells.get(Vector2(x, y), Common.EMPTY_CELL_DATA)
				if cell_data == previous_cell_data:
					compressed_data[compressed_data.size() - 1] += 1
				else:
					compressed_data.append_array(cell_data)
					compressed_data.append(1)
					previous_cell_data = cell_data
		return {
			cell_half_offset = cell_half_offset,
			used_cells_count = used_cells_count,
			compressed_data = compressed_data,
			bounds = Serialization.serialize(bounds)
		}

class HexagonalPattern:
	extends Pattern

	var orientation: int # HORIZONTAL or VERTICAL

	func _init(orientation: int):
		self.orientation = orientation

	# OVERRIDES

	func normalize() -> void:
		pass

	func rotate(rotation: int) -> void:
		__transform(1, 2, 3, rotation, false)

	func flip(flipping: int) -> void:
		__transform(1, 0, 2, flipping + orientation, true)

	func duplicate() -> HexagonalPattern:
		var pattern = HexagonalPattern.new(orientation)
		pattern.cells = cells.duplicate()
		pattern.bounds = bounds
		return pattern

	const COMP: PoolIntArray = PoolIntArray([0, 0, 0])
	func __transform(idx_x: int, idx_y: int, idx_z: int, steps: int, paired: bool) -> void:
		var sig = (steps & 1) * 2 - 1
		if paired:
			steps /= 2
		idx_x = (idx_x + steps) % 3
		idx_y = (idx_y + steps) % 3
		idx_z = (idx_z + steps) % 3
		
		var new_cells: Dictionary
		bounds = Rect2()
		var cell_rect = Rect2(Vector2.ZERO, Vector2.ONE)
		for cell in cells.keys():
			COMP[0] = cell.x; COMP[1] = cell.y; COMP[2] = -cell.x-cell.y
			cell_rect.position = Vector2(sig * COMP[idx_x], sig * COMP[idx_y])
			new_cells[cell_rect.position] = cells[cell]
			bounds = cell_rect if bounds.has_no_area() else bounds.merge(cell_rect)
		cells = new_cells

	func serialize() -> Dictionary:
		var result: Dictionary = .serialize()
		result["orientation"] = orientation
		return result

class RectangularPattern:
	extends Pattern
	
	const FLIPPING_BASES: PoolVector2Array = PoolVector2Array([
		Vector2.RIGHT, Vector2.UP,    # 0
		Vector2.UP,    Vector2.LEFT,  # 45
		Vector2.LEFT,  Vector2.DOWN,  # 90
		Vector2.DOWN,  Vector2.RIGHT, # 135
	])

	const ROTATION_BASES: PoolVector2Array = PoolVector2Array([
		Vector2.UP,   Vector2.RIGHT, # 90
		Vector2.LEFT, Vector2.UP,    # 180
		Vector2.DOWN, Vector2.LEFT,  # 270
	])
	
	func _init() -> void:
		cell_half_offset = TileMap.HALF_OFFSET_DISABLED



	func get_origin_map_cell(world_position: Vector2) -> Vector2:
		return (world_position - bounds.position - bounds.size / 2).round()

	func get_cell_data(cell: Vector2) -> PoolIntArray:
		return cells.get((cell - bounds.position).posmodv(bounds.size), Common.EMPTY_CELL_DATA)

	func set_cell_data(cell: Vector2, data: PoolIntArray) -> void:
		cells[cell] = data
		bounds = bounds.merge(Rect2(cell, Vector2.ONE))
		used_cells_count = cells.size()


	# OVERRIDES

	func duplicate() -> RectangularPattern:
		var pattern = RectangularPattern.new()
		pattern.cells = cells.duplicate()
		pattern.bounds = bounds
		return pattern

	func normalize() -> void:
		var new_cells: Dictionary
		for cell in cells.keys():
			new_cells[cell - bounds.position] = cells[cell]
		cells = new_cells
		bounds.position = Vector2.ZERO

	func rotate(rotation: int) -> void: # RectangularRotations
		__transform(ROTATION_BASES[rotation * 2], ROTATION_BASES[rotation * 2 + 1])

	func flip(flipping: int) -> void:
		__transform(FLIPPING_BASES[flipping * 2], FLIPPING_BASES[flipping * 2 + 1])

	func __transform(base_x, base_y) -> void:
		if cells.empty():
			return
		var new_cells: Dictionary
		var transform: Transform2D = Transform2D(base_x, base_y, Vector2.ZERO)
		var cell_rect = Rect2(Vector2.ZERO, Vector2.ONE)
		for cell in cells.keys():
			cell_rect.position = transform * cell
			new_cells[cell_rect.position] = cells[cell]
			bounds = cell_rect if bounds.has_no_area() else bounds.merge(cell_rect)
		cells = new_cells

#	const __temp_map_cell_data: PoolIntArray = PoolIntArray([0, 0, 0, 0])
#	static func from_rect_and_data(rect: Rect2, data: PoolIntArray, original_cell_half_offset: int) -> Pattern:
#		rect = rect.abs()
#		assert(rect.size.x * rect.size.y * 4 == data.size())
#		var original_half_offset_type: Common.CellHalfOffsetType = Common.CELL_HALF_OFFSET_TYPES[original_cell_half_offset]
#		var pattern: Pattern = Pattern.new(original_half_offset_type.offset_orientation)
#		var map: TileMap = pattern.__map
#		if original_cell_half_offset > 2:
#			map = map.duplicate(0)
#			map.cell_half_offset = original_cell_half_offset
#		var i: int
#		for y in range(rect.position.y, rect.end.y): for x in range(rect.position.x, rect.end.x):
#			__temp_map_cell_data[0] = data[i]
#			__temp_map_cell_data[1] = data[i + 1]
#			__temp_map_cell_data[2] = data[i + 2]
#			__temp_map_cell_data[3] = data[i + 3]
#			Common.set_map_cell_data(
#				pattern.__map,
#				pattern.__map.world_to_map(map.map_to_world(Vector2(x, y))),
#				__temp_map_cell_data)
#			i += 4
#		pattern.size = pattern.__map.get_used_rect().size
#		pattern.used_cells_count = pattern.__map.get_used_cells().size()
#		pattern.normalize()
#		return pattern

#static func deserialize(serialized_data: String) -> Pattern:
#	var data = parse_json(serialized_data)
##	var pattern: Pattern = Pattern.new(data.half_offset_orientation)
#	pattern.size = Serialization.deserialize(data.size, TYPE_VECTOR2)
#	pattern.used_cells_count = data.used_cells_count
#	pattern.half_offset_orientation = data.half_offset_orientation
#	var x: int
#	var y: int
#	var d: PoolIntArray = PoolIntArray([0, 0, 0, 0])
#	for i in range(0, data.compressed_data.size(), 5):
#		d[0] = data.compressed_data[i]
#		d[1] = data.compressed_data[i + 1]
#		d[2] = data.compressed_data[i + 2]
#		d[3] = data.compressed_data[i + 3]
#		for r in data.compressed_data[i + 4]:
#			print(d)
#			Common.set_map_cell_data(pattern.__map, Vector2(x, y), d)
#			x += 1
#			if x >= pattern.size.x:
#				x = 0
#				y += 1
#	prints(pattern.size, pattern.used_cells_count, pattern.half_offset_orientation)
#	return pattern
#	return null
