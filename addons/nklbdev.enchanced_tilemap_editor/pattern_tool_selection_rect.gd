extends "res://addons/nklbdev.enchanced_tilemap_editor/pattern_tool_selection_base.gd"
const Common = preload("res://addons/nklbdev.enchanced_tilemap_editor/common.gd")

var Settings = Common.SelectionSettings

var _active: bool
var _absolute_selection_rect: Rect2
var _grid_selection_rect: Rect2
var _negative: bool

func _init(tile_map: TileMap, pattern_selection).(tile_map, pattern_selection):
	pass

func _on_mouse_button(position: Vector2, button: int, pressed: bool) -> void:
	pass

func _on_mouse_motion(position: Vector2, relative: Vector2, pressed_buttons: int) -> void:
	pass

func _on_ready_to_drag(start_position: Vector2, button: int) -> void:
	if not _active and (button == BUTTON_LEFT or button == BUTTON_RIGHT):
		_active = true
		_absolute_selection_rect = Rect2(start_position, Vector2.ZERO)
		_grid_selection_rect = Rect2()
		_negative = button == BUTTON_RIGHT
		_consume_event()

func _on_cancel_dragging(position: Vector2, button: int) -> void:
	if _active:
		_active = false
		_grid_selection_rect = Rect2()
		_consume_event()

func _on_start_dragging(start_position: Vector2, button: int) -> void:
	if _active:
		_grid_selection_rect = Rect2(start_position.floor(), Vector2.ONE)
		_consume_event()

func _on_drag(position: Vector2, relative: Vector2, button: int) -> void:
	if _active:
		_absolute_selection_rect.end = position
		var a = _absolute_selection_rect.abs()
		_grid_selection_rect.position = _tile_map.world_to_map(a.position)
		_grid_selection_rect.end = _tile_map.world_to_map(a.end) + Vector2.ONE
		_consume_event()

func _on_finish_dragging(finish_position: Vector2, button: int, success: bool) -> void:
	if _active:
		if success:
			_pattern_selection.combine(_grid_selection_rect)
		else:
			pass
		_active = false
		_absolute_selection_rect = Rect2()
		_grid_selection_rect = Rect2()
		_negative = false
		_consume_event()

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not _active or _grid_selection_rect.has_no_area():
		return
	
	var rect_to_draw = (_tile_map.get_viewport_transform() * _tile_map.get_global_transform()) \
		.xform(Rect2(
			_tile_map.map_to_world(_grid_selection_rect.position),
			_tile_map.map_to_world(_grid_selection_rect.size)))
	
	overlay.draw_rect(rect_to_draw, Settings.FILL_COLOR, true)
	overlay.draw_rect(rect_to_draw, Settings.BORDER_COLOR, false, Settings.BORDER_WIDTH)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass
