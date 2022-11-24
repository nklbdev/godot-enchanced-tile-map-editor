tool
extends EditorPlugin

const _plugin_folder = "res://addons/nklbdev.enchanced_tilemap_editor/"
const Common = preload("res://addons/nklbdev.enchanced_tilemap_editor/common.gd")

var _tile_map: TileMap

var _original_tile_map_editor_plugin: EditorPlugin
var _original_tile_map_editor: VBoxContainer
var _original_toolbar: HBoxContainer
var _original_toolbar_right: HBoxContainer
var _canvas_item_editor: VBoxContainer
var _scene_viewport: Viewport
var _select_tool_button: ToolButton
var _context_menu_hbox: HBoxContainer

var _display_grid_enabled: bool = false
var _grid_color: Color
var _axis_color: Color

# режимы рисования:
# тайлы (включая паттерны, типа скопированные области)
# террэйны
# кастомные правила
var _toolbar: HBoxContainer
var _tool_select_button: ToolButton
var _tool_draw_button: ToolButton
# modes: brush (square or circle or copied data), line, rect
var _tool_pick_button: ToolButton
var _tool_bucket_fill_button: ToolButton
var _tool_magick_wand_button: ToolButton
var _tool_select_same_button: ToolButton

var _rotate_clockwise_button: ToolButton
var _rotate_counterclockwise_button: ToolButton
var _flip_horizontally_button: ToolButton
var _flip_vertically_button: ToolButton
var _transpose_button: ToolButton # swap x and y axes

var _buttons_by_shortcuts = {}

var PatternSelection = preload("res://addons/nklbdev.enchanced_tilemap_editor/pattern_selection.gd")
var _pattern_selection

const _quad: Array = [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]

##########################################
#           OVERRIDEN METHODS            #
##########################################

func _enter_tree() -> void:
	print("_enter_tree")
	var editor_interface = get_editor_interface()
	_interface_display_scale = editor_interface.get_editor_scale()
	_original_tile_map_editor_plugin = _get_child_by_class(get_parent(), "TileMapEditorPlugin")
	_canvas_item_editor = _find_node_by_class(editor_interface.get_editor_viewport(), "CanvasItemEditor")
	_original_tile_map_editor = _find_node_by_class(_canvas_item_editor, "TileMapEditor")
	_scene_viewport = _find_node_by_class(_canvas_item_editor, "Viewport")
	_select_tool_button = _get_child_by_class(_get_child_by_class(_get_child_by_class(_canvas_item_editor, "HFlowContainer"), "HBoxContainer"), "ToolButton")
	
	editor_interface.get_editor_settings().connect("settings_changed", self, "_update_grid_visibility")
	_scan_editor_settings()
	
	var collision_polygon_2d_editor = _find_node_by_class(_canvas_item_editor, "CollisionPolygon2DEditor") as Node
	_context_menu_hbox = collision_polygon_2d_editor.get_parent() as HBoxContainer
	_original_toolbar = _context_menu_hbox.get_child(collision_polygon_2d_editor.get_position_in_parent() + 1) as HBoxContainer
	_original_toolbar_right = _context_menu_hbox.get_child(collision_polygon_2d_editor.get_position_in_parent() + 2) as HBoxContainer
	
	_hang_canvas_item_visibility(_original_tile_map_editor, false)
	_hang_canvas_item_visibility(_original_toolbar, false)
	_hang_canvas_item_visibility(_original_toolbar_right, false)
	
	_toolbar = _create_toolbar()
	_context_menu_hbox.add_child(_toolbar)
	_toolbar.hide()

func _exit_tree() -> void:
	print("_exit_tree")
	_release_canvas_item_visibility(_original_tile_map_editor)
	_release_canvas_item_visibility(_original_toolbar)
	_release_canvas_item_visibility(_original_toolbar_right)
	get_editor_interface().get_editor_settings().disconnect("settings_changed", self, "_update_grid_visibility")
	_toolbar.queue_free()

func handles(object: Object) -> bool:
	print("handles")
	return object is TileMap and is_instance_valid(object)

func make_visible(visible: bool) -> void:
	print("make_visible")
	if not _is_active():
		return
	_toolbar.visible = visible
	if not visible:
		edit(null)

func edit(object: Object) -> void:
	print("edit")
	if object is TileMap:
		_tile_map = object as TileMap
		_original_tile_map_editor._node_removed(_tile_map)
		_original_tile_map_editor.hide()
		_pattern_selection = PatternSelection.new(_tile_map)
		make_visible(true)
	else:
		if _pattern_selection != null:
			_pattern_selection.free()
			_pattern_selection = null
	update_overlays()

func clear() -> void:
	print("clear")
	make_visible(false)

func apply_changes() -> void:
	print("apply_changes")
	pass

func build() -> bool:
	print("build")
	return true

func enable_plugin() -> void:
	print("enable_plugin")
	pass

func disable_plugin() -> void:
	print("disable_plugin")
	pass

func get_plugin_icon() -> Texture:
	print("get_plugin_icon")
	return null

