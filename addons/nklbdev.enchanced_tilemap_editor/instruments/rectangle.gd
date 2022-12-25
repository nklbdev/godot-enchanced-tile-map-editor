extends "_base.gd"

var __filled: bool

func _init(brush: Brush, filled: bool, drawing_settings: Common.DrawingSettings).(brush, drawing_settings) -> void:
	__filled = filled

func _after_pushed() -> void:
	_brush.paint(_origin_cell)

#func _before_pulled() -> void:
#	pass

func _on_moved() -> void:
	if _is_pushed:
		_paper.reset_changes()
		var s = (_cell - _origin_cell).sign()
		if s.x == 0: s.x = 1
		if s.y == 0: s.y = 1
		if __filled:
			for y in range(_origin_cell.y, _cell.y + s.y, s.y):
				for x in range(_origin_cell.x, _cell.x + s.y, s.x):
					_brush.paint(Vector2(x, y))
		else:
			for x in range(_origin_cell.x, _cell.x, s.x):
				_brush.paint(Vector2(x, _origin_cell.y))
			for y in range(_origin_cell.y, _cell.y, s.y):
				_brush.paint(Vector2(_cell.x, y))
			for x in range(_cell.x, _origin_cell.x, -s.x):
				_brush.paint(Vector2(x, _cell.y))
			for y in range(_cell.y, _origin_cell.y, -s.y):
				_brush.paint(Vector2(_origin_cell.x, y))

func _on_draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	if _is_pushed:
		var color = _drawing_settings.drawn_cells_color
		var s = (_cell - _origin_cell).sign()
		if s == Vector2.ZERO:
			overlay.draw_rect(_paper.get_cell_world_rect(_origin_cell), color)
		if s.x == 0:
			for y in range(_origin_cell.y, _cell.y + s.y, s.y):
				overlay.draw_rect(_paper.get_cell_world_rect(Vector2(_origin_cell.x, y)), color)
		elif s.y == 0:
			for x in range(_origin_cell.x, _cell.x + s.x, s.x):
				overlay.draw_rect(_paper.get_cell_world_rect(Vector2(x, _origin_cell.y)), color)
		else:
			for x in range(_origin_cell.x, _cell.x + s.x, s.x):
				overlay.draw_rect(_paper.get_cell_world_rect(Vector2(x, _origin_cell.y)), color)
				overlay.draw_rect(_paper.get_cell_world_rect(Vector2(x, _cell.y)), color)
			for y in range(_origin_cell.y + s.y, _cell.y, s.y):
				overlay.draw_rect(_paper.get_cell_world_rect(Vector2(_origin_cell.x, y)), color)
				overlay.draw_rect(_paper.get_cell_world_rect(Vector2(_cell.x, y)), color)
