extends Object

const Serialization = preload("serialization.gd")

enum Rotation {
	ROTATE_300
	ROTATE_270,
	ROTATE_240,
	ROTATE_180,
	ROTATE_120,
	ROTATE_90,
	ROTATE_60,
}

const ROTATIONS: PoolRealArray = PoolRealArray([
	PI * 1.0 / 3,
	PI * 1.0 / 2,
	PI * 2.0 / 3,
	PI,
	PI * 4.0 / 3,
	PI * 3.0 / 2,
	PI * 5.0 / 3,
])

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
	var FLIPPINGS: PoolVector2Array = PoolVector2Array([
		Vector2.RIGHT, Vector2.UP,    # FLIP_0,
		Vector2.RIGHT.rotated(PI * 10 / 6), Vector2.RIGHT.rotated(PI * 1 / 6), # FLIP_30, X будет под 60г а Y будет под 330
		Vector2.UP,    Vector2.LEFT, # FLIP_45,
		Vector2.RIGHT.rotated(PI * 8 / 6), Vector2.RIGHT.rotated(PI * 11 / 6), # FLIP_60, X будет под 120г а Y будет под 30
		Vector2.LEFT,  Vector2.DOWN,  # FLIP_90,
		Vector2.RIGHT.rotated(PI * 4 / 6), Vector2.RIGHT.rotated(PI * 7 / 6), # FLIP_120, X будет под 240г а Y будет под 150
		Vector2.DOWN,  Vector2.RIGHT, # FLIP_135,
		Vector2.RIGHT.rotated(PI * 2 / 6), Vector2.RIGHT.rotated(PI * 5 / 6), # FLIP_150, X будет под 300г а Y будет под 210
	])
	const Common = preload("common.gd")
	var __map: TileMap
	var size: Vector2
	var used_cells_count: int
	var half_offset_orientation: int
	func _init(_half_offset_orientation: int = Common.HalfOffsetOrientation.NOT_OFFSETTED) -> void:
		half_offset_orientation = _half_offset_orientation
		__map = TileMap.new()
		__map.cell_size = Vector2.ONE
		__map.mode = TileMap.MODE_CUSTOM
		__map.cell_half_offset = TileMap.HALF_OFFSET_X if half_offset_orientation == Common.HalfOffsetOrientation.HORIZONTAL_OFFSETTED else \
			(TileMap.HALF_OFFSET_Y if half_offset_orientation == Common.HalfOffsetOrientation.VERTICAL_OFFSETTED else TileMap.HALF_OFFSET_DISABLED)
		__map.cell_custom_transform = Transform2D.IDENTITY.scaled(Common.CELL_HALF_OFFSET_TYPES[__map.cell_half_offset].cell_regular_scale)

	func create_icon(tile_map: TileMap, icon_size: Vector2) -> Texture:
		return null

	func duplicate() -> Pattern:
		var pattern = Pattern.new(half_offset_orientation)
		for cell in __map.get_used_cells():
			Common.set_map_cell_data(pattern.__map, cell, Common.get_map_cell_data(__map, cell))
		pattern.size = size
		pattern.used_cells_count = used_cells_count
		return pattern

	func get_cell_data(cell: Vector2) -> PoolIntArray:
		cell = cell.posmodv(size)
		return Common.get_map_cell_data(__map, cell)

	func set_cell_data(cell: Vector2, data: PoolIntArray) -> void:
		prints(cell, data)
		Common.set_map_cell_data(__map, cell, data)
		__map.update_dirty_quadrants()
		size = __map.get_used_rect().size
		used_cells_count = __map.get_used_cells().size()

	func normalize() -> void:
		return
		print("normalize")
		for cell in __map.get_used_cells():
			prints(cell, Common.get_map_cell_data(__map, cell))
		var used_rect_position: Vector2 = __map.get_used_rect().position
		if size == Vector2.ONE and used_rect_position != Vector2.ZERO:
			Common.set_map_cell_data(__map, Vector2.ZERO, Common.get_map_cell_data(__map, used_rect_position))
			__map.set_cellv(used_rect_position, TileMap.INVALID_CELL)
			return
		if used_rect_position == Vector2.ZERO:
			return
		var map: TileMap = __map.duplicate(0)
		if __map.map_to_world(used_rect_position + Vector2.ONE) - __map.map_to_world(used_rect_position) != \
			__map.map_to_world(Vector2.ONE) - __map.map_to_world(Vector2.ZERO):
			__map.cell_half_offset = Common.CELL_HALF_OFFSET_TYPES[__map.cell_half_offset].opposite.index
		__map.clear()
		for cell in map.get_used_cells():
			Common.set_map_cell_data(__map, cell - used_rect_position, Common.get_map_cell_data(map, cell))
		size = __map.get_used_rect().size
		print("normalized")
		for cell in __map.get_used_cells():
			prints(cell, Common.get_map_cell_data(__map, cell))

	func get_origin_map_cell(world_position: Vector2, ruler_grid_map: TileMap) -> Vector2:
		var linear_size: Vector2 = ruler_grid_map.cell_half_offset_type.conv(size)
		return ruler_grid_map.world_to_map(
			world_position + ruler_grid_map.cell_half_offset_type.conv(
				(Vector2.ONE - linear_size + Vector2.RIGHT *
				((int(linear_size.y > 1) + (int(linear_size.y) & 1)) * ruler_grid_map.cell_half_offset_type.offset)) / 2))

	func rotate(rotation: int) -> void:
		var map: TileMap = __map.duplicate(0)
		__map.clear()
		map.cell_custom_transform = map.cell_custom_transform.rotated(ROTATIONS[rotation])
		for cell in map.get_used_cells():
			Common.set_map_cell_data(__map, __map.world_to_map(map.map_to_world(cell)), Common.get_map_cell_data(map, cell))
		size = __map.get_used_rect().size
		normalize()

	func flip(flipping: int) -> void:
		var map: TileMap = __map.duplicate(0)
		__map.clear()
		var target_cell: Vector2
		if map.cell_half_offset == TileMap.HALF_OFFSET_DISABLED:
			for cell in map.get_used_cells():
				match flipping:
					Flipping.FLIP_0: target_cell = Vector2(cell.x, -cell.y)
					Flipping.FLIP_45: target_cell = Vector2(-cell.y, -cell.x)
					Flipping.FLIP_90: target_cell = Vector2(-cell.x, cell.y)
					Flipping.FLIP_135: target_cell = Vector2(cell.y, cell.x)
					_: assert(false)
				Common.set_map_cell_data(__map, target_cell, Common.get_map_cell_data(map, cell))
			return
		var vertical: bool = map.cell_half_offset == TileMap.HALF_OFFSET_Y or map.cell_half_offset == TileMap.HALF_OFFSET_NEGATIVE_Y
		for cell in map.get_used_cells():
			var c: Vector3 = Common.map_to_cube(cell, map.cell_half_offset)
			if vertical:
				match flipping:
					Flipping.FLIP_0:   c = Vector3( c.x,  c.z,  c.y)
					Flipping.FLIP_30:  c = Vector3(-c.y, -c.x, -c.z)
					Flipping.FLIP_60:  c = Vector3( c.z,  c.y,  c.x)
					Flipping.FLIP_90:  c = Vector3(-c.x, -c.z, -c.y)
					Flipping.FLIP_120: c = Vector3( c.y,  c.x,  c.z)
					Flipping.FLIP_150: c = Vector3(-c.z, -c.y, -c.x)
			else:
				match flipping:
					Flipping.FLIP_0:   c = Vector3(-c.z, -c.y, -c.x)
					Flipping.FLIP_30:  c = Vector3( c.x,  c.z,  c.y)
					Flipping.FLIP_60:  c = Vector3(-c.y, -c.x, -c.z)
					Flipping.FLIP_90:  c = Vector3( c.z,  c.y,  c.x)
					Flipping.FLIP_120: c = Vector3(-c.x, -c.z, -c.y)
					Flipping.FLIP_150: c = Vector3( c.y,  c.x,  c.z)
			target_cell = Common.cube_to_map(c, __map.cell_half_offset)
			Common.set_map_cell_data(__map, target_cell, Common.get_map_cell_data(map, cell))
		size = __map.get_used_rect().size
		normalize()

	func transform_cells(cell_transform: int) -> void:
		var cell_data: PoolIntArray
		for cell in __map.get_used_cells():
			cell_data = Common.get_map_cell_data(__map, cell)
			match cell_transform:
				CellTransform.ROTATE_90: cell_data[1] = Common.rotate_cell_transform(cell_data[1], 1)
				CellTransform.ROTATE_180: cell_data[1] = Common.rotate_cell_transform(cell_data[1], 2)
				CellTransform.ROTATE_270: cell_data[1] = Common.rotate_cell_transform(cell_data[1], 3)
				CellTransform.FLIP_0: cell_data[1] ^= Common.CELL_Y_FLIPPED
				CellTransform.FLIP_45: cell_data[1] ^= (Common.CELL_X_FLIPPED | Common.CELL_Y_FLIPPED | Common.CELL_TRANSPOSED)
				CellTransform.FLIP_90: cell_data[1] ^= Common.CELL_X_FLIPPED
				CellTransform.FLIP_135: cell_data[1] ^= Common.CELL_TRANSPOSED
			Common.set_map_cell_data(__map, cell, cell_data)

	const __temp_map_cell_data: PoolIntArray = PoolIntArray([0, 0, 0, 0])
	static func from_rect_and_data(rect: Rect2, data: PoolIntArray, original_cell_half_offset: int) -> Pattern:
		rect = rect.abs()
		assert(rect.size.x * rect.size.y * 4 == data.size())
		var original_half_offset_type: Common.CellHalfOffsetType = Common.CELL_HALF_OFFSET_TYPES[original_cell_half_offset]
		var pattern: Pattern = Pattern.new(original_half_offset_type.offset_orientation)
		var map: TileMap = pattern.__map
		if original_cell_half_offset > 2:
			map = map.duplicate(0)
			map.cell_half_offset = original_cell_half_offset
		var i: int
		for y in range(rect.position.y, rect.end.y): for x in range(rect.position.x, rect.end.x):
			__temp_map_cell_data[0] = data[i]
			__temp_map_cell_data[1] = data[i + 1]
			__temp_map_cell_data[2] = data[i + 2]
			__temp_map_cell_data[3] = data[i + 3]
			Common.set_map_cell_data(
				pattern.__map,
				pattern.__map.world_to_map(map.map_to_world(Vector2(x, y))),
				__temp_map_cell_data)
			i += 4
		pattern.size = pattern.__map.get_used_rect().size
		pattern.used_cells_count = pattern.__map.get_used_cells().size()
		pattern.normalize()
		return pattern