func get_plugin_name() -> String:
	print("get_plugin_name")
	return "Enchanced TileMap Editor"

func get_state() -> Dictionary:
	print("get_state")
	return {}

func set_state(state: Dictionary) -> void:
	print("set_state")
	pass

func get_window_layout(layout: ConfigFile) -> void:
	print("get_window_layout")
	pass

func set_window_layout(layout: ConfigFile) -> void:
	print("set_window_layout")
	pass

func has_main_screen() -> bool:
	print("has_main_screen")
	return false

func save_external_data() -> void:
	print("save_external_data")
	pass

func forward_canvas_gui_input(event: InputEvent) -> bool:
	if not _is_active():
		return false
	
	var consumed = false
	if event is InputEventKey:
		if event.pressed:
			for shortcut_event in _buttons_by_shortcuts.keys():
				if shortcut_event.shortcut_match(event):
					_buttons_by_shortcuts.get(shortcut_event).emit_signal("pressed")
					consumed = true
	
	
	if not consumed and _tile_pattern_tool != null:
		consumed = _tile_pattern_tool.forward_canvas_gui_input(event)
	
	if consumed:
		update_overlays()
	
	return consumed

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not _is_active():
		return
	_draw_grid(overlay, _tile_map.get_used_rect())
	if _pattern_selection != null:
		_pattern_selection.forward_canvas_draw_over_viewport(overlay)
	if _tile_pattern_tool != null:
		_tile_pattern_tool.forward_canvas_draw_over_viewport(overlay)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	if _tile_pattern_tool != null:
		_tile_pattern_tool.forward_canvas_force_draw_over_viewport(overlay)

##########################################
#            PRIVATE METHODS             #
##########################################

func _is_active() -> bool:
	return _tile_map != null and is_instance_valid(_tile_map) and _select_tool_button.pressed

var _interface_display_scale: float = 1.0
func _create_tool_button(group: ButtonGroup, tooltip: String, method: String, binds: Array, icon_name: String,  scancodes_with_modifiers = []) -> ToolButton:
	var tool_button = ToolButton.new()
	tool_button.focus_mode = Control.FOCUS_NONE
	if group:
		tool_button.group = group
		tool_button.toggle_mode = true
	if not tooltip.empty():
		tool_button.hint_tooltip = tooltip
	if not method.empty():
		tool_button.connect("pressed", self, method, binds)
	if not icon_name.empty():
		tool_button.icon = \
			_canvas_item_editor.get_icon(icon_name, "EditorIcons") \
			if _canvas_item_editor.has_icon(icon_name, "EditorIcons") else \
			_resize_button_texture( \
				load(_plugin_folder.plus_file("icons/").plus_file(icon_name + ".svg")), \
				_interface_display_scale / 4)
	if typeof(scancodes_with_modifiers) == TYPE_INT:
		scancodes_with_modifiers = [scancodes_with_modifiers]
	for scancode_with_modifiers in scancodes_with_modifiers:
		var event = InputEventKey.new()
		event.pressed = true
		event.shift = scancode_with_modifiers & KEY_MASK_SHIFT
		event.alt = scancode_with_modifiers & KEY_MASK_ALT
		event.meta = scancode_with_modifiers & KEY_MASK_META
		event.control = scancode_with_modifiers & KEY_MASK_CTRL
		event.command = scancode_with_modifiers & KEY_MASK_CMD
		event.scancode = scancode_with_modifiers & KEY_CODE_MASK
		# do not set shortcut into button!
		_buttons_by_shortcuts[event] = tool_button
	return tool_button

func _create_toolbar() -> HBoxContainer:
	var toolbar = HBoxContainer.new()
	var tools_button_group = ButtonGroup.new()
	# Selection
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.SELECTION, Common.SelectionType.RECT], "ToolSelect", KEY_M))
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.SELECTION, Common.SelectionType.LASSO], "ToolSelect"))
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.SELECTION, Common.SelectionType.POLYGON], "ToolSelect"))
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.SELECTION, Common.SelectionType.CONTINOUS], "")) # aseprite and tiled: W
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.SELECTION, Common.SelectionType.SAME], "")) # tiled: S
	# Drawing (square brush, circle brush, line, rect, paste pattern)
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.DRAWING, Common.DrawingType.PASTE], "Edit", KEY_B)) # aseprite: B, L, U, tiled: B
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.DRAWING, Common.DrawingType.CLONE], "Edit", KEY_C)) # aseprite: B, L, U, tiled: B
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.DRAWING, Common.DrawingType.ERASE], "Clear", KEY_E)) # aseprite: B, L, U, tiled: B
	toolbar.add_child(_create_tool_button(tools_button_group, "", "_select_tool", [Common.TilePatternToolType.FILLING], "Bucket", [KEY_B, KEY_F]))
	
	toolbar.add_child(VSeparator.new())
	
	toolbar.add_child(_create_tool_button(null, "", "_transform_pattern", [Common.TransformType.ROTATE_COUNTERCLOCKWISE], "RotateLeft", KEY_A))
	toolbar.add_child(_create_tool_button(null, "", "_transform_pattern", [Common.TransformType.ROTATE_CLOCKWISE], "RotateRight", KEY_S))
	toolbar.add_child(_create_tool_button(null, "", "_transform_pattern", [Common.TransformType.FLIP_HORIZONTALLY], "MirrorX", KEY_Z))
	toolbar.add_child(_create_tool_button(null, "", "_transform_pattern", [Common.TransformType.FLIP_VERTICALLY], "MirrorY", KEY_X))
	toolbar.add_child(_create_tool_button(null, "", "_transform_pattern", [Common.TransformType.TRANSPOSE], "Transpose", KEY_T))
	toolbar.add_child(_create_tool_button(null, "", "_transform_pattern", [Common.TransformType.CLEAR_TRANSFORM], "Clear", KEY_W))
	
	toolbar.add_child(VSeparator.new())
	
	toolbar.add_child(_create_tool_button(null, "", "_selection_action", [Common.SelectionActionType.CUT], "ActionCut", KEY_MASK_CMD | KEY_C))
	toolbar.add_child(_create_tool_button(null, "", "_selection_action", [Common.SelectionActionType.COPY], "Duplicate", KEY_MASK_CMD | KEY_V))
	toolbar.add_child(_create_tool_button(null, "", "_selection_action", [Common.SelectionActionType.DELETE], "Remove", KEY_DELETE))
	return toolbar

