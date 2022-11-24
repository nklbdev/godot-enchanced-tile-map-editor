extends Object

var _tile_map: TileMap
var _consumed: bool

func _init(tile_map: TileMap):
	_tile_map = tile_map

func forward_canvas_gui_input(event: InputEvent) -> bool:
	_consumed = false
	_forward_canvas_gui_input(event)
	return _consumed

func _forward_canvas_gui_input(event: InputEvent) -> void:
	pass

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	pass

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _consume_event() -> void:
	_consumed = true
