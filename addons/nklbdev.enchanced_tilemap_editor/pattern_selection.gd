extends "res://addons/nklbdev.enchanced_tilemap_editor/utility.gd"
const Common = preload("res://addons/nklbdev.enchanced_tilemap_editor/common.gd")
var Settings = Common.SelectionSettings

var _rect: Rect2

func _init(tile_map: TileMap).(tile_map):
	pass

func _forward_canvas_gui_input(event: InputEvent) -> void:
	pass

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if _rect.has_no_area():
		return
	
	var rect_to_draw = (_tile_map.get_viewport_transform() * _tile_map.get_global_transform()) \
		.xform(Rect2(
			_tile_map.map_to_world(_rect.position),
			_tile_map.map_to_world(_rect.size)))
	
	overlay.draw_rect(rect_to_draw, Settings.FILL_COLOR, true)
	overlay.draw_rect(rect_to_draw, Settings.BORDER_COLOR, false, Settings.BORDER_WIDTH)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func combine(rect: Rect2) -> void:
	_rect = rect if _rect.has_no_area() else _rect.merge(rect)
	_consume_event()

func clear() -> void:
	if _rect.has_no_area():
		return
	_rect = Rect2()
	_consume_event()
	
