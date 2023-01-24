extends Object

const Serialization = preload("serialization.gd")

class Pattern:
	const Common = preload("common.gd")
	const Paper = preload("paper.gd")
		
	# если паттерн накладывается на карту со смещениями, то подразумевается,
	# что в паттерне смещение всегда положительное
	var size: Vector2
	var used_cells_count: int
	# data
	# 0 - tile_id
	# 1 - transform
	# 2 - autotile_coord.x
	# 3 - autotile_coord.y
	var data: PoolIntArray
	const __data_size: int =  4

	func _init(size: Vector2, data: PoolIntArray) -> void:
		assert(size.x * size.y * 4 == data.size())
		self.size = size
		self.data = data
		for i in range(0, data.size(), 4):
			if data[i] >= 0:
				used_cells_count += 1

	# паттерн можно повернуть на 90 градусов только если cell_half_offset == disabled
	# для шестиугольников можно было бы поворачивать на 60 градусов. Но нельзя будет повернуть сами текстуры
	# у паттерна должно быть смещение точно такое, как у бумаги
	signal changed()
	func flip() -> void:
		pass
	func rotate() -> void:
		pass

	const __map_cell_data_to_return: PoolIntArray = PoolIntArray([0, 0, 0, 0])
	func get_cell_data(cell: Vector2) -> PoolIntArray:
		cell = cell.posmodv(size)
		var data_idx = (cell.x + cell.y * size.x) * 4
		__map_cell_data_to_return[0] = data[data_idx]
		__map_cell_data_to_return[1] = data[data_idx + 1]
		__map_cell_data_to_return[2] = data[data_idx + 2]
		__map_cell_data_to_return[3] = data[data_idx + 3]
		return __map_cell_data_to_return

	func get_origin_map_cell(world_position: Vector2, ruler_grid_map: Paper.RulerGridMap) -> Vector2:
		var linear_size: Vector2 = ruler_grid_map.cell_half_offset_type.conv(size)
		return ruler_grid_map.world_to_map(
			world_position + ruler_grid_map.cell_half_offset_type.conv(
				(Vector2.ONE - linear_size + Vector2.RIGHT *
				((int(linear_size.y > 1) + (int(linear_size.y) & 1)) * ruler_grid_map.cell_half_offset_type.offset)) / 2))

const __TYPE_MAP: Dictionary = {
	size = TYPE_VECTOR2,
	data = TYPE_INT_ARRAY,
}

static func serialize(pattern: Pattern) -> String:
	var d = to_json(Serialization.serialize_object(pattern, __TYPE_MAP.keys()))
	print(d)
	return d

static func deserialize(serialized_data: String) -> Pattern:
	var data: Dictionary = Serialization.deserialize_dictionary_by_type_map(parse_json(serialized_data), __TYPE_MAP)
	return Pattern.new(data.size, data.data)
