extends "_base.gd"

var __pattern_holder: Common.ValueHolder

func _init(pattern_holder: Common.ValueHolder, drawing_settings: Common.DrawingSettings).(drawing_settings) -> void:
	__pattern_holder = pattern_holder
	__pattern_holder.connect("value_changed", self, "__on_pattern_holder_value_changed")
	pass

# 0 - tile_id
# 1 - transform
# 2 - autotile_coord.x
# 3 - autotile_coord.y
func paint(cell: Vector2) -> void:
	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
	# порядкового номера (идентификатора?) рисовательного действия и координат
	var pattern = __pattern_holder.value as Common.Pattern
	var sections = _paper.get_sections_in_cell(cell)
#	sections.sort()
#	var previous_section: Vector3 = Vector3(0, 0, -1)
	for section in sections:
#		if section != previous_section:
		var map_cell = Vector2(section.x, section.y)
		var pattern_start_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
#			previous_section = section
			
#			_paper.set_map_cell_data(map_cell, __pattern_holder.value.get_map_cell_data(map_cell))
		for y in pattern.size.y: for x in pattern.size.x:
			var addr = (x + y * pattern.size.x) * 4
			_paper.set_map_cell_data(pattern_start_map_cell + Vector2(x, y), pattern.data.slice(addr, addr + 4))
#		var pattern_position_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
		


func __on_pattern_holder_value_changed() -> void:
	pass



#var __pattern_size: Vector2
#var __pattern_offset: Vector2
#var __pattern_transform_flags: int
#var __pattern_data: PoolIntArray # tile_id, transform_flags, subtile_coord.x, subtile_coord_y
#
#func set_pattern(size: Vector2, data: PoolIntArray) -> void:
#	assert(size.x > 0 and size.y > 0)
#	assert(data.size() == size.x * size.y * 4)
#	__pattern_size = size
#	__pattern_data = data
#
#var __temp_map_cell_data: PoolIntArray = PoolIntArray([0, 0, 0, 0])
#func get_map_cell_data(map_cell: Vector2) -> PoolIntArray:
#	var internal_map_cell = (map_cell - __pattern_offset).posmodv(__pattern_size)
#	var data_address = (internal_map_cell.x + internal_map_cell.y * __pattern_size.x) * 4
#	for data_offset in 4:
#		__temp_map_cell_data[data_offset] = __pattern_data[data_address + data_offset]
#	return __temp_map_cell_data
