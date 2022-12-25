#extends "../_base.gd"
#
#const Instrument = preload("../_base.gd")
#
#var __data: PoolIntArray
#
#func _init(data: PoolIntArray) -> void:
#	__data = data
#
#func _on_start() -> void:
#	pass
#
#func _on_apply_changes_and_close_inner_transactions() -> void:
#	pass
#
#func _on_break_last_change() -> bool:
#	return true
#
#func _on_break_all_changes_and_close_inner_transactions() -> void:
#	pass
#
#func _on_finish() -> void:
#	pass
#
#func _on_mode_changed() -> void:
#	pass
#
#func _on_pushed() -> void:
#	if is_active():
#		_transaction_parent.set_cell_data(_position.floor(), __data)
#
#func _on_pulled() -> void:
#	pass
#
#func _on_moved(previous_position: Vector2) -> void:
#	if is_active() and _position.floor() != previous_position.floor():
#		_transaction_parent.set_cell_data(_position.floor(), __data)
#
#
#
#
#func forward_canvas_draw_over_viewport(overlay: Control, tile_map: TileMap) -> void:
##	overlay.draw_circle(_position.snapped(Vector2.ONE / 2), 0.2, Color.white)
#	pass
#
#func forward_canvas_force_draw_over_viewport(overlay: Control, tile_map: TileMap) -> void:
#	pass
