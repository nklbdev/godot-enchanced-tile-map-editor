extends "_base.gd"

const Iterators = preload("../iterators.gd")

func _init(brush: Brush, drawing_settings: Common.DrawingSettings).(brush, drawing_settings) -> void:
	pass

#func _after_pushed() -> void:
#	._after_pushed()
#	_tip.push()
#
#func _before_pulled() -> void:
#	_tip.pull()
#	._before_pulled()
#
#func _on_moved(from_hex_cell: Vector2) -> void:
#	_tip.move_to(_hex_cell)

var __drawn_cells: PoolVector2Array
var __unique_drawn_cells: Dictionary

func _before_pulled() -> void:
	__drawn_cells.resize(0)
	__unique_drawn_cells.clear()

func _after_pushed() -> void:
	__drawn_cells.resize(0)
	__unique_drawn_cells.clear()
	_brush.paint(_origin_cell)
	__drawn_cells.append(_origin_cell)
	__unique_drawn_cells[_origin_cell] = true

func _on_moved() -> void:
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
		for cell in Iterators.line(_origin_cell, _cell).skip(1):
			_brush.paint(cell)
			__drawn_cells.append(cell)
			__unique_drawn_cells[cell] = true
	_set_origin_hex_cell(_hex_cell)

func _on_draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	if _is_pushed:
		# draw line
		# todo: improve line algorithm
		var color = _drawing_settings.drawn_cells_color
		for cell in __unique_drawn_cells.keys():
			overlay.draw_rect(_paper.get_cell_world_rect(cell), color)
