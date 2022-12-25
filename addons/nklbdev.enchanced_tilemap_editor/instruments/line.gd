extends "_base.gd"

const Iterators = preload("../iterators.gd")

func _init(brush: Brush, drawing_settings: Common.DrawingSettings).(brush, drawing_settings) -> void:
	pass

func _after_pushed() -> void:
	_brush.paint(_origin_cell)

func _on_moved() -> void:
	if _is_pushed:
		_paper.reset_changes()
		# draw line
		# todo: improve line algorithm
		for cell in Iterators.line(_origin_cell, _cell):
			_brush.paint(cell)

func _on_draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
		var color = _drawing_settings.drawn_cells_color
		for cell in Iterators.line(_origin_cell, _cell):
			overlay.draw_rect(_paper.get_cell_world_rect(cell), color)
