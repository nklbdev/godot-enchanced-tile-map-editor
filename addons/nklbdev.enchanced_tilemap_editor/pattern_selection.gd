extends "res://addons/nklbdev.enchanced_tilemap_editor/tile_map_utility_base.gd"

const v_half: Vector2 = Vector2.ONE / 2
var __cells: Dictionary = {}
var __selection_map: TileMap = TileMap.new()

func _init(tile_map: TileMap).(tile_map):
	__selection_map
	pass

func _forward_canvas_gui_input(event: InputEvent) -> void:
	pass



func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	var transform = _tile_map.get_viewport_transform() * _tile_map.get_global_transform()
	
	var one = _tile_map.map_to_world(Vector2.ONE) - _tile_map.map_to_world(Vector2.ZERO)
	var half = one / 2
#	var center_of_cell = transform * v_half
	for cell in __cells.keys():
		overlay.draw_circle(transform * (_tile_map.map_to_world(cell) + half), 5, Common.SelectionSettings.FILL_COLOR)
#	if _rect.has_no_area():
#		return
#
#	var rect_to_draw = (_tile_map.get_viewport_transform() * _tile_map.get_global_transform()) \
#		.xform(Rect2(
#			_tile_map.map_to_world(_rect.position),
#			_tile_map.map_to_world(_rect.size)))
#
#	overlay.draw_rect(rect_to_draw, Settings.FILL_COLOR, true)
#	overlay.draw_rect(rect_to_draw, Settings.BORDER_COLOR, false, Settings.BORDER_WIDTH)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func combine(cell_enumerator, operation_type: int) -> void:
	if cell_enumerator == null:
		cell_enumerator = []
	match operation_type:
		Common.SelectionCombineOperationType.REPLACEMENT:
			__cells.clear()
			for cell in cell_enumerator:
				__cells[cell] = true
		Common.SelectionCombineOperationType.UNION:
			for cell in cell_enumerator:
				__cells[cell] = true
		Common.SelectionCombineOperationType.INTERSECTION:
			var new_cells: Dictionary = {}
			for cell in cell_enumerator:
				if __cells.has(cell):
					new_cells[cell] = true
			__cells = new_cells
		Common.SelectionCombineOperationType.FORWARD_SUBTRACTION:
			for cell in cell_enumerator:
				__cells.erase(cell)
		Common.SelectionCombineOperationType.BACKWARD_SUBTRACTION:
			var new_cells: Dictionary = {}
			for cell in cell_enumerator:
				if not __cells.has(cell):
					new_cells[cell] = true
			__cells = new_cells
	_consume_event()

func clear() -> void:
	__cells = {}
	_consume_event()

func empty() -> bool:
	return __cells.empty()
