extends "_base.gd"

var __filled: bool

func _init(brush: Brush, paper_holder: Common.ValueHolder, filled: bool).(brush, paper_holder) -> void:
	__filled = filled

func _after_pushed() -> void:
	_brush.paint(_origin_cell, _paper_holder.value)

#func _before_pulled() -> void:
#	pass

func _on_moved() -> void:
	if _is_pushed:
		var paper = _paper_holder.value
		paper.reset_changes()
		var s = (_position_cell - _origin_cell).sign()
		if s.x == 0: s.x = 1
		if s.y == 0: s.y = 1
		if __filled:
			for y in range(_origin_cell.y, _position_cell.y + s.y, s.y):
				for x in range(_origin_cell.x, _position_cell.x + s.x, s.x):
					_brush.paint(Vector2(x, y), paper)
		else:
			for x in range(_origin_cell.x, _position_cell.x, s.x):
				_brush.paint(Vector2(x, _origin_cell.y), paper)
			for y in range(_origin_cell.y, _position_cell.y, s.y):
				_brush.paint(Vector2(_position_cell.x, y), paper)
			for x in range(_position_cell.x, _origin_cell.x, -s.x):
				_brush.paint(Vector2(x, _position_cell.y), paper)
			for y in range(_position_cell.y, _origin_cell.y, -s.y):
				_brush.paint(Vector2(_origin_cell.x, y), paper)

func _on_draw(overlay: Control) -> void:
	if _is_pushed:
		var half_offset = _paper_holder.value.get_half_offset()
		var s = (_position_cell - _origin_cell).sign()
		if s == Vector2.ZERO:
			_brush.draw(_origin_cell, overlay, half_offset)
		if s.x == 0:
			for y in range(_origin_cell.y, _position_cell.y + s.y, s.y):
				_brush.draw(Vector2(_origin_cell.x, y), overlay, half_offset)
		elif s.y == 0:
			for x in range(_origin_cell.x, _position_cell.x + s.x, s.x):
				_brush.draw(Vector2(x, _origin_cell.y), overlay, half_offset)
		else:
			for x in range(_origin_cell.x, _position_cell.x + s.x, s.x):
				_brush.draw(Vector2(x, _origin_cell.y), overlay, half_offset)
				_brush.draw(Vector2(x, _position_cell.y), overlay, half_offset)
			for y in range(_origin_cell.y + s.y, _position_cell.y, s.y):
				_brush.draw(Vector2(_origin_cell.x, y), overlay, half_offset)
				_brush.draw(Vector2(_position_cell.x, y), overlay, half_offset)
