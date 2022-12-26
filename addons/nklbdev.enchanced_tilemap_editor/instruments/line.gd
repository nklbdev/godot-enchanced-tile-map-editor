extends "_base.gd"

const Iterators = preload("../iterators.gd")

func _init(brush: Brush, paper_holder: Common.ValueHolder).(brush, paper_holder) -> void:
	pass

func _after_pushed() -> void:
	_brush.paint(_origin_cell, _paper_holder.value)

func _on_moved() -> void:
	if _is_pushed:
		_paper_holder.value.reset_changes()
		# draw line
		# todo: improve line algorithm
		for cell in Iterators.line(_origin_cell, _position_cell):
			_brush.paint(cell, _paper_holder.value)

func _on_draw(overlay: Control) -> void:
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
		var half_offset: int = _paper_holder.value.get_half_offset()
		for cell in Iterators.line(_origin_cell, _position_cell):
			_brush.draw(cell, overlay, half_offset)
#			overlay.draw_rect(_paper.get_cell_world_rect(cell), color)
