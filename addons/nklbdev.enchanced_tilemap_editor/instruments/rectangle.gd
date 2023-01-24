extends "_base.gd"

var __size: Vector2

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
	__size = Vector2.ZERO
	pass


func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	if previous_pattern_grid_position_cell != _pattern_grid_position_cell:
		var size: Vector2 = _pattern_grid_position_cell
		if size == Vector2.ZERO:
			pass
		elif size.x == 0:
			size.y = floor(min(_drawing_area_limit / _pattern.used_cells_count, abs(size.y))) * sign(size.y)
		elif size.y == 0:
			size.x = floor(min(_drawing_area_limit / _pattern.used_cells_count, abs(size.x))) * sign(size.x)
		else:
			size = Common.limit_area(size, _drawing_area_limit).floor()
		if size != __size:
			__size = size
			paint()

func _on_paint() -> void:
	_paper.reset_changes()
	if __size == Vector2.ZERO:
		paint_pattern_at(Vector2.ZERO)
	else:
		var s = __size.sign()
		if __size.x == 0:
			for y in range(0, __size.y + s.y, s.y):
				paint_pattern_at(Vector2(0, y))
		elif __size.y == 0:
			for x in range(0, __size.x + s.x, s.x):
				paint_pattern_at(Vector2(x, 0))
		else:
			for y in range(0, __size.y + s.y, s.y):
				for x in range(0, __size.x + s.x, s.x):
					paint_pattern_at(Vector2(x, y))

func _on_draw(overlay: Control) -> void:
	if not _is_pushed:
		return
	if __size == Vector2.ZERO:
		draw_pattern_hint_at(overlay, Vector2.ZERO)
	else:
		var s = __size.sign()
		if __size.x == 0:
			for y in range(0, __size.y + s.y, s.y):
				draw_pattern_hint_at(overlay, Vector2(0, y))
		elif __size.y == 0:
			for x in range(0, __size.x + s.x, s.x):
				draw_pattern_hint_at(overlay, Vector2(x, 0))
		else:
			for x in range(0, __size.x, s.x):
				draw_pattern_hint_at(overlay, Vector2(x, 0))
			for y in range(0, __size.y, s.y):
				draw_pattern_hint_at(overlay, Vector2(__size.x, y))
			for x in range(__size.x, 0, -s.x):
				draw_pattern_hint_at(overlay, Vector2(x, __size.y))
			for y in range(__size.y, 0, -s.y):
				draw_pattern_hint_at(overlay, Vector2(0, y))
