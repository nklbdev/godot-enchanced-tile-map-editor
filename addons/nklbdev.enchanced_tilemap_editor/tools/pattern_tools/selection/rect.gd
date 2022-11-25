extends "res://addons/nklbdev.enchanced_tilemap_editor/tools/pattern_tools/selection/_base.gd"

var RectCellEnumerator = preload("res://addons/nklbdev.enchanced_tilemap_editor/cell_enumerators/rect.gd")

var __selected_rect = null
var __selection_arm = null
var __shape_layout_controller

func _init(tile_map: TileMap, pattern_selection, shape_layout_controller).(tile_map, pattern_selection):
	__shape_layout_controller = shape_layout_controller
	__shape_layout_controller.disabled = true
	add_subutility(__shape_layout_controller)
	__shape_layout_controller.connect("shape_layout_changed", self, "__on_shape_layout_changed")

func _on_mouse_button(position: Vector2, button: int, pressed: bool) -> void:
	print("_on_mouse_button %s" % position)
	pass

func _on_mouse_motion(position: Vector2, relative: Vector2, pressed_buttons: int) -> void:
#	print("_on_mouse_motion %s" % position)
	pass

func _on_ready_to_drag(start_position: Vector2, button: int) -> void:
	print("_on_ready_to_drag %s" % start_position)
	match button:
		BUTTON_LEFT: _start()
		BUTTON_RIGHT: _start(Common.SelectionCombineOperationType.FORWARD_SUBTRACTION)
		_: return
	__shape_layout_controller.disabled = false
	__selection_arm = Rect2(_tile_map.world_to_map(start_position), Vector2.ZERO)
	_consume_event()

func _on_cancel_dragging(position: Vector2, button: int) -> void:
	print("_on_cancel_dragging %s" % position)
	_on_drag(position, Vector2.ZERO, button)
	_on_finish_dragging(position, button, true)

func _on_start_dragging(start_position: Vector2, button: int) -> void:
	print("_on_start_dragging %s" % start_position)
	if is_active():
		__selection_arm = Rect2(_tile_map.world_to_map(start_position), Vector2.ZERO)
		_consume_event()
		_update_overlays()

func _on_drag(position: Vector2, relative: Vector2, button: int) -> void:
	print("_on_drag %s" % position)
	if is_active():
		__selection_arm.end = _tile_map.world_to_map(position)
		__update_selected_rect()
		_consume_event()

func _on_finish_dragging(finish_position: Vector2, button: int, success: bool) -> void:
	print("_on_finish_dragging %s" % finish_position)
	if is_active():
		if __selected_rect == null:
			_finish(null)
		else:
			_finish(RectCellEnumerator.new(__selected_rect))
		__shape_layout_controller.disabled = true
		__selection_arm = null
		__selected_rect = null
		_consume_event()
		_update_overlays()

func __keep_aspect(vector: Vector2) -> Vector2:
	var shortest = min(abs(vector.x), abs(vector.y))
	return Vector2(shortest * sign(vector.x), shortest * sign(vector.y))

func __update_selected_rect() -> void:
	print("_update_selected_rect")
	var new_selected_rect = null
	if __selection_arm != null:
		var layout_flags = __shape_layout_controller.get_shape_layout_flags()
		
		new_selected_rect = __selection_arm
		if layout_flags & Common.ShapeLayoutFlag.REGULAR:
			new_selected_rect.size = __keep_aspect(new_selected_rect.size)
		if layout_flags & Common.ShapeLayoutFlag.CENTERED:
			new_selected_rect.position -= new_selected_rect.size
			new_selected_rect.size *= 2

	if new_selected_rect != __selected_rect:
		__selected_rect = new_selected_rect
		_update_overlays()

func __on_shape_layout_changed(shape_layout_flags: int) -> void:
	print("_on_shape_layout_changed")
	__update_selected_rect()

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not is_active() or __selected_rect == null:
		return
	
	var rect_to_draw = (_tile_map.get_viewport_transform() * _tile_map.get_global_transform()) \
		.xform(rect_map_to_world(__selected_rect.abs().grow_individual(0, 0, 1, 1)))
	
	overlay.draw_rect(rect_to_draw, Common.SelectionSettings.FILL_COLOR, true)
	overlay.draw_rect(rect_to_draw, Common.SelectionSettings.BORDER_COLOR, false, Common.SelectionSettings.BORDER_WIDTH)

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass
