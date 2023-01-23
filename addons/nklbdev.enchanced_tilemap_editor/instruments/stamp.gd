extends "_base.gd"

const Iterators = preload("../iterators.gd")
const Algorithms = preload("../algorithms.gd")

var __line: PoolVector2Array = PoolVector2Array([Vector2.ZERO])

func _init(pattern_holder: Common.ValueHolder, paper: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(pattern_holder, paper, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	pass


func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	pass
func _before_pulled() -> void:
	pass
func _after_pulled() -> void:
	__line = [Vector2.ZERO]
func _before_interrupted() -> void:
	pass
func _after_interrupted() -> void:
	pass
func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	if _is_pushed:
		if not _pattern or _pattern.size == Vector2.ONE:
			var from_map_cell: Vector2 = _ruler_grid_map.world_to_map(from_position - _pattern_grid_origin_map_cell_position)
			var to_map_cell: Vector2 = _ruler_grid_map.world_to_map(_position - _pattern_grid_origin_map_cell_position)
			if from_map_cell != to_map_cell:
				__line = Algorithms.get_line(from_map_cell, to_map_cell, _ruler_grid_map.cell_half_offset)
				paint()
		else:
			if previous_pattern_grid_position_cell != _pattern_grid_position_cell:
				__line = Iterators.line(previous_pattern_grid_position_cell, _pattern_grid_position_cell).to_array()
				# skip first cell
				paint()
	else:
		__line[0] = Vector2.ZERO

func _on_paint() -> void:
	if not _pattern:
		return
	for cell in __line:
		paint_pattern_at(cell)

func _on_draw(overlay: Control) -> void:
	if not _is_pushed:
		return
	for cell in __line:
		draw_pattern_hint_at(overlay, cell)
