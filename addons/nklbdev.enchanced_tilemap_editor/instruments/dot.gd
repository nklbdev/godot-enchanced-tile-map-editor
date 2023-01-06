extends "_base.gd"

func _init(brush: Brush, paper: Paper).(brush, paper) -> void:
	pass


func _after_pushed() -> void:
	_brush.paint(_origin_cell, _paper)
	pass
func _before_pulled() -> void:
	pass
func _on_moved(from_position: Vector2, from_cell: Vector2) -> void:
	pass


func _on_draw(overlay: Control) -> void:
	_brush.draw(_origin_cell, overlay, _paper)
