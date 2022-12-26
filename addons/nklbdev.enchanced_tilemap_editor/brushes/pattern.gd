extends "_base.gd"

var pattern: Common.Pattern

func _init(drawing_settings: Common.DrawingSettings, pattern: Common.Pattern = null).(drawing_settings) -> void:
	self.pattern = pattern




func _paint_hex_cell(hex_cell: Vector2, paper: Paper) -> void:
	if pattern != null:
		var map_cell = _get_map_cell(hex_cell / 4, paper.get_half_offset())
		paper.set_map_cell_data(map_cell, pattern.get_map_cell_data(map_cell))

func _paint_tet_cell(tet_cell: Vector2, paper: Paper) -> void:
	if pattern != null:
		var origin_hex_cell = tet_cell * 2 - Vector2.ONE
		_paint_hex_cell(origin_hex_cell, paper)
		_paint_hex_cell(origin_hex_cell + Vector2.RIGHT, paper)
		_paint_hex_cell(origin_hex_cell + Vector2.ONE, paper)
		_paint_hex_cell(origin_hex_cell + Vector2.DOWN, paper)

func _paint_map_cell(map_cell: Vector2, paper: Paper) -> void:
	if pattern != null:
		paper.set_map_cell_data(map_cell, pattern.get_map_cell_data(map_cell))

func _paint_pat_cell(pat_cell: Vector2, paper: Paper) -> void:
	if pattern != null:
		var pattern_origin_map_cell = pattern.offset + pattern.size * pat_cell
		for y in pattern.size.y: for x in pattern.size.x:
			var addr = (x + y * pattern.size.x) * 4
			paper.set_map_cell_data(pattern_origin_map_cell + Vector2(x, y), pattern.data.slice(addr, addr + 4))


func _get_pat_cell(world_position: Vector2, half_offset: int) -> Vector2:
	return Vector2.ZERO if pattern == null else ((_get_map_cell(world_position, half_offset) - pattern.offset) / pattern.size).floor()



func _draw_pat_cell(cell: Vector2, overlay: Control, half_offset: int) -> void:
	if pattern != null:
		var pattern_origin_map_cell = pattern.offset + pattern.size * cell
		for y in pattern.size.y: for x in pattern.size.x:
			var c = pattern_origin_map_cell + Vector2(x, y)
			overlay.draw_rect(Rect2(c + Common.get_half_offset(c, half_offset), Vector2.ONE), _drawing_settings.drawn_cells_color)










#
#func paint(cell: Vector2, paper: Paper) -> void:
#	if pattern == null:
#		return
#	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
#	# порядкового номера (идентификатора?) рисовательного действия и координат
#	var sections = paper.get_sections_in_cell(cell)
##	sections.sort()
##	var previous_section: Vector3 = Vector3(0, 0, -1)
#	for section in sections:
##		if section != previous_section:
#		var map_cell = Vector2(section.x, section.y)
#		var pattern_start_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
##			previous_section = section
#
##			_paper.set_map_cell_data(map_cell, __pattern_holder.value.get_map_cell_data(map_cell))
#		for y in pattern.size.y: for x in pattern.size.x:
#			var addr = (x + y * pattern.size.x) * 4
#			paper.set_map_cell_data(pattern_start_map_cell + Vector2(x, y), pattern.data.slice(addr, addr + 4))
##		var pattern_position_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
#
#
#
#
#func _paint_hex_cell(world_position: Vector2, paper) -> void:
#	if pattern == null:
#		return
#	var map_cell = world_position
#	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
#	# порядкового номера (идентификатора?) рисовательного действия и координат
#	var sections = paper.get_sections_in_cell(cell)
##	sections.sort()
##	var previous_section: Vector3 = Vector3(0, 0, -1)
#	for section in sections:
##		if section != previous_section:
#		var map_cell = Vector2(section.x, section.y)
#		var pattern_start_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
##			previous_section = section
#
##			_paper.set_map_cell_data(map_cell, __pattern_holder.value.get_map_cell_data(map_cell))
#		for y in pattern.size.y: for x in pattern.size.x:
#			var addr = (x + y * pattern.size.x) * 4
#			paper.set_map_cell_data(pattern_start_map_cell + Vector2(x, y), pattern.data.slice(addr, addr + 4))
##		var pattern_position_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
#
#func _paint_tet_cell(world_position: Vector2, paper) -> void:
#	assert(false)
#
#func _paint_map_cell(world_position: Vector2, paper) -> void:
#	assert(false)
#
#func _paint_pat_cell(world_position: Vector2, paper) -> void:
#	assert(false)
#
#func _get_pattern_cell(world_position: Vector2, half_offset: int) -> Vector2:
#	assert(false)
#	return Vector2.ZERO
#
#func _draw_pattern_cell(cell: Vector2, overlay: Control, half_offset: int) -> void:
#	if pattern == null:
#		return
#	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
#	# порядкового номера (идентификатора?) рисовательного действия и координат
#	var sections = paper.get_sections_in_cell(cell)
##	sections.sort()
##	var previous_section: Vector3 = Vector3(0, 0, -1)
#	for section in sections:
##		if section != previous_section:
#		var map_cell = Vector2(section.x, section.y)
#		var pattern_start_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
##			previous_section = section
#
##			_paper.set_map_cell_data(map_cell, __pattern_holder.value.get_map_cell_data(map_cell))
#		for y in pattern.size.y: for x in pattern.size.x:
#			var addr = (x + y * pattern.size.x) * 4
#			paper.set_map_cell_data(pattern_start_map_cell + Vector2(x, y), pattern.data.slice(addr, addr + 4))
##		var pattern_position_map_cell = map_cell - (map_cell - pattern.offset).posmodv(pattern.size)
#
#




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