const Common = preload("common.gd")
static func serialize(pattern: Pattern) -> String:
	print("serialize")
	var used_rect: Rect2 = pattern.__map.get_used_rect()
	var previous_cell_data: PoolIntArray = PoolIntArray()
	var repititions_count: int
	var compressed_data: Array = []
	for y in range(used_rect.position.y, used_rect.end.y):
		for x in range(used_rect.position.x, used_rect.end.x):
			var cell = Vector2(x, y)
			var cell_data: PoolIntArray = Common.get_map_cell_data(pattern.__map, cell)
			print(cell_data)
			if cell_data == previous_cell_data:
				compressed_data[compressed_data.size() - 1] += 1
			else:
				compressed_data.append_array(cell_data)
				compressed_data.append(1)
				previous_cell_data = cell_data
	prints(pattern.size, pattern.used_cells_count, pattern.half_offset_orientation)
	return to_json({
		size = Serialization.serialize(pattern.size),
		used_cells_count = pattern.used_cells_count,
		half_offset_orientation = pattern.half_offset_orientation,
		compressed_data = compressed_data
	})

static func deserialize(serialized_data: String) -> Pattern:
	print("deserialize")
	var data = parse_json(serialized_data)
	print(data)
	var pattern: Pattern = Pattern.new(data.half_offset_orientation)
	pattern.size = Serialization.deserialize(data.size, TYPE_VECTOR2)
	pattern.used_cells_count = data.used_cells_count
	pattern.half_offset_orientation = data.half_offset_orientation
	var x: int
	var y: int
	var d: PoolIntArray = PoolIntArray([0, 0, 0, 0])
	for i in range(0, data.compressed_data.size(), 5):
		d[0] = data.compressed_data[i]
		d[1] = data.compressed_data[i + 1]
		d[2] = data.compressed_data[i + 2]
		d[3] = data.compressed_data[i + 3]
		for r in data.compressed_data[i + 4]:
			print(d)
			Common.set_map_cell_data(pattern.__map, Vector2(x, y), d)
			x += 1
			if x >= pattern.size.x:
				x = 0
				y += 1
	prints(pattern.size, pattern.used_cells_count, pattern.half_offset_orientation)
	return pattern
