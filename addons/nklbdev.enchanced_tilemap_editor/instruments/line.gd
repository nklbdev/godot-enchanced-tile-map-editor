extends "_base.gd"

const Iterators = preload("../iterators.gd")

func _init(brush: Brush, paper: Paper).(brush, paper) -> void:
	pass

func _after_pushed() -> void:
	_brush.paint(_origin_cell, _paper)

func _on_moved(from_position: Vector2, from_cell: Vector2) -> void:
	if _is_pushed:
		_paper.reset_changes()
		# draw line
		# todo: improve line algorithm
		for cell in Iterators.line(_origin_cell, _position_cell):
			_brush.paint(cell, _paper)

func _on_draw(overlay: Control) -> void:
	_brush.draw(_position_cell, overlay, _paper)
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
		for cell in Iterators.line(_origin_cell, _position_cell):
			_brush.draw(cell, overlay, _paper)
#			overlay.draw_rect(_paper.get_cell_world_rect(cell), color)
