extends "_base.gd"

func _init(brush: Brush, paper: Paper).(brush, paper) -> void:
	pass

#var __comparator
#
#func _init(ink: Ink, comparator).(ink) -> void:
#	__comparator = comparator
#
#func _after_pushed() -> void:
#	# read cell
#	# draw on all same cells
#
#	# выбрать все доступные ячейки
#	# перебрать их и для каждой
#	# проверить соответствие
#	var cell_data = _paper.get_cell_data(_hex_cell)
#	_paper.
#	pass
#
#func _before_pulled() -> void:
#	pass
#
#func _on_moved(from_hex_cell: Vector2) -> void:
#	pass

func _on_draw(overlay: Control) -> void:
	_brush.draw(_origin_cell, overlay, _paper)
