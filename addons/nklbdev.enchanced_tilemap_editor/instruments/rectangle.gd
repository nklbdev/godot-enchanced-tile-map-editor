extends "_base.gd"

var __filled: bool

func _init(brush: Brush, paper: Paper, filled: bool).(brush, paper) -> void:
	__filled = filled

func _after_pushed() -> void:
	_brush.paint(_origin_cell, _paper)

#func _before_pulled() -> void:
#	pass
#func paint_abs_rect(rect: Rect2) -> void:
#	for y in range(rect.position.y, rect.end.y):
#		for x in range(rect.position.x, rect.end.x):
#			assert(not _paper.is_cell_changed(Vector2(x, y)))
#			_brush.paint(Vector2(x, y), _paper)
#
#func reset_abs_rect(rect: Rect2) -> void:
#	for y in range(rect.position.y, rect.end.y):
#		for x in range(rect.position.x, rect.end.x):
#			assert(not _paper.is_cell_changed(Vector2(x, y)))
#			_paper.reset_cell(Vector2(x, y))

#func __paint_rect(rect: Rect2, reset: bool = false) -> void:
##	print("__paint_rect(%s, %s)" % [rect, reset])
##	var size_sign = rect.size.sign()
##	for y in range(rect.position.y, rect.end.y + size_sign.y, 1 if size_sign.y == 0 else size_sign.y):
##		for x in range(rect.position.x, rect.end.x + size_sign.x, 1 if size_sign.x == 0 else size_sign.x):
##			_brush.paint(Vector2(x, y), _paper, reset)
##	print("%s: %s" % ["reset" if reset else "paint", rect])
#	var a = rect.abs()
#	for y in range(a.position.y, a.end.y + 1):
#		for x in range(a.position.x, a.end.x + 1):
#			_brush.paint(Vector2(x, y), _paper, reset)

func _on_moved(from_position: Vector2, from_cell: Vector2) -> void:
	if not _is_pushed:
		return

#	var old_size: Vector2 = from_cell - _origin_cell
#	var new_size: Vector2 = _position_cell - _origin_cell
#	if old_size.x * new_size.x < 0 or old_size.y * new_size.y < 0:
#		# прямоугольник "вывернулся" по одной или двум осям
#		__paint_rect(Rect2(_origin_cell, old_size), true) # _paper.reset_changes()
#		__paint_rect(Rect2(_origin_cell, new_size))
#	else:
#		var growth: Vector2 = new_size - old_size # _position_cell - from_cell
#		var a = old_size * growth
#		# Прямоугольник:
#		if a.x < 0 and a.y < 0: # уменьшился по обеим осям
#			# стереть
##			print("width height")
#			# стереть право и угол
#			__paint_rect(Rect2(from_cell.x, _origin_cell.y, growth.x, old_size.y), true)
#			# стереть низ
#			__paint_rect(Rect2(_origin_cell.x, from_cell.y, new_size.x, growth.y), true)
#		elif a.x < 0: # сузился и, возможно, стал выше
##			print("width HEIGHT")
#			# стереть право и угол
#			__paint_rect(Rect2(from_cell.x, _origin_cell.y, growth.x, old_size.y), true)
#			# продолжить низ
#			__paint_rect(Rect2(_origin_cell.x, from_cell.y, new_size.x, growth.y))
#		elif a.y < 0: # стал ниже и, возможно, шире
##			print("WIDTH height")
#			# стереть низ и угол
#			__paint_rect(Rect2(_origin_cell.x, from_cell.y, old_size.x, growth.y), true)
#			# продолжить право
#			__paint_rect(Rect2(from_cell.x, _origin_cell.y, growth.x, new_size.y))
#		else: # возможно, увеличился по обеим осям
##			print("WIDTH HEIGHT")
#			# продолжить право
#			__paint_rect(Rect2(from_cell.x, _origin_cell.y, growth.x, old_size.y))
#			# продолжить низ и угол
#			__paint_rect(Rect2(_origin_cell.x, from_cell.y, new_size.x, growth.y))

	_paper.reset_changes()
	var s = (_position_cell - _origin_cell).sign()
	if s.x == 0: s.x = 1
	if s.y == 0: s.y = 1
#	if __filled:
#		for y in range(_origin_cell.y, _position_cell.y + s.y, s.y):
#			for x in range(_origin_cell.x, _position_cell.x + s.x, s.x):
#				_brush.paint(Vector2(x, y), _paper)
#	else:
	for x in range(_origin_cell.x, _position_cell.x, s.x):
		_brush.paint(Vector2(x, _origin_cell.y), _paper)
	for y in range(_origin_cell.y, _position_cell.y, s.y):
		_brush.paint(Vector2(_position_cell.x, y), _paper)
	for x in range(_position_cell.x, _origin_cell.x, -s.x):
		_brush.paint(Vector2(x, _position_cell.y), _paper)
	for y in range(_position_cell.y, _origin_cell.y, -s.y):
		_brush.paint(Vector2(_origin_cell.x, y), _paper)

func _before_pulled() -> void:
	var s = (_position_cell - _origin_cell).sign()
	if s.x == 0: s.x = 1
	if s.y == 0: s.y = 1
	if __filled:
		for y in range(_origin_cell.y + s.y, _position_cell.y, s.y):
			for x in range(_origin_cell.x + s.x, _position_cell.x + s.x, s.x):
				_brush.paint(Vector2(x, y), _paper)

func _on_draw(overlay: Control) -> void:
	_brush.draw(_position_cell, overlay, _paper)
	if _is_pushed:
		var s = (_position_cell - _origin_cell).sign()
		if s == Vector2.ZERO:
			_brush.draw(_origin_cell, overlay, _paper)
		if s.x == 0:
			for y in range(_origin_cell.y, _position_cell.y + s.y, s.y):
				_brush.draw(Vector2(_origin_cell.x, y), overlay, _paper)
		elif s.y == 0:
			for x in range(_origin_cell.x, _position_cell.x + s.x, s.x):
				_brush.draw(Vector2(x, _origin_cell.y), overlay, _paper)
		else:
			for x in range(_origin_cell.x, _position_cell.x + s.x, s.x):
				_brush.draw(Vector2(x, _origin_cell.y), overlay, _paper)
				_brush.draw(Vector2(x, _position_cell.y), overlay, _paper)
			for y in range(_origin_cell.y + s.y, _position_cell.y, s.y):
				_brush.draw(Vector2(_origin_cell.x, y), overlay, _paper)
				_brush.draw(Vector2(_position_cell.x, y), overlay, _paper)
