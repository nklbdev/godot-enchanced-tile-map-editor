extends "_single.gd"

const Iterators = preload("../iterators.gd")
const Algorithms = preload("../algorithms.gd")

var __line: PoolVector2Array = PoolVector2Array([Vector2.ZERO])
var __painted_cells: Dictionary

func _init(pattern_holder: Common.ValueHolder, paper: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(pattern_holder, paper, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	pass


func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	if _pattern_size:
		__line.append(_ruler_grid_map.world_to_map(_position) if _pattern_size == Vector2.ONE else Vector2.ZERO)
		paint()

func _before_pulled(force: bool) -> void:
	pass
func _after_pulled(force: bool) -> void:
	__painted_cells.clear()
	__line.resize(0)

func _on_moved(previous_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	if _is_pushed:
		if _pattern_size:
			if _pattern_size == Vector2.ONE:
				var position_map_cell: Vector2 = _ruler_grid_map.world_to_map(_position)
				var previous_position_map_cell: Vector2 = _ruler_grid_map.world_to_map(previous_position)
				if position_map_cell != previous_position_map_cell:
					__line = Algorithms.get_line(previous_position_map_cell, position_map_cell, _ruler_grid_map.cell_half_offset)
					paint()
			else:
				if previous_pattern_grid_position_cell != _pattern_grid_position_cell:
					__line = Iterators.line(previous_pattern_grid_position_cell, _pattern_grid_position_cell).to_array()
					paint()

func _on_paint() -> void:
	if _pattern_size:
		if _pattern_size == Vector2.ONE:
			for cell in __line:
				paint_pattern_at(cell - _pattern_grid_origin_map_cell)
				__painted_cells[cell - _pattern_grid_origin_map_cell] = true
		else:
			for cell in __line:
				paint_pattern_at(cell)
				__painted_cells[cell] = true

func _on_draw(overlay: Control) -> void:
	if not _is_pushed:
		return
	if _pattern_size:
		for cell in __painted_cells.keys():
			draw_pattern_hint_at(overlay, cell)
