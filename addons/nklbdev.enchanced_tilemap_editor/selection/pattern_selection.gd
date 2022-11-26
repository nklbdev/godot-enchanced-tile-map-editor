extends "../utility_base.gd"

var CombineOperations = Common.SelectionCombineOperations
var Settings = Common.SelectionSettings

const v_half: Vector2 = Vector2.ONE / 2
var __cells: Dictionary = {}
var __selection_map: TileMap = TileMap.new()

func _init(editor: EditorPlugin).(editor) -> void: pass

func _forward_canvas_gui_input(event: InputEvent) -> void: pass

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	var tile_map = _editor.try_get_tile_map()
	if not tile_map:
		return
	var transform = tile_map.get_viewport_transform() * tile_map.get_global_transform()
	
	var one = tile_map.map_to_world(Vector2.ONE) - tile_map.map_to_world(Vector2.ZERO)
	var half = one / 2
#	var center_of_cell = transform * v_half
	for cell in __cells.keys():
		overlay.draw_circle(transform * (tile_map.map_to_world(cell) + half), 5, Settings.FILL_COLOR)
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

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void: pass

func combine(cell_enumerator, operation_type: int) -> void:
	if cell_enumerator == null:
		cell_enumerator = []
	match operation_type:
		CombineOperations.REPLACEMENT:
			__cells.clear()
			for cell in cell_enumerator:
				__cells[cell] = true
		CombineOperations.UNION:
			for cell in cell_enumerator:
				__cells[cell] = true
		CombineOperations.INTERSECTION:
			var new_cells: Dictionary = {}
			for cell in cell_enumerator:
				if __cells.has(cell):
					new_cells[cell] = true
			__cells = new_cells
		CombineOperations.FORWARD_SUBTRACTION:
			for cell in cell_enumerator:
				__cells.erase(cell)
		CombineOperations.BACKWARD_SUBTRACTION:
			var new_cells: Dictionary = {}
			for cell in cell_enumerator:
				if not __cells.has(cell):
					new_cells[cell] = true
			__cells = new_cells
	_consume_event()

func clear() -> void:
	__cells = {}
	_consume_event()
	_update_overlays()

func empty() -> bool:
	return __cells.empty()
