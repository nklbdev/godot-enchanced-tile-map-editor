extends "res://addons/nklbdev.enchanced_tilemap_editor/tools/pattern_tools/_base.gd"
var __default_operation_type = Common.SelectionCombineOperationType.REPLACEMENT

signal operation_type_changed(previous_operation_type, current_operation_type)

var __pattern_selection = null
var __operation_type: int = __default_operation_type
var __current_operation_type: int = -1

func _init(tile_map: TileMap, pattern_selection).(tile_map):
	__pattern_selection = pattern_selection

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	pass

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _on_key(event: InputEventKey) -> void:
	if event.echo or is_active():
		return
	if Input.is_key_pressed(KEY_SHIFT):
		if Input.is_key_pressed(KEY_ALT):
			__set_operation_type(Common.SelectionCombineOperationType.FORWARD_SUBTRACTION)
		elif Input.is_key_pressed(KEY_CONTROL):
			__set_operation_type(Common.SelectionCombineOperationType.INTERSECTION)
		else:
			__set_operation_type(Common.SelectionCombineOperationType.UNION)
	else: __set_operation_type(__default_operation_type)

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
	if __current_operation_type < 0:
		__set_current_operation_type(get_operation_type() if override_operation_type < 0 else override_operation_type)
		_consume_event()

func _finish(cell_enumerator) -> void:
	if __current_operation_type >= 0:
		if cell_enumerator:
			__pattern_selection.combine(cell_enumerator, __current_operation_type)
		__set_current_operation_type(-1)
		_consume_event()

func is_active() -> bool:
	return __current_operation_type >= 0

func get_operation_type() -> int:
	if __current_operation_type >= 0:
		return __current_operation_type
	return __operation_type

func __set_operation_type(operation_type: int) -> void:
	var previous_operation_type = get_operation_type()
	__operation_type = operation_type
	var current_operation_type = get_operation_type()
	if operation_type != current_operation_type:
		_consume_event()
		emit_signal("operation_type_changed", previous_operation_type, current_operation_type)

func __set_current_operation_type(operation_type: int) -> void:
	var previous_operation_type = get_operation_type()
	__current_operation_type = operation_type
	var current_operation_type = get_operation_type()
	if operation_type != current_operation_type:
		_consume_event()
		emit_signal("operation_type_changed", previous_operation_type, current_operation_type)
