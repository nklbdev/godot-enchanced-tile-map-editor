extends "_base.gd"

const Iterators = preload("../iterators.gd")

var __tracing: bool
var __drawn_cells: PoolVector2Array
var __unique_drawn_cells: Dictionary

func _init(brush: Brush, paper: Paper, tracing = true).(brush, paper) -> void:
	__tracing = tracing

func _before_pulled() -> void:
	if __tracing:
		__drawn_cells.resize(0)
		__unique_drawn_cells.clear()

func _after_pushed() -> void:
	_brush.paint(_position_cell, _paper)
	if __tracing:
		__drawn_cells.resize(0)
		__unique_drawn_cells.clear()
		__drawn_cells.append(_position_cell)
		__unique_drawn_cells[_position_cell] = true

func _on_moved(from_position: Vector2, from_cell: Vector2) -> void:
	if _is_pushed:
		# todo: improve line algorithm
		for cell in Iterators.line(from_cell, _position_cell).skip(1):
			_brush.paint(cell, _paper)
			if __tracing:
				__drawn_cells.append(cell)
				__unique_drawn_cells[cell] = true

func _on_draw(overlay: Control) -> void:
	_brush.draw(_position_cell, overlay, _paper)
	if __tracing and _is_pushed:
		# todo: improve line algorithm
		for cell in __unique_drawn_cells.keys():
			_brush.draw(cell, overlay, _paper)
