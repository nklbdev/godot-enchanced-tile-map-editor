extends "_base.gd"

var __sample_cell_data: PoolIntArray
var __start_filling_cell: Vector2
var __start_filling_cell_position: Vector2
var __paper_to_pick: Paper

func _init(pattern_holder: Common.ValueHolder, paper_to_paint: Paper, paper_to_pick: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(pattern_holder, paper_to_paint, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	__paper_to_pick = paper_to_pick
	pass

func _before_pushed() -> void:
	__start_filling_cell = _ruler_grid_map.world_to_map(_origin)
	__start_filling_cell_position = _ruler_grid_map.map_to_world(__start_filling_cell)
	__sample_cell_data = __paper_to_pick.get_map_cell_data(__start_filling_cell)
func _after_pushed() -> void:
	# TODO fill on ruler_grid_map
	# TODO implement half-offset processing
	_paper.reset_changes()
	if can_paint_at(__start_filling_cell):
		_ruler_grid_map.set_cellv(__start_filling_cell, 0)
	else:
		return
	var offset_type: Common.CellHalfOffsetType = _ruler_grid_map.cell_half_offset_type
	var cell_queue: Array
	cell_queue.append(__start_filling_cell)

	var upper_trigger: bool
	var lower_trigger: bool
	var temp_trigger_value: bool

	while not cell_queue.empty():
		var cell: Vector2 = cell_queue.pop_front() as Vector2
		var start: int = offset_type.get_column(cell)
		# quickly walk left to the wall
		while true:
			cell -= offset_type.line_direction
			if not __can_fill(cell):
				break
		# walk right to other wall with paint and two triggers
		upper_trigger = false
		lower_trigger = false
		var trigger_cell: Vector2
		while true:
			cell += offset_type.line_direction
			# skip passed cells checking
			if offset_type.get_column(cell) > start and not __can_fill(cell):
				break

			_ruler_grid_map.set_cellv(cell, 0)

			temp_trigger_value = upper_trigger
			trigger_cell = cell - offset_type.column_direction
			upper_trigger = __can_fill(trigger_cell)
			if upper_trigger and not temp_trigger_value:
				cell_queue.push_back(trigger_cell)

			temp_trigger_value = lower_trigger
			trigger_cell = cell + offset_type.column_direction
			lower_trigger = __can_fill(trigger_cell)
			if lower_trigger and not temp_trigger_value:
				cell_queue.push_back(trigger_cell)

func _before_pulled(force: bool) -> void:
	pass
func _after_pulled(force: bool) -> void:
	pass


func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	var previous_origin = _origin
	_set_origin(_position)
	# TODO refill ruler_grid_map filled area on tile_map
	if _origin != previous_origin:
		paint()

func __can_fill(cell: Vector2) -> bool:
	return _ruler_grid_map.get_cellv(cell) == TileMap.INVALID_CELL and \
		__sample_cell_data == __paper_to_pick.get_map_cell_data(cell) and \
		can_paint_at(cell) and \
		__paper_to_pick.get_used_rect().has_point(cell)

func _on_paint() -> void:
	# TODO implement half-offset processing
	_paper.reset_changes()
	for cell in _ruler_grid_map.get_used_cells():
		paint_pattern_cell_at(cell)

func _on_draw(overlay: Control) -> void:
#	if not _is_pushed:
		return
