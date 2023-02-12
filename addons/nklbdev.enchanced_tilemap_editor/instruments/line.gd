extends "_single.gd"

const Iterators = preload("../iterators.gd")
const Algorithms = preload("../algorithms.gd")

var __line: PoolVector2Array = PoolVector2Array([Vector2.ZERO])

func _init(paper: Paper, pattern_layout_map: PatternLayoutMap, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(paper, pattern_layout_map, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	pass


func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	pass
func _before_pulled(force: bool) -> void:
	pass
func _after_pulled(force: bool) -> void:
	__line = [Vector2.ZERO]

func _on_moved(previous_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	if _is_pushed:
		if _pattern_layout_map.pattern_size == Vector2.ONE:
			var position_map_cell: Vector2 = _pattern_layout_map.world_to_map(_position)
			var previous_position_map_cell: Vector2 = _pattern_layout_map.world_to_map(previous_position)
			if position_map_cell != previous_position_map_cell:
				__line = Algorithms.get_line(_pattern_grid_origin_map_cell, _pattern_grid_position_map_cell, _pattern_layout_map.cell_half_offset)
				paint()
		else:
			if previous_pattern_grid_position_cell != _pattern_grid_position_cell:
				__line = Iterators.line(Vector2.ZERO, _pattern_grid_position_cell).to_array()
				paint()

func _on_paint() -> void:
	_paper.reset_changes()
	if _pattern_layout_map.pattern_size == Vector2.ONE:
		for cell in __line:
			paint_pattern_at(cell - _pattern_grid_origin_map_cell)
	else:
		for cell in __line:
			paint_pattern_at(cell)

func _on_draw(overlay: Control) -> void:
	if not _is_pushed:
		return
	if _pattern_layout_map.pattern_size == Vector2.ONE:
		for cell in __line:
			draw_pattern_hint_at(overlay, cell - _pattern_grid_origin_map_cell)
	else:
		for cell in __line:
			draw_pattern_hint_at(overlay, cell)
