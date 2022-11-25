extends "res://addons/nklbdev.enchanced_tilemap_editor/tools/pattern_tools/_base.gd"

var __pattern_selection = null

func _init(tile_map: TileMap, pattern_selection).(tile_map):
	__pattern_selection = pattern_selection

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	pass

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _on_key(event: InputEventKey) -> void:
#	if event.echo:
#		return
#	if is_active():
#		var shape_layout_flags = ShapeLayoutFlag.SIMPLE
#		if Input.is_key_pressed(KEY_SHIFT):
#			shape_layout_flags |= ShapeLayoutFlag.REGULAR
#		if Input.is_key_pressed(KEY_CONTROL):
#			shape_layout_flags |= ShapeLayoutFlag.CENTERED
#		set_shape_layout_flags(shape_layout_flags)
#	else:
#		if Input.is_key_pressed(KEY_SHIFT):
#			if Input.is_key_pressed(KEY_ALT):
#				__set_operation_type(OperationType.FORWARD_SUBTRACTION)
#			elif Input.is_key_pressed(KEY_CONTROL):
#				__set_operation_type(OperationType.INTERSECTION)
#			else:
#				__set_operation_type(OperationType.UNION)
#		else: __set_operation_type(__default_operation_type)
	pass

func _on_mouse_button(position: Vector2, button: int, pressed: bool) -> void:
	pass

func _on_mouse_motion(position: Vector2, relative: Vector2, pressed_buttons: int) -> void:
	pass

func _on_ready_to_drag(position: Vector2, button: int) -> void:
	pass

func _on_cancel_dragging(position: Vector2, button: int) -> void:
	pass

func _on_start_dragging(start_position: Vector2, button: int) -> void:
	pass

func _on_drag(position: Vector2, relative: Vector2, button: int) -> void:
	pass

func _on_finish_dragging(finish_position: Vector2, button: int, success: bool) -> void:
	pass

func _start(override_operation_type = -1) -> void:
#	if __current_operation_type < 0:
#		__set_current_operation_type(get_operation_type() if override_operation_type < 0 else override_operation_type)
	pass

func _finish(cell_enumerator) -> void:
#	if __current_operation_type >= 0:
#		if cell_enumerator != null:
#			__pattern_selection.combine(cell_enumerator, __current_operation_type)
#		__set_current_operation_type(-1)
	pass

func is_active() -> bool:
#	return __current_operation_type >= 0
	return false
