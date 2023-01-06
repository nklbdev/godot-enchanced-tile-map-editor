tool
extends EditorPlugin

const Types = preload("types.gd")
const Common = preload("common.gd")
const Iterators = preload("iterators.gd")
const Selection = preload("selection.gd")
const ToolBar = preload("tool_bar.gd")
const Palette = preload("palette/palette.gd")
const CanvasItemVisibilityController = preload("canvas_item_visibility_controller.gd")
const Instrument = preload("instruments/_base.gd")
const Paper = preload("paper.gd")
const Brush = preload("brushes/_base.gd")
#const BrushSelection = preload("brushes/selection.gd")
const BrushPattern = preload("brushes/pattern.gd")
const BrushAutotile = preload("brushes/autotile.gd")
const BrushTerrain = preload("brushes/terrain.gd")

var __tile_map: TileMap

var __original_tile_map_editor_plugin: EditorPlugin
var __original_tile_map_editor: VBoxContainer
var __original_toolbar: HBoxContainer
var __original_toolbar_right: HBoxContainer

var __editor_settings: EditorSettings

var __overlay: Control
var __select_tool_button: ToolButton

var __palette: Palette
var __tool_bar: ToolBar
var __selection: Selection

var __canvas_item_visibility_controller: CanvasItemVisibilityController
var __is_mouse_on_overlay: bool

var __visual_root: Node2D
var __settings: Common.Settings
var __tile_map_paper: Paper

var __instruments: Dictionary
var __instrument_adjustments_hbox: HBoxContainer
var __brush_adjustments_hbox: HBoxContainer
var __paper_adjustments_hbox: HBoxContainer
var __active_instrument: Instrument setget __set_active_instrument
func __set_active_instrument(value: Instrument) -> void:
	__active_instrument = value
	__update_current_instrument()
var __default_instrument: Instrument setget __set_default_instrument
func __set_default_instrument(value: Instrument) -> void:
	__default_instrument = value
	__update_current_instrument()
var __current_instrument: Instrument
func __update_current_instrument() -> void:
	var current_instrument: Instrument = __active_instrument if __active_instrument else __default_instrument 
	if current_instrument != __current_instrument:
		for adjustment in __instrument_adjustments_hbox.get_children():
			 __instrument_adjustments_hbox.remove_child(adjustment)
		for adjustment in __paper_adjustments_hbox.get_children():
			 __paper_adjustments_hbox.remove_child(adjustment)
		for adjustment in __brush_adjustments_hbox.get_children():
			 __brush_adjustments_hbox.remove_child(adjustment)
		__current_instrument = current_instrument
		if __current_instrument:
			for adjustment in __current_instrument.get_adjustments():
				__instrument_adjustments_hbox.add_child(adjustment)
			for adjustment in __current_instrument.get_brush_adjustments():
				__brush_adjustments_hbox.add_child(adjustment)
			for adjustment in __current_instrument.get_paper_adjustments():
				__paper_adjustments_hbox.add_child(adjustment)
#			__current_instrument.apply_modifiers(__modifiers)



##########################################
#           OVERRIDEN METHODS            #
##########################################

func __tangent(points: PoolVector2Array) -> PoolVector2Array:
	for i in points.size():
		points[i] = points[i].tangent()
	return points

func _init():
	name = "EnchancedTileMapEditorPlugin"
	
#	var two_thirds: float = 0.5 # 2.0 / 3.0
#	var two_thirds_v: Vector2 = Vector2(two_thirds, two_thirds)
#	var rotate_clockwise: Transform2D = Transform2D(Vector2.DOWN, Vector2.LEFT, Vector2.ZERO)
#	var transpose: Transform2D = Transform2D.IDENTITY.scaled(Vector2.ONE.tangent())
#	var scale_two_thirds: Transform2D = Transform2D.IDENTITY.scaled(two_thirds_v)
#	var translate_a_half: Transform2D = Transform2D.IDENTITY.translated(Vector2.ONE / 2)
	
	__lines.resize(3)
	__sublines.resize(3)
	__lines[TileMap.HALF_OFFSET_X] = HORIZONTAL_HEX_LINES
	var sublines: PoolVector2Array = PoolVector2Array()
	sublines.append_array(HORIZONTAL_HEX_SUBLINES)
	sublines.append_array(Transform2D.IDENTITY.translated(Vector2(-0.5, -1.0 / 3.0)).xform(HORIZONTAL_HEX_SUBLINES))
	sublines.append_array(Transform2D.IDENTITY.translated(Vector2(-0.5,  1.0 / 3.0)).xform(HORIZONTAL_HEX_SUBLINES))
	__sublines[TileMap.HALF_OFFSET_X] = sublines
	
	__lines[TileMap.HALF_OFFSET_Y] = VERTICAL_HEX_LINES
	sublines = PoolVector2Array()
	sublines.append_array(VERTICAL_HEX_SUBLINES)
	sublines.append_array(Transform2D.IDENTITY.translated(Vector2(-1.0 / 3.0, -0.5)).xform(VERTICAL_HEX_SUBLINES))
	sublines.append_array(Transform2D.IDENTITY.translated(Vector2( 1.0 / 3.0, -0.5)).xform(VERTICAL_HEX_SUBLINES))
	__sublines[TileMap.HALF_OFFSET_Y] = sublines
	
	
#	var hexagons = [HORIZONTAL_ORIENTED_HEXAGON, VERTICAL_ORIENTED_HEXAGON]
#	for hi in hexagons.size():
#		var hexagon = hexagons[hi]
#		var other_hexagon = hexagons[(hi + 1) % 2]
#		__lines[hi] = translate_a_half.xform(hexagon)
#		var center_hex_sublines: PoolVector2Array = scale_two_thirds.xform(other_hexagon)
#		var all_hex_sublines: PoolVector2Array = center_hex_sublines
#		all_hex_sublines.append_array(Transform2D.IDENTITY.translated(hexagon[0]).xform(center_hex_sublines))
#		all_hex_sublines.append_array(Transform2D.IDENTITY.translated(hexagon[1]).xform(center_hex_sublines))
#		__sublines[hi] = translate_a_half.xform(all_hex_sublines)
	__lines[TileMap.HALF_OFFSET_DISABLED] = SQUARE_CELL_LINES
	__sublines[TileMap.HALF_OFFSET_DISABLED] = SQUARE_CELL_SUBLINES
	

func _enter_tree() -> void:
	Common.print_log("_enter_tree")

	var editor_interface = get_editor_interface()

	__editor_settings = editor_interface.get_editor_settings()
	__settings = Common.Settings.new(__editor_settings)
	ProjectSettings.connect("project_settings_changed", __settings, "rescan_project_settings")
	__editor_settings.connect("settings_changed", __settings, "rescan_editor_settings")
	
	__settings.rescan_all_settings()

	var canvas_item_editor = Common.find_node_by_class(editor_interface.get_editor_viewport(), "CanvasItemEditor") as Node
	__select_tool_button = Common.get_child_by_class(Common.get_child_by_class(Common.get_child_by_class(canvas_item_editor, "HFlowContainer"), "HBoxContainer"), "ToolButton") as ToolButton
	__select_tool_button.connect("toggled", self, "__on_select_tool_button_toggled")
	__overlay = Common.find_node_by_class(canvas_item_editor, "CanvasItemEditorViewport") as Control

	var collision_polygon_2d_editor = Common.find_node_by_class(canvas_item_editor, "CollisionPolygon2DEditor") as Node
	var context_menu_hbox = collision_polygon_2d_editor.get_parent() as HBoxContainer
	__original_tile_map_editor_plugin = Common.get_child_by_class(get_parent(), "TileMapEditorPlugin") as EditorPlugin
	__original_tile_map_editor = Common.find_node_by_class(canvas_item_editor, "TileMapEditor") as VBoxContainer
	__original_toolbar = context_menu_hbox.get_child(collision_polygon_2d_editor.get_position_in_parent() + 1) as HBoxContainer
	__original_toolbar_right = context_menu_hbox.get_child(collision_polygon_2d_editor.get_position_in_parent() + 2) as HBoxContainer

	__canvas_item_visibility_controller = CanvasItemVisibilityController.new()
	for control in [
		__original_tile_map_editor,
		__original_toolbar,
		__original_toolbar_right]:
		__canvas_item_visibility_controller.lock_visibility(control, false)

	__visual_root = Node2D.new()
	__overlay.add_child(__visual_root)
	__overlay.connect("mouse_entered", self, "__on_overlay_mouse_entered")
	__overlay.connect("mouse_exited", self, "__on_overlay_mouse_exited")
	__tile_map_paper = Paper.new()
	__selection = Selection.new(__settings)
	__visual_root.add_child(__selection.get_selection_map())
	__visual_root.add_child(__selection.get_selection_operand_map())
	
	var editor_scale = editor_interface.get_editor_scale()
	__palette = Palette.new(editor_scale)
	add_control_to_bottom_panel(__palette, "Tile Palette")
	
	__tool_bar = ToolBar.new(__palette, __tile_map_paper, __selection, __settings, editor_scale)
	context_menu_hbox.add_child(__tool_bar)
	__tool_bar.connect("instruments_taken", self, "__on_tool_bar_instruments_taken")
	__tool_bar.connect("instruments_dropped", self, "__on_tool_bar_instruments_dropped")
#	__tool_bar.connect("cell_type_selected", self, "__on_tool_bar_cell_type_selected")
	context_menu_hbox.add_spacer(false)
	__instrument_adjustments_hbox = HBoxContainer.new()
	context_menu_hbox.add_child(__instrument_adjustments_hbox)
	context_menu_hbox.add_spacer(false)
	__brush_adjustments_hbox = HBoxContainer.new()
	context_menu_hbox.add_child(__brush_adjustments_hbox)
	context_menu_hbox.add_spacer(false)
	__paper_adjustments_hbox = HBoxContainer.new()
	context_menu_hbox.add_child(__paper_adjustments_hbox)
	

func _exit_tree() -> void:
	Common.print_log("_exit_tree")
	__tear_down()
	__overlay.disconnect("mouse_entered", self, "__on_overlay_mouse_entered")
	__overlay.disconnect("mouse_exited", self, "__on_overlay_mouse_exited")
	
	__canvas_item_visibility_controller.unlock_all()
	__canvas_item_visibility_controller = null
	ProjectSettings.disconnect("project_settings_changed", __settings, "rescan_project_settings")
	__editor_settings.disconnect("settings_changed", __settings, "rescan_editor_settings")
	
	__tool_bar.queue_free()
	__tool_bar = null
	remove_control_from_bottom_panel(__palette)
	__palette = null
	
	__visual_root.queue_free()
	__visual_root = null

func handles(object: Object) -> bool:
	var result = object is TileMap and is_instance_valid(object)
	Common.print_log("handles(%s) -> %s" % [Common.to_string_pretty(object), result])
	return result

func __set_up(tile_map: TileMap) -> void:
	assert(__tile_map == null)
	assert(tile_map != null)
	__tile_map = tile_map
	__palette.set_up(__tile_map)
	__tile_map_paper.set_up(__tile_map)
	__selection.set_up(__tile_map)
	__tool_bar.visible = true
	__original_tile_map_editor._node_removed(__tile_map)
	__original_tile_map_editor.hide()

func __tear_down() -> void:
	assert(__tile_map != null)
	__tool_bar.visible = false
	__selection.tear_down()
	__tile_map_paper.tear_down()
	__tile_map = null
	__palette.tear_down()


# called with true right after edit(object)
# called with false on work with object is finished
# can be called with false multiple times
func make_visible(visible: bool) -> void:
	Common.print_log("make_visible(%s)" % [visible])
#	assert(not (__tile_map == null and __tool_bar.visible), \
#		"inconsistent state: the plugin is visible without edited object")
#	assert(not (__tile_map == null and not __tool_bar.visible and visible), \
#		"invalid operation: set plugin visible without edited object")
#	assert(not (__tile_map != null and __tool_bar.visible and visible), \
#		"invalid operation: set plugin visible more than once in a row")
	if visible == __tool_bar.visible:
		return
	if visible:
#		assert(false, "что это еще такое?")
#		__tool_bar.visible = true
		pass
	else:
		__tear_down()

# can be called only if visible == false
# recalled on rename node with visibility blink
# but when user selects other TileMap after previous, visibility not changes
func edit(object: Object) -> void:
	Common.print_log("edit %s" % object)
	# при переключении карты с одной на другую, тут будет старая.
	assert(__tile_map == null, "на данный момент не должно быть текущей тайловой карты")
	assert(object is TileMap, "тайловая карта должна быть обязательно передана")
	__set_up(object as TileMap)

func has_main_screen() -> bool:
	Common.print_log("has_main_screen")
	return false

func __is_event_is_mouse_button_pressed_outside_viewport(event: InputEvent) -> bool:
	return event is InputEventMouseButton and \
		event.pressed and \
		not __overlay.get_rect().has_point(__overlay.get_local_mouse_position())

func __get_mouse_position() -> Vector2:
	assert(__tile_map != null)
	var zero: Vector2 = __tile_map.map_to_world(Vector2.ZERO)
	return Transform2D(
		(__tile_map.map_to_world(Vector2.RIGHT * 2) - zero) / 2,
		(__tile_map.map_to_world(Vector2.DOWN * 2)  - zero) / 2,
		zero
		).affine_inverse().xform(__tile_map.get_local_mouse_position())

func forward_canvas_gui_input(event: InputEvent) -> bool:
	if __tile_map == null:
		return false

	var is_event_consumed: bool
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			var instrument: Instrument = __instruments.get(event.button_index)
			if instrument == null:
				pass
			elif event.pressed:
				if __active_instrument == null: # нет текущего рисования
					__set_active_instrument(instrument)
					instrument.move_to(__get_mouse_position())
					__active_instrument.push()
				elif instrument != __active_instrument: # есть текущее рисование, но нажата кнопка другого инструмента
					__active_instrument.interrupt()
					__set_active_instrument(null)
				is_event_consumed = true
			else:
				if instrument == __active_instrument:
					__active_instrument.pull()
					__set_active_instrument(null)
				is_event_consumed = true
		elif event is InputEventMouseMotion:
			for instrument in __instruments.values():
				instrument.move_to(__get_mouse_position())
			is_event_consumed = true
	elif event is InputEventKey:
		if __active_instrument:
			if event.scancode == KEY_ESCAPE:
				if event.pressed:
					__active_instrument.interrupt()
					__set_active_instrument(null)
					is_event_consumed = true
		if __current_instrument:
			is_event_consumed = __current_instrument.process_input_event_key(event)

	if is_event_consumed:
		update_overlays()
	return is_event_consumed

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	__draw(overlay)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	__draw(overlay, true)

func __draw(overlay: Control, force: bool = false) -> void:
	if __tile_map == null:
		return
	__visual_root.transform = \
		__tile_map.get_viewport_transform() * \
		__tile_map.get_global_transform() * \
		Common.get_cell_base_transform(__tile_map)
	overlay.draw_set_transform_matrix(__visual_root.transform)
	if __current_instrument != null:
		__current_instrument.draw(overlay)
	__draw_grid(overlay)
	overlay.draw_set_transform_matrix(Transform2D.IDENTITY)

##########################################
#            PRIVATE METHODS             #
##########################################

func __on_overlay_mouse_entered() -> void:
	__is_mouse_on_overlay = true
#	if __tile_map and __current_instrument == null:
#		for instrument in __instruments.values():
#			instrument.set_up(__paper)

func __on_overlay_mouse_exited() -> void:
	__is_mouse_on_overlay = false
#	if __tile_map and __current_instrument == null:
#		for instrument in __instruments.values():
#			if instrument.is_ready():
#				instrument.tear_down()

func __on_tool_bar_instruments_taken(left_instrument: Instrument, right_instrument: Instrument) -> void:
	assert(__instruments.empty())
	assert(left_instrument != null)
	assert(right_instrument != null)
	__instruments[BUTTON_LEFT] = left_instrument
	__instruments[BUTTON_RIGHT] = right_instrument
	__set_default_instrument(left_instrument)

func __on_tool_bar_instruments_dropped(left_instrument: Instrument, right_instrument: Instrument) -> void:
	assert(not __instruments.empty())
	assert(__instruments[BUTTON_LEFT] == left_instrument)
	assert(__instruments[BUTTON_RIGHT] == right_instrument)
	for instrument in __instruments.values():
		if instrument.is_pushed():
			instrument.pull()
	__set_active_instrument(null)
	__set_default_instrument(null)
	__instruments.clear()

func __on_select_tool_button_toggled(pressed: bool) -> void:
	if pressed:
		# выбрать первый инструмент
		pass
	else:
		# выбрать первый инструмент
		var pressed_tool_buton: BaseButton = __tool_bar.__button_group.get_pressed_button()
		if pressed_tool_buton:
			pressed_tool_buton.pressed = true

const SQUARE_CELL_LINES: PoolVector2Array = PoolVector2Array([
	Vector2(0, 0   ), Vector2(1, 0   ),
	Vector2(0,    0), Vector2(0,    1),
])

const SQUARE_CELL_SUBLINES: PoolVector2Array = PoolVector2Array([
	Vector2( 0,   -0.25), Vector2( 1,   -0.25),
	Vector2( 0,    0.25), Vector2( 1,    0.25),
	Vector2(-0.25, 0   ), Vector2(-0.25, 1   ),
	Vector2( 0.25, 0   ), Vector2( 0.25, 1   ),
])

const HORIZONTAL_HEX_LINES = PoolVector2Array([
	Vector2(-3, -2) / 6,
	Vector2( 0, -4) / 6,
	Vector2( 3, -2) / 6,
	Vector2( 3,  2) / 6,
	Vector2( 0,  4) / 6,
	Vector2(-3,  2) / 6,
])

const HORIZONTAL_HEX_SUBLINES = PoolVector2Array([
#	Vector2(2, 1) / 6,
#	Vector2(4, 1) / 6,
#	Vector2(5, 3) / 6,
#	Vector2(4, 5) / 6,
#	Vector2(2, 5) / 6,
#	Vector2(1, 3) / 6,
	
	Vector2(2, 0) / 6,
	Vector2(4, 0) / 6,
	Vector2(5, 2) / 6,
	Vector2(4, 4) / 6,
	Vector2(2, 4) / 6,
	Vector2(1, 2) / 6,
])

const VERTICAL_HEX_LINES = PoolVector2Array([
	Vector2( 2, -3) / 6,
	Vector2( 4,  0) / 6,
	Vector2( 2,  3) / 6,
	Vector2(-2,  3) / 6,
	Vector2(-4,  0) / 6,
	Vector2(-2, -3) / 6,
])

const VERTICAL_HEX_SUBLINES = PoolVector2Array([
#	Vector2(1, 2) / 6,
#	Vector2(3, 1) / 6,
#	Vector2(5, 2) / 6,
#	Vector2(5, 4) / 6,
#	Vector2(3, 5) / 6,
#	Vector2(1, 4) / 6,
	
	Vector2(0, 2) / 6,
	Vector2(2, 1) / 6,
	Vector2(4, 2) / 6,
	Vector2(4, 4) / 6,
	Vector2(2, 5) / 6,
	Vector2(0, 4) / 6,
])

var __lines: Array
var __sublines: Array

var __temp_grid_color: Color
func __draw_grid(overlay: Control):
	if __tile_map == null:
		return

	var half_offset_type = __tile_map.cell_half_offset
	var cell_position: Vector2
	if __is_mouse_on_overlay or __active_instrument:
		__temp_grid_color = __settings.grid_color
		var mouse_map_cell: Vector2 = __tile_map.world_to_map(__tile_map.get_local_mouse_position())
		var draw_transform: Transform2D = __visual_root.transform
		var lines: PoolVector2Array = __lines[half_offset_type % 3]
		var sublines: PoolVector2Array = __sublines[half_offset_type % 3]
		for y in range(mouse_map_cell.y - __settings.grid_fragment_radius, mouse_map_cell.y + __settings.grid_fragment_radius + 1):
			for x in range(mouse_map_cell.x - __settings.grid_fragment_radius, mouse_map_cell.x + __settings.grid_fragment_radius + 1):
#		for y in [mouse_map_cell.y]:
#			for x in [mouse_map_cell.x]:
				cell_position = Vector2(x, y)
				cell_position += Common.get_half_offset(cell_position, half_offset_type)
				overlay.draw_set_transform_matrix(draw_transform.translated(cell_position))

				__temp_grid_color.a = __settings.grid_color.a * (1 - mouse_map_cell.distance_squared_to(cell_position) / __settings.grid_fragment_radius_squared)
				
				# Draw first, third and fifth sides of hexagon
				# overlay.draw_multiline(__visual_root.transform.translated(cell_position).xform(__hexagon), __temp_grid_color)
#				overlay.draw_multiline(__hexagon, __temp_grid_color)
#				continue

				# Draw square grid
				overlay.draw_multiline(SQUARE_CELL_LINES, __temp_grid_color)
#				overlay.draw_multiline(lines, __temp_grid_color)
				__temp_grid_color.a /= 3
				overlay.draw_multiline(SQUARE_CELL_SUBLINES, __temp_grid_color)
#				overlay.draw_multiline(sublines, __temp_grid_color)
		overlay.draw_set_transform_matrix(__visual_root.transform)


	# Draw axis fragment
	var axis_color: Color = __settings.axis_color
	for i in __settings.axis_fragment_radius + 1:
		axis_color.a = __settings.axis_color.a * (1 - float(i) / __settings.axis_fragment_radius)
		var direction = Vector2.RIGHT
		for r in 4:
			cell_position = direction * i
			cell_position += Common.get_half_offset(cell_position, half_offset_type)
			overlay.draw_line(cell_position, cell_position + direction, axis_color)
			direction = direction.tangent()
