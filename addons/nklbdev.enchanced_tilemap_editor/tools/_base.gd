extends "res://addons/nklbdev.enchanced_tilemap_editor/tile_map_utility_base.gd"
var __previous_mouse_position: Vector2
var __dragging: bool = false
var __dragging_button: int = 0

func _init(tile_map: TileMap).(tile_map):
	__previous_mouse_position = _tile_map.get_local_mouse_position()

func _forward_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_position = _tile_map.get_local_mouse_position()
		_on_mouse_button(mouse_position, event.button_index, event.pressed)
		if __dragging:
			_on_finish_dragging(mouse_position, __dragging_button, not event.pressed)
			__dragging = false
			__dragging_button = 0
		else:
			if __dragging_button == 0:
				if event.pressed:
					__dragging_button = event.button_index
					_on_ready_to_drag(mouse_position, __dragging_button)
			else:
				_on_cancel_dragging(mouse_position, __dragging_button)
				__dragging_button = 0
	elif event is InputEventMouseMotion:
		var mouse_position = _tile_map.get_local_mouse_position()
		var relative = mouse_position - __previous_mouse_position
		_on_mouse_motion(mouse_position, relative, event.button_mask)
		if __dragging:
			_on_drag(mouse_position, relative, __dragging_button)
		elif __dragging_button:
			_on_start_dragging(__previous_mouse_position, __dragging_button)
			__dragging = true
			_on_drag(mouse_position, relative, __dragging_button)
		__previous_mouse_position = mouse_position
	elif event is InputEventKey:
		_on_key(event)

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	pass

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _on_key(event: InputEventKey) -> void:
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

func _is_dragging() -> bool:
	return __dragging

