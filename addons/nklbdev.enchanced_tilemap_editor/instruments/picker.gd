extends "_single.gd"

func _init(pattern_holder: Common.ValueHolder, paper: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) \
	.(pattern_holder, paper, selection_map, paint_immediately_on_pushed, paint_invalid_cell) -> void:
	pass


func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	# считать ячейку бумаги на позиции
	pass
func _before_pulled(force: bool) -> void:
	pass
func _after_pulled(force: bool) -> void:
	# если ячейка бумаги считана - создать из нее паттерн и положить в _pattern_holder
	pass

func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	if _is_pushed:
		# считать ячейку бумаги на позиции
		pass
	pass


func _on_draw(overlay: Control) -> void:
	# Подсветить текущую ячейку бумаги
	pass


