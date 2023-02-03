extends "_single.gd"

const Iterators = preload("../../iterators.gd")
const Algorithms = preload("../../algorithms.gd")

var __line: PoolVector2Array = PoolVector2Array([Vector2.ZERO])

func _init(pattern_holder: Common.ValueHolder, paper: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(pattern_holder, paper, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	pass


func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	pass
func _before_pulled(force: bool) -> void:
	pass
func _after_pulled(force: bool) -> void:
	__line = [Vector2.ZERO]

func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	if _is_pushed:
		if previous_pattern_grid_position_cell != _pattern_grid_position_cell:
			if not _pattern or _pattern.size == Vector2.ONE:
				__line = Algorithms.get_line(_pattern_grid_origin_map_cell, _pattern_grid_position_map_cell, _ruler_grid_map.cell_half_offset)
			else:
				__line = Iterators.line(Vector2.ZERO, _pattern_grid_position_cell).to_array()
			paint()
	else:
		__line[0] = _pattern_grid_origin_map_cell if not _pattern or _pattern.size == Vector2.ONE else Vector2.ZERO

func _on_paint() -> void:
	_paper.reset_changes()
	if not _pattern:
		return
	if _pattern.size == Vector2.ONE:
		var origin = _origin
		for cell in __line:
			_set_origin(_ruler_grid_map.map_to_world(cell))
			paint_pattern_at(Vector2.ZERO)
		_set_origin(origin)
	else:
		for cell in __line:
			paint_pattern_at(cell)

var clr = Color.red * Color(1, 1, 1, 0.25)
func _on_draw(overlay: Control) -> void:
	if not _is_pushed:
		return
	if not _pattern or _pattern.size == Vector2.ONE:
		var origin = _origin
		for cell in __line:
			_set_origin(_ruler_grid_map.map_to_world(cell))
			draw_pattern_hint_at(overlay, Vector2.ZERO)
		_set_origin(origin)
	else:
		for cell in __line:
			draw_pattern_hint_at(overlay, cell)
