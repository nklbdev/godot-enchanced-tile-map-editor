extends "_base.gd"

# флудфилл при нажатии определяет точку начала заливки и начало паттерна,
# а при движении меняет ориджин

var __sample_cell_data: PoolIntArray
var __start_filling_cell: Vector2
var __start_filling_cell_position: Vector2

func _init(pattern_holder: Common.ValueHolder, paper: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(pattern_holder, paper, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	pass

func _before_pushed() -> void:
	__start_filling_cell = _ruler_grid_map.world_to_map(_origin)
	__start_filling_cell_position = _ruler_grid_map.map_to_world(__start_filling_cell)
	__sample_cell_data = _paper.get_map_cell_data(__start_filling_cell)
func _after_pushed() -> void:
	pass
func _before_pulled() -> void:
	pass
func _after_pulled() -> void:
	pass
func _before_interrupted() -> void:
	pass
func _after_interrupted() -> void:
	pass

func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	var previous_origin = _origin
	_set_origin(_position)
	if _origin != previous_origin:
		paint()

func _on_paint() -> void:
	_paper.reset_changes()
	var not_selected = not _selection_map or _selection_map.get_used_rect().has_no_area()
	if not_selected or _selection_map.get_cellv(__start_filling_cell) != TileMap.INVALID_CELL:
		paint_pattern_cell_at(__start_filling_cell)
	else:
		return
	var used_rect: Rect2 = _paper.get_used_rect()

	var position: Vector2 = __start_filling_cell
	
	_cell_half_offset_axis
	_cell_half_offset_sign
	_is_cell_half_offset_horizontal

	var cell_queue: Array
	cell_queue.append(position)

	var upper_trigger: bool
	var lower_trigger: bool
	var temp_trigger_value: bool

	var triggers = [false, false]
	while not cell_queue.empty():
		var cell = cell_queue.pop_front()
		var start = cell * _cell_half_offset_axis
		# quickly walk left to the wall
		while true:
			cell -= _cell_half_offset_axis
			if not (__sample_cell_data == _paper.get_map_cell_data(cell) and
				(not_selected or _selection_map.get_cellv(cell) != TileMap.INVALID_CELL) and
				used_rect.has_point(cell)):
				break
		# walk right to other wall with paint and two triggers
		upper_trigger = false
		lower_trigger = false
		var trigger_cell: Vector2
		while true:
			cell += _cell_half_offset_axis
			# skip passed cells checking
			if cell * _cell_half_offset_axis > start and not (__sample_cell_data == _paper.get_map_cell_data(cell) and
				(not_selected or _selection_map.get_cellv(cell) != TileMap.INVALID_CELL) and
				used_rect.has_point(cell)):
				break

			paint_pattern_cell_at(cell)

			temp_trigger_value = upper_trigger
			trigger_cell = (cell - _line_number_ascending_direction)
			upper_trigger = (__sample_cell_data == _paper.get_map_cell_data(trigger_cell) and
				(not_selected or _selection_map.get_cellv(trigger_cell) != TileMap.INVALID_CELL) and
				used_rect.has_point(cell))
			if upper_trigger and not temp_trigger_value:
				cell_queue.append(trigger_cell)

			temp_trigger_value = lower_trigger
			trigger_cell = (cell + _line_number_ascending_direction)
			lower_trigger = (__sample_cell_data == _paper.get_map_cell_data(trigger_cell) and
				(not_selected or _selection_map.get_cellv(trigger_cell) != TileMap.INVALID_CELL) and
				used_rect.has_point(cell))
			if lower_trigger and not temp_trigger_value:
				cell_queue.append(trigger_cell)

func _on_draw(overlay: Control) -> void:
	if not _is_pushed:
		return
#	if __size == Vector2.ZERO:
#		draw_pattern_hint_at(overlay, Vector2.ZERO)
#	else:
#		var s = __size.sign()
#		if __size.x == 0:
#			for y in range(0, __size.y + s.y, s.y):
#				draw_pattern_hint_at(overlay, Vector2(0, y))
#		elif __size.y == 0:
#			for x in range(0, __size.x + s.x, s.x):
#				draw_pattern_hint_at(overlay, Vector2(x, 0))
#		else:
#			for x in range(0, __size.x, s.x):
#				draw_pattern_hint_at(overlay, Vector2(x, 0))
#			for y in range(0, __size.y, s.y):
#				draw_pattern_hint_at(overlay, Vector2(__size.x, y))
#			for x in range(__size.x, 0, -s.x):
#				draw_pattern_hint_at(overlay, Vector2(x, __size.y))
#			for y in range(__size.y, 0, -s.y):
#				draw_pattern_hint_at(overlay, Vector2(0, y))



