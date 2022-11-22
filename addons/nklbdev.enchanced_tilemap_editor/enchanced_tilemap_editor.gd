tool
extends EditorPlugin

enum ActionType {
	NONE = -1,
	PAINT = 0,
	ERASE = 1
}

enum PaintMode {
	BRUSH = 0,
	LINE = 1,
	RECT = 2
}

var _tile_map: TileMap
var _current_action: int = ActionType.NONE
var _current_mode: int = PaintMode.BRUSH
var _start_cell: Vector2 = Vector2.ZERO
var _finish_cell: Vector2 = Vector2.ZERO
var _original_tile_map_editor_plugin: EditorPlugin
var _original_tile_map_editor: VBoxContainer
var _canvas_item_editor: VBoxContainer
var _canvas_item_editor_viewport: Viewport

const _quad: Array = [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]

func _do_action(force: bool = false) -> void:
	match _current_action:
		ActionType.PAINT:
			for pos in _quad:
				_tile_map.set_cellv(_finish_cell + pos, 0)
			_tile_map.update_bitmask_region(_finish_cell - Vector2.ONE, _finish_cell + Vector2.ONE * 2)
		ActionType.ERASE:
			_tile_map.set_cellv(_finish_cell, TileMap.INVALID_CELL)
			_tile_map.update_bitmask_region(_finish_cell - Vector2.ONE, _finish_cell + Vector2.ONE)
	update_overlays()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _current_action != ActionType.NONE:
			_finish_cell = _tile_map.world_to_map(_tile_map.get_local_mouse_position())
			_do_action()
			get_tree().set_input_as_handled()

var _select_tool_button: ToolButton
func _enter_tree() -> void:
	_original_tile_map_editor = _find_node_by_class(get_tree().root, "TileMapEditor")
	_hang_canvas_item_visibility(_original_tile_map_editor, false)
	_original_tile_map_editor_plugin = _get_child_by_class(get_parent(), "TileMapEditorPlugin")
	_canvas_item_editor = _find_node_by_class(get_tree().root, "CanvasItemEditor")
	_canvas_item_editor_viewport = _find_node_by_class(_canvas_item_editor, "Viewport")
	get_editor_interface().get_editor_settings().connect("settings_changed", self, "_update_grid_visibility")
	_scan_editor_settings()
	_select_tool_button = _get_child_by_class(_get_child_by_class(_get_child_by_class(_canvas_item_editor, "HFlowContainer"), "HBoxContainer"), "ToolButton")

func _print_path_pretty(node: Node) -> void:
	var results = []
	while node:
		results.append(_to_string_pretty(node))
		node = node.get_parent()
	results.invert()
	for result in results:
		print(result)
	
func _exit_tree() -> void:
	_release_canvas_item_visibility(_original_tile_map_editor)

func handles(object: Object) -> bool:
	return object.is_class("TileMap")

func edit(object: Object) -> void:
	_tile_map = object as TileMap
	_current_action = ActionType.NONE
	_current_mode = PaintMode.BRUSH
	_original_tile_map_editor._node_removed(_tile_map)
	_original_tile_map_editor.hide()
	update_overlays()

func clear() -> void:
	_tile_map = null
	_current_action = ActionType.NONE
	_current_mode = PaintMode.BRUSH

func _find_node_by_class(root: Node, classname: String) -> Node:
	if root.is_class(classname):
		return root
	for child in root.get_children():
		var node = _find_node_by_class(child, classname)
		if node:
			return node
	return null

func _find_nodes_by_class(root: Node, classname: String) -> Node:
	var results = []
	if root.is_class(classname):
		results.append(root)
	for child in root.get_children():
		results.append_array(_find_nodes_by_class(child, classname))
	return results

func _get_child_by_class(root: Node, classname: String) -> Node:
	for child in root.get_children():
		if child.is_class(classname):
			return child
	return null

func _find_children_by_class(root: Node, classname: String) -> Node:
	var results = []
	for child in root.get_children():
		if child.is_class(classname):
			results.append(child)
	return results

func _to_string_pretty(node: Node):
	return "%s: %s%s" % [node.name, node.get_class(), (", " + node.text if "text" in node else "")]

func _print_tree_pretty(node: Node, indent = "") -> void:
	print(indent + _to_string_pretty(node))
	var children_indent = indent + "    "
	for child in node.get_children():
		_print_tree_pretty(child, children_indent)

func forward_canvas_gui_input(event: InputEvent) -> bool:
	if _tile_map and _select_tool_button.pressed:
		if event is InputEventMouseButton:
			match event.button_index:
				BUTTON_LEFT:
					if event.pressed:
						if _current_action == ActionType.NONE:
							_current_action = ActionType.PAINT
							_start_cell = _tile_map.world_to_map(_tile_map.make_input_local(event).position)
							return true
					else:
						if _current_action == ActionType.PAINT:
							_current_action = ActionType.NONE
							_do_action(true)
							return true
				BUTTON_RIGHT:
					if event.pressed:
						if _current_action == ActionType.NONE:
							_current_action = ActionType.ERASE
							_start_cell = _tile_map.world_to_map(_tile_map.make_input_local(event).position)
							_finish_cell = _start_cell
							_do_action()
							return true
					else:
						if _current_action == ActionType.ERASE:
							_current_action = ActionType.NONE
							_do_action(true)
							return true
		elif event is InputEventMouseMotion:
			if _current_action != ActionType.NONE:
				_do_action()
				return true
	return false

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if _tile_map == null or not _select_tool_button.pressed:
		return
	_draw_grid(overlay, _tile_map.get_used_rect())
	pass

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _hang_canvas_item_visibility(canvas_item: CanvasItem, value: bool):
	canvas_item.visible = value
	canvas_item.connect("visibility_changed", self, "_on_canvas_item_visibility_changed", [canvas_item, value])

func _release_canvas_item_visibility(canvas_item: CanvasItem):
	canvas_item.disconnect("visibility_changed", self, "_on_canvas_item_visibility_changed")

func _on_canvas_item_visibility_changed(canvas_item: CanvasItem, value: bool):
	if not canvas_item.visible == value:
		canvas_item.visible = value

var _display_grid_enabled: bool = false
var _grid_color: Color
var _axis_color: Color
func _scan_editor_settings():
	var settings = get_editor_interface().get_editor_settings()
	_display_grid_enabled = settings.get_setting("editors/tile_map/display_grid")
	_grid_color = settings.get_setting("editors/tile_map/grid_color")
	_axis_color = settings.get_setting("editors/tile_map/axis_color")

static func _lerp_fade(total: int, fade: int, position: float) -> float:
	if position < fade:
		return inverse_lerp(0, fade, position)
	if position > (total - fade):
		return inverse_lerp(total, total - fade, position)
	return 1.0

func _draw_grid(viewport: Control, rect: Rect2) -> void:
	if not _display_grid_enabled:
		return

	var cell_xf: Transform2D = _tile_map.cell_custom_transform
	var xform: Transform2D = _tile_map.get_viewport_transform() * _tile_map.get_global_transform()

	# Fade the grid when the rendered cell size is relatively small.
	var cell_area: float = xform.xform(Rect2(Vector2.ZERO, _tile_map.get_cell_size())).get_area()
	var distance_fade: float = min(inverse_lerp(4, 64, cell_area), 1)
	if distance_fade <= 0:
		return

	var grid_color: Color = _grid_color * Color(1, 1, 1, distance_fade)
	var axis_color: Color = _axis_color * Color(1, 1, 1, distance_fade)

	var fade: int = 5
	var si: Rect2 = rect.grow(fade)

	# When zoomed in, it's useful to clip the rendering.
	var xform_inv: Transform2D = xform.affine_inverse()
	var screen_size: Vector2 = viewport.rect_size
	var visible_cells_rect: Rect2 = Rect2()
	visible_cells_rect.position = _tile_map.world_to_map(xform_inv.xform(Vector2.ZERO))
	visible_cells_rect = visible_cells_rect.expand(_tile_map.world_to_map(xform_inv.xform(Vector2(0, screen_size.y))) + Vector2.DOWN)
	visible_cells_rect = visible_cells_rect.expand(_tile_map.world_to_map(xform_inv.xform(Vector2(screen_size.x, 0))) + Vector2.RIGHT)
	visible_cells_rect = visible_cells_rect.expand(_tile_map.world_to_map(xform_inv.xform(screen_size)) + Vector2.ONE)
	if _tile_map.cell_half_offset != TileMap.HALF_OFFSET_DISABLED:
		visible_cells_rect.grow(1) # So it won't matter whether corners are on an odd or even row/column.
	var clipped: Rect2 = visible_cells_rect.clip(si)
	if clipped.has_no_area():
		return

	clipped.position -= si.position # Relative to the fade rect, in grid unit.
	var clipped_end: Vector2 = clipped.end

	var points: PoolVector2Array
	var colors: PoolColorArray
	print("clipped position: %s, size: %s" % [clipped.position, clipped.size])

	# Vertical lines.
	if _tile_map.cell_half_offset != TileMap.HALF_OFFSET_X and _tile_map.cell_half_offset != TileMap.HALF_OFFSET_NEGATIVE_X:
		points.resize(4)
		colors.resize(4)

		for x in range(clipped.position.x, clipped_end.x + 1):
			points[0] = xform.xform(_tile_map.map_to_world(si.position + Vector2(x, 0)))
			points[1] = xform.xform(_tile_map.map_to_world(si.position + Vector2(x, fade)))
			points[2] = xform.xform(_tile_map.map_to_world(si.position + Vector2(x, si.size.y - fade)))
			points[3] = xform.xform(_tile_map.map_to_world(si.position + Vector2(x, si.size.y)))

			var color: Color = axis_color if x + si.position.x == 0 else grid_color
			var line_opacity: float = _lerp_fade(si.size.x, fade, x)

			colors[0] = Color(color.r, color.g, color.b, 0.0)
			colors[1] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[2] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[3] = Color(color.r, color.g, color.b, 0.0)

			viewport.draw_polyline_colors(points, colors, 1)
	else:
		var half_offset: float = 0.5 if _tile_map.cell_half_offset == TileMap.HALF_OFFSET_X else -0.5
		var cell_count: int = clipped.size.y
		points.resize(cell_count * 2)
		colors.resize(cell_count * 2)

		for x in range(clipped.position.x, clipped.end.x + 1):
			var color: Color = axis_color if x + si.position.x == 0 else grid_color
			var line_opacity: float = _lerp_fade(si.size.x, fade, x)

			for y in range(clipped.position.y, clipped.end.y + 1):
				var ofs: Vector2
				if int(abs(si.position.y + y)) & 1:
					ofs = cell_xf[0] * half_offset
				var index: int = (y - clipped.position.y) * 2
				points[index + 0] = xform.xform(ofs + _tile_map.map_to_world(si.position + Vector2(x, y), true))
				points[index + 1] = xform.xform(ofs + _tile_map.map_to_world(si.position + Vector2(x, y + 1), true))
				colors[index + 0] = Color(color.r, color.g, color.b, color.a * line_opacity * _lerp_fade(si.size.y, fade, y))
				colors[index + 1] = Color(color.r, color.g, color.b, color.a * line_opacity * _lerp_fade(si.size.y, fade, y + 1))
			viewport.draw_multiline_colors(points, colors, 1)

	# Horizontal lines.
	if _tile_map.cell_half_offset != TileMap.HALF_OFFSET_Y and _tile_map.cell_half_offset != TileMap.HALF_OFFSET_NEGATIVE_Y:
		points.resize(4)
		colors.resize(4)

		for y in range(clipped.position.y, clipped.end.y + 1):
			points[0] = xform.xform(_tile_map.map_to_world(si.position + Vector2(0, y)))
			points[1] = xform.xform(_tile_map.map_to_world(si.position + Vector2(fade, y)))
			points[2] = xform.xform(_tile_map.map_to_world(si.position + Vector2(si.size.x - fade, y)))
			points[3] = xform.xform(_tile_map.map_to_world(si.position + Vector2(si.size.x, y)))

			var color: Color = axis_color if y + si.position.y == 0 else grid_color
			var line_opacity: float = _lerp_fade(si.size.y, fade, y)

			colors[0] = Color(color.r, color.g, color.b, 0.0)
			colors[1] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[2] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[3] = Color(color.r, color.g, color.b, 0.0)

			viewport.draw_polyline_colors(points, colors, 1)
	else:
		var half_offset: float = 0.5 if _tile_map.cell_half_offset == TileMap.HALF_OFFSET_Y else -0.5
		var cell_count: int = clipped.size.x
		points.resize(cell_count * 2)
		colors.resize(cell_count * 2)

		for y in range(clipped.position.y, clipped.end.y + 1):
			var color: Color = axis_color if y + si.position.y == 0 else grid_color
			var line_opacity: float = _lerp_fade(si.size.y, fade, y)

			for x in range(clipped.position.x, clipped.end.x + 1):
				var ofs: Vector2
				if int(abs(si.position.x + x)) & 1:
					ofs = cell_xf[1] * half_offset
				var index: int = (x - clipped.position.x) * 2
				points[index + 0] = xform.xform(ofs + _tile_map.map_to_world(si.position + Vector2(x, y), true))
				points[index + 1] = xform.xform(ofs + _tile_map.map_to_world(si.position + Vector2(x + 1, y), true))
				colors[index + 0] = Color(color.r, color.g, color.b, color.a * line_opacity * _lerp_fade(si.size.x, fade, x))
				colors[index + 1] = Color(color.r, color.g, color.b, color.a * line_opacity * _lerp_fade(si.size.x, fade, x + 1))
			viewport.draw_multiline_colors(points, colors, 1)