const a = preload("res://addons/nklbdev.enchanced_tilemap_editor/pattern_tool_selection_rect.gd")

var _tile_pattern_tool: Object = null
func _select_tool(tile_pattern_tool_type: int, clarification: int = -1) -> void:
	if not _is_active():
		return
	if _tile_pattern_tool:
		_tile_pattern_tool.free()
		_tile_pattern_tool = null
	match tile_pattern_tool_type:
		Common.TilePatternToolType.SELECTION:
			_tile_pattern_tool = a.new(_tile_map, _pattern_selection)
		Common.TilePatternToolType.DRAWING:
			pass
		Common.TilePatternToolType.FILLING:
			pass

	var clarification_type = null
	match tile_pattern_tool_type:
		Common.TilePatternToolType.SELECTION: clarification_type = Common.SelectionType
		Common.TilePatternToolType.DRAWING: clarification_type = Common.DrawingType
		Common.TilePatternToolType.FILLING: pass
	print("Select pattern tool: %s, clarification: %s" % [
		_get_first_key_with_value(Common.TilePatternToolType, tile_pattern_tool_type, "unknown tool type"),
		_get_first_key_with_value(clarification_type, clarification, "unknown clarification type") if clarification_type else ""])

func _transform_pattern(transform_type: int) -> void:
	print(_get_first_key_with_value(Common.TransformType, transform_type, "unknown transform type"))

func _selection_action(selection_action_type: int) -> void:
	if not _is_active():
		return
	print(_get_first_key_with_value(Common.SelectionActionType, selection_action_type, "unknown selection action type"))
	match selection_action_type:
		Common.SelectionActionType.COPY: pass
		Common.SelectionActionType.CUT: pass
		Common.SelectionActionType.DELETE:
			for y in range(_pattern_selection._rect.position.y, _pattern_selection._rect.end.y):
				for x in range(_pattern_selection._rect.position.x, _pattern_selection._rect.end.x):
					_tile_map.set_cell(x, y, TileMap.INVALID_CELL)
			_pattern_selection.clear()
			

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


##########################################
#                 UTILS                  #
##########################################

# visibility

func _hang_canvas_item_visibility(canvas_item: CanvasItem, value: bool):
	canvas_item.visible = value
	canvas_item.connect("visibility_changed", self, "_on_canvas_item_visibility_changed", [canvas_item, value])

func _release_canvas_item_visibility(canvas_item: CanvasItem):
	canvas_item.disconnect("visibility_changed", self, "_on_canvas_item_visibility_changed")

func _on_canvas_item_visibility_changed(canvas_item: CanvasItem, value: bool):
	if not canvas_item.visible == value:
		canvas_item.visible = value

# search nodes

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

# nodes inspection

func _to_string_pretty(node: Node):
	return "%s: %s%s" % [node.name, node.get_class(), (", " + node.text if "text" in node else "")]

func _print_path_pretty(node: Node) -> void:
	var results = []
	while node:
		results.append(_to_string_pretty(node))
		node = node.get_parent()
	results.invert()
	for result in results:
		print(result)

func _print_tree_pretty(node: Node, indent = "") -> void:
	print(indent + _to_string_pretty(node))
	var children_indent = indent + "    "
	for child in node.get_children():
		_print_tree_pretty(child, children_indent)

# Other

func _get_first_key_with_value(dict: Dictionary, value, default):
	for key in dict.keys():
		if dict.get(key) == value:
			return key
	return default

static func _resize_button_texture(texture: Texture, scale: float) -> Texture:
	var image = texture.get_data() as Image
	var new_size = image.get_size() * scale
	image.resize(round(new_size.x), round(new_size.y))
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)
	return new_texture
