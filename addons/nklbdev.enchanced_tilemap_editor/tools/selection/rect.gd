extends "_base.gd"

const ShapeLayoutController = preload("../../shape_layout_controller.gd")
var ShapeLayouts = Common.ShapeLayouts
var SelectionSettings = Common.SelectionSettings

var __selected_rect = null
var __selection_arm = null
var __shape_layout_controller

func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Rectangle Selection",
		editor.get_editor_interface().get_base_control().get_icon("ToolSelect", "EditorIcons"),
		KEY_M)
	__shape_layout_controller = ShapeLayoutController.new(editor)
	add_subutility(__shape_layout_controller)
	__shape_layout_controller.connect("shape_layout_changed", self, "__on_shape_layout_changed")

func _on_mouse_button(position: Vector2, button: int, pressed: bool) -> void:
	print("_on_mouse_button %s" % position)
	pass

func _on_mouse_motion(position: Vector2, relative: Vector2, pressed_buttons: int) -> void:
#	print("_on_mouse_motion %s" % position)
	pass

func _on_ready_to_drag(start_position: Vector2, button: int) -> void:
	var tile_map = _editor.try_get_tile_map()
	if not tile_map:
		return
	print("_on_ready_to_drag %s" % start_position)
	match button:
		BUTTON_LEFT: _start()
		BUTTON_RIGHT: _start(Common.SelectionCombineOperations.FORWARD_SUBTRACTION)
		_: return
	__shape_layout_controller.clear()
	__selection_arm = Rect2(tile_map.world_to_map(start_position), Vector2.ZERO)
	_consume_event()

func _on_cancel_dragging(position: Vector2, button: int) -> void:
	print("_on_cancel_dragging %s" % position)
	_on_drag(position, Vector2.ZERO, button)
	_on_finish_dragging(position, button, true)

func _on_start_dragging(start_position: Vector2, button: int) -> void:
	var tile_map = _editor.try_get_tile_map()
	if not tile_map:
		return
	print("_on_start_dragging %s" % start_position)
	if is_active():
		__selection_arm = Rect2(tile_map.world_to_map(start_position), Vector2.ZERO)
		_consume_event()
		_update_overlays()

func _on_drag(position: Vector2, relative: Vector2, button: int) -> void:
	var tile_map = _editor.try_get_tile_map()
	if not tile_map:
		return
	print("_on_drag %s" % position)
	if is_active():
		__selection_arm.end = tile_map.world_to_map(position)
		__update_selected_rect()
		_consume_event()

func _on_finish_dragging(finish_position: Vector2, button: int, success: bool) -> void:
	print("_on_finish_dragging %s" % finish_position)
	if is_active():
		if __selected_rect == null:
			_finish(null)
		else:
			_finish(Common.RectCellEnumerator.new(__selected_rect))
		__shape_layout_controller.clear()
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
		if layout_flags & ShapeLayouts.REGULAR:
			new_selected_rect.size = __keep_aspect(new_selected_rect.size)
		if layout_flags & ShapeLayouts.CENTERED:
			new_selected_rect.position -= new_selected_rect.size
			new_selected_rect.size *= 2

	if new_selected_rect != __selected_rect:
		__selected_rect = new_selected_rect
		_update_overlays()

func __on_shape_layout_changed(shape_layout_flags: int) -> void:
	print("_on_shape_layout_changed")
	if is_active():
		__update_selected_rect()

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not is_active() or __selected_rect == null:
		return
	var tile_map = _editor.try_get_tile_map()
	if not tile_map:
		return
	
	var rect_to_draw = (tile_map.get_viewport_transform() * tile_map.get_global_transform()) \
		.xform(Common.rect_map_to_world(__selected_rect.abs().grow_individual(0, 0, 1, 1), tile_map))
	
	overlay.draw_rect(rect_to_draw, SelectionSettings.FILL_COLOR, true)
	overlay.draw_rect(rect_to_draw, SelectionSettings.BORDER_COLOR, false, SelectionSettings.BORDER_WIDTH)

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass
