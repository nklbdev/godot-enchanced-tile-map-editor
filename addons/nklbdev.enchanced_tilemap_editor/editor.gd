tool
extends EditorPlugin

const Common = preload("common.gd")
const RectSelectionPatternTool = preload("tools/selection/rect.gd")
const ShapeLayoutController = preload("shape_layout_controller.gd")
const PatternSelection = preload("pattern_selection.gd")
const ToolBar = preload("tool_bar.gd")
const CanvasItemVisibilityController = preload("canvas_item_visibility_controller.gd")
const ToolBase = preload("tools/_base.gd")

var __tile_map_ref: WeakRef

var __original_tile_map_editor_plugin: EditorPlugin
var __original_tile_map_editor: VBoxContainer
var __original_toolbar: HBoxContainer
var __original_toolbar_right: HBoxContainer

var __editor_settings: EditorSettings

var __overlay: Control
var __select_tool_button: ToolButton

var __display_grid_enabled: bool
var __grid_color: Color
var __axis_color: Color

var __tool_bar: ToolBar
var pattern_selection: PatternSelection
var current_tool: ToolBase setget __set_current_tool

var __canvas_item_visibility_controller: CanvasItemVisibilityController

var __is_event_consumed: bool

##########################################
#           OVERRIDEN METHODS            #
##########################################
var __log: File
func _enter_tree() -> void:
	__log = File.new()
	__log.open("C:/Data/Godot/_log.txt", File.WRITE)
	print("_enter_tree")
	var editor_interface = get_editor_interface()
	print("1")

	__editor_settings = editor_interface.get_editor_settings()
	print("2")
	__editor_settings.connect("settings_changed", self, "__scan_editor_settings")
	print("3")
	__scan_editor_settings()
	print("4")

	var canvas_item_editor = Common.find_node_by_class(editor_interface.get_editor_viewport(), "CanvasItemEditor") as Node
	print("5")
	__select_tool_button = Common.get_child_by_class(Common.get_child_by_class(Common.get_child_by_class(canvas_item_editor, "HFlowContainer"), "HBoxContainer"), "ToolButton") as ToolButton
	print("6")
	__overlay = Common.find_node_by_class(canvas_item_editor, "CanvasItemEditorViewport") as Control
	print("7")

	var collision_polygon_2d_editor = Common.find_node_by_class(canvas_item_editor, "CollisionPolygon2DEditor") as Node
	print("8")
	var context_menu_hbox = collision_polygon_2d_editor.get_parent() as HBoxContainer
	print("9")
	__original_tile_map_editor_plugin = Common.get_child_by_class(get_parent(), "TileMapEditorPlugin") as EditorPlugin
	print("10")
	__original_tile_map_editor = Common.find_node_by_class(canvas_item_editor, "TileMapEditor") as VBoxContainer
	print("11")
	__original_toolbar = context_menu_hbox.get_child(collision_polygon_2d_editor.get_position_in_parent() + 1) as HBoxContainer
	print("12")
	__original_toolbar_right = context_menu_hbox.get_child(collision_polygon_2d_editor.get_position_in_parent() + 2) as HBoxContainer
	print("13")
	
	__canvas_item_visibility_controller = CanvasItemVisibilityController.new()
	print("14")
	__canvas_item_visibility_controller.hang_visibility(__original_tile_map_editor, false)
	print("15")
	__canvas_item_visibility_controller.hang_visibility(__original_toolbar, false)
	print("16")
	__canvas_item_visibility_controller.hang_visibility(__original_toolbar_right, false)
	print("17")
	
	__tool_bar = ToolBar.new(self)
	print("18")
	print("__tool_bar: %s" % Common.to_string_pretty(__tool_bar))
	print("__tool_bar.visible: %s" % __tool_bar)
	context_menu_hbox.add_child(__tool_bar)
	print("19")
	__tool_bar.hide()

func _exit_tree() -> void:
	print("_exit_tree")
	__canvas_item_visibility_controller.release_visibility(__original_tile_map_editor)
	__canvas_item_visibility_controller.release_visibility(__original_toolbar)
	__canvas_item_visibility_controller.release_visibility(__original_toolbar_right)
	__canvas_item_visibility_controller = null
	__editor_settings.disconnect("settings_changed", self, "__scan_editor_settings")
	__tool_bar.queue_free()
	__tool_bar = null

func handles(object: Object) -> bool:
	print("handles")
	return object is TileMap and is_instance_valid(object)

func make_visible(visible: bool) -> void:
#	return
	print("make_visible(%s)" % [visible])
	if __tool_bar.visible == visible:
		return
	if not __is_active():
		return
	__tool_bar.visible = visible
	if not visible:
		edit(null)

func edit(object: Object) -> void:
#	return
	print("edit")
	if __tile_map_ref != null:
		var tile_map: TileMap = __tile_map_ref.get_ref()
		if tile_map:
			if object == tile_map:
				return
			# TODO forgive old tilemap!
			pattern_selection = null
			# _tile_pattern_tool = null
		else:
			# TODO restore initial state to prevent errors!
			pass
	var tile_map = object as TileMap
	if tile_map:
		__tile_map_ref = weakref(tile_map)
		__original_tile_map_editor._node_removed(tile_map)
		__original_tile_map_editor.hide()
		pattern_selection = PatternSelection.new(self)
		#__select_tool(Common.TilePatternToolTypes.SELECTION, Common.SelectionTypes.RECT)
	else:
		__tile_map_ref = null
	make_visible(__tile_map_ref != null)
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
	if event is InputEventMouseButton:
		print("InputEventMouseButton button: %s, pressed: %s, position: %s" % [event.button_index, event.pressed, event.position])

	__is_event_consumed = false
	if not __is_active():
		return false
	
	# ignore pressing mouse buttons outside the viewport
	if event is InputEventMouseButton \
		and event.pressed and \
		not __overlay.get_rect().has_point(__overlay.get_local_mouse_position()):
		return false

	if current_tool:
		current_tool.forward_canvas_gui_input(event)
		if __is_event_consumed:
			__is_event_consumed = false
			return true
	
	__tool_bar.forward_canvas_gui_input(event)
	if __is_event_consumed:
		__is_event_consumed = false
		return true
	return false

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not __is_active():
		return
	var tile_map = try_get_tile_map()
	if not tile_map:
		return
	__draw_grid(__overlay, tile_map.get_used_rect())
	if pattern_selection:
		pattern_selection.forward_canvas_draw_over_viewport(__overlay)
	if current_tool:
		current_tool.forward_canvas_draw_over_viewport(__overlay)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	if current_tool:
		current_tool.forward_canvas_force_draw_over_viewport(__overlay)

##########################################
#            PUBLIC METHODS              #
##########################################

#func get_icon(icon_name: String, theme_type: String = "") -> Texture:
#	return __original_tile_map_editor.get_icon(icon_name, theme_type)
#
#func has_icon(icon_name: String, theme_type: String = "") -> bool:
#	return __original_tile_map_editor.has_icon(icon_name, theme_type)
#
func try_get_tile_map() -> TileMap:
	__log.store_line("start try_get_tile_map")
	if __tile_map_ref != null:
		var tile_map = __tile_map_ref.get_ref()
		if tile_map:
			__log.store_line("try_get_tile_map returns tilemap")
			return tile_map
		__tile_map_ref = null
		__log.store_line("try_get_tile_map performs edit(null)")
		edit(null)
	__log.store_line("try_get_tile_map returns null")
	return null
	
#	if __tile_map_ref != null:
#		var tile_map = __tile_map_ref.get_ref()
#		if tile_map:
#			return tile_map
#		__tile_map_ref = null
#	edit(null)
#	return null

func consume_event() -> void:
	__is_event_consumed = true

##########################################
#            PRIVATE METHODS             #
##########################################

func __is_active() -> bool:
	var result = __select_tool_button.pressed and try_get_tile_map()
#	print("__is_active() -> %s ---- %s" % [result, __select_tool_button.pressed])
	return result

func __set_current_tool(value: ToolBase) -> void:
	if current_tool == value:
		return
	if current_tool:
		current_tool.set_active(false)
	current_tool = value
	if current_tool:
		current_tool.set_active(true)

func __scan_editor_settings():
	__display_grid_enabled = __editor_settings.get_setting("editors/tile_map/display_grid")
	__grid_color = __editor_settings.get_setting("editors/tile_map/grid_color")
	__axis_color = __editor_settings.get_setting("editors/tile_map/axis_color")

func __draw_grid(viewport: Control, rect: Rect2) -> void:
	if not __display_grid_enabled:
		return
	var tile_map = try_get_tile_map()
	if not tile_map:
		return

	var cell_xf: Transform2D = tile_map.cell_custom_transform
	var xform: Transform2D = tile_map.get_viewport_transform() * tile_map.get_global_transform()

	# Fade the grid when the rendered cell size is relatively small.
	var cell_area: float = xform.xform(Rect2(Vector2.ZERO, tile_map.get_cell_size())).get_area()
	var distance_fade: float = min(inverse_lerp(4, 64, cell_area), 1)
	if distance_fade <= 0:
		return

	var grid_color: Color = __grid_color * Color(1, 1, 1, distance_fade)
	var axis_color: Color = __axis_color * Color(1, 1, 1, distance_fade)

	var fade: int = 5
	var si: Rect2 = rect.grow(fade)

	# When zoomed in, it's useful to clip the rendering.
	var xform_inv: Transform2D = xform.affine_inverse()
	var screen_size: Vector2 = viewport.rect_size
	var visible_cells_rect: Rect2 = Rect2()
	visible_cells_rect.position = tile_map.world_to_map(xform_inv.xform(Vector2.ZERO))
	visible_cells_rect = visible_cells_rect.expand(tile_map.world_to_map(xform_inv.xform(Vector2(0, screen_size.y))) + Vector2.DOWN)
	visible_cells_rect = visible_cells_rect.expand(tile_map.world_to_map(xform_inv.xform(Vector2(screen_size.x, 0))) + Vector2.RIGHT)
	visible_cells_rect = visible_cells_rect.expand(tile_map.world_to_map(xform_inv.xform(screen_size)) + Vector2.ONE)
	if tile_map.cell_half_offset != TileMap.HALF_OFFSET_DISABLED:
		visible_cells_rect.grow(1) # So it won't matter whether corners are on an odd or even row/column.
	var clipped: Rect2 = visible_cells_rect.clip(si)
	if clipped.has_no_area():
		return

	clipped.position -= si.position # Relative to the fade rect, in grid unit.
	var clipped_end: Vector2 = clipped.end

	var points: PoolVector2Array
	var colors: PoolColorArray

	# Vertical lines.
	if tile_map.cell_half_offset != TileMap.HALF_OFFSET_X and tile_map.cell_half_offset != TileMap.HALF_OFFSET_NEGATIVE_X:
		points.resize(4)
		colors.resize(4)

		for x in range(clipped.position.x, clipped_end.x + 1):
			points[0] = xform.xform(tile_map.map_to_world(si.position + Vector2(x, 0)))
			points[1] = xform.xform(tile_map.map_to_world(si.position + Vector2(x, fade)))
			points[2] = xform.xform(tile_map.map_to_world(si.position + Vector2(x, si.size.y - fade)))
			points[3] = xform.xform(tile_map.map_to_world(si.position + Vector2(x, si.size.y)))

			var color: Color = axis_color if x + si.position.x == 0 else grid_color
			var line_opacity: float = Common.lerp_fade(si.size.x, fade, x)

			colors[0] = Color(color.r, color.g, color.b, 0.0)
			colors[1] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[2] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[3] = Color(color.r, color.g, color.b, 0.0)

			viewport.draw_polyline_colors(points, colors, 1)
	else:
		var half_offset: float = 0.5 if tile_map.cell_half_offset == TileMap.HALF_OFFSET_X else -0.5
		var cell_count: int = clipped.size.y
		points.resize(cell_count * 2)
		colors.resize(cell_count * 2)

		for x in range(clipped.position.x, clipped.end.x + 1):
			var color: Color = axis_color if x + si.position.x == 0 else grid_color
			var line_opacity: float = Common.lerp_fade(si.size.x, fade, x)

			for y in range(clipped.position.y, clipped.end.y + 1):
				var ofs: Vector2
				if int(abs(si.position.y + y)) & 1:
					ofs = cell_xf[0] * half_offset
				var index: int = (y - clipped.position.y) * 2
				points[index + 0] = xform.xform(ofs + tile_map.map_to_world(si.position + Vector2(x, y), true))
				points[index + 1] = xform.xform(ofs + tile_map.map_to_world(si.position + Vector2(x, y + 1), true))
				colors[index + 0] = Color(color.r, color.g, color.b, color.a * line_opacity * Common.lerp_fade(si.size.y, fade, y))
				colors[index + 1] = Color(color.r, color.g, color.b, color.a * line_opacity * Common.lerp_fade(si.size.y, fade, y + 1))
			viewport.draw_multiline_colors(points, colors, 1)

	# Horizontal lines.
	if tile_map.cell_half_offset != TileMap.HALF_OFFSET_Y and tile_map.cell_half_offset != TileMap.HALF_OFFSET_NEGATIVE_Y:
		points.resize(4)
		colors.resize(4)

		for y in range(clipped.position.y, clipped.end.y + 1):
			points[0] = xform.xform(tile_map.map_to_world(si.position + Vector2(0, y)))
			points[1] = xform.xform(tile_map.map_to_world(si.position + Vector2(fade, y)))
			points[2] = xform.xform(tile_map.map_to_world(si.position + Vector2(si.size.x - fade, y)))
			points[3] = xform.xform(tile_map.map_to_world(si.position + Vector2(si.size.x, y)))

			var color: Color = axis_color if y + si.position.y == 0 else grid_color
			var line_opacity: float = Common.lerp_fade(si.size.y, fade, y)

			colors[0] = Color(color.r, color.g, color.b, 0.0)
			colors[1] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[2] = Color(color.r, color.g, color.b, color.a * line_opacity)
			colors[3] = Color(color.r, color.g, color.b, 0.0)

			viewport.draw_polyline_colors(points, colors, 1)
	else:
		var half_offset: float = 0.5 if tile_map.cell_half_offset == TileMap.HALF_OFFSET_Y else -0.5
		var cell_count: int = clipped.size.x
		points.resize(cell_count * 2)
		colors.resize(cell_count * 2)

		for y in range(clipped.position.y, clipped.end.y + 1):
			var color: Color = axis_color if y + si.position.y == 0 else grid_color
			var line_opacity: float = Common.lerp_fade(si.size.y, fade, y)

			for x in range(clipped.position.x, clipped.end.x + 1):
				var ofs: Vector2
				if int(abs(si.position.x + x)) & 1:
					ofs = cell_xf[1] * half_offset
				var index: int = (x - clipped.position.x) * 2
				points[index + 0] = xform.xform(ofs + tile_map.map_to_world(si.position + Vector2(x, y), true))
				points[index + 1] = xform.xform(ofs + tile_map.map_to_world(si.position + Vector2(x + 1, y), true))
				colors[index + 0] = Color(color.r, color.g, color.b, color.a * line_opacity * Common.lerp_fade(si.size.x, fade, x))
				colors[index + 1] = Color(color.r, color.g, color.b, color.a * line_opacity * Common.lerp_fade(si.size.x, fade, x + 1))
			viewport.draw_multiline_colors(points, colors, 1)
