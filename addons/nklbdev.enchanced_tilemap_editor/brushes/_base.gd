extends "../_setupable.gd"

func _init(drawing_settings: Common.DrawingSettings).(drawing_settings) -> void:
	pass

func paint(cell: Vector2) -> void:
	assert(is_ready())
	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
	# порядкового номера (идентификатора?) рисовательного действия и координат
	pass

