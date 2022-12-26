extends "_base.gd"

const Iterators = preload("../iterators.gd")

func _init(brush: Brush, paper_holder: Common.ValueHolder).(brush, paper_holder) -> void:
	pass

var __drawn_cells: PoolVector2Array
var __unique_drawn_cells: Dictionary

func _before_pulled() -> void:
	__drawn_cells.resize(0)
	__unique_drawn_cells.clear()

func _after_pushed() -> void:
	__drawn_cells.resize(0)
	__unique_drawn_cells.clear()
	_brush.paint(_origin_cell, _paper_holder.value)
	__drawn_cells.append(_origin_cell)
	__unique_drawn_cells[_origin_cell] = true

func _on_moved() -> void:
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
		for cell in Iterators.line(_origin_cell, _position_cell).skip(1):
			_brush.paint(cell, _paper_holder.value)
			__drawn_cells.append(cell)
			__unique_drawn_cells[cell] = true
	_set_origin(_position)

func _on_draw(overlay: Control) -> void:
	
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
#		var color = _drawing_settings.drawn_cells_color
		var half_offset: int = _paper_holder.value.get_half_offset()
		for cell in __unique_drawn_cells.keys():
			_brush.draw(cell, overlay, half_offset)
#			overlay.draw_rect(_paper.get_cell_world_rect(cell), color)
