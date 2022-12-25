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
var __drawing_settings: Common.DrawingSettings
var __current_instrument: Instrument
var __default_instrument: Instrument
var __instruments: Dictionary
var __paper: Paper

##########################################
#           OVERRIDEN METHODS            #
##########################################

func _init():
	name = "EnchancedTileMapEditorPlugin"

func _enter_tree() -> void:
	Common.print_log("_enter_tree")

	var editor_interface = get_editor_interface()

	ProjectSettings.connect("project_settings_changed", self, "__scan_settings")
	__editor_settings = editor_interface.get_editor_settings()
	__editor_settings.connect("settings_changed", self, "__scan_settings")
	__drawing_settings = Common.DrawingSettings.new()
	__scan_settings()

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
	__selection = Selection.new()
	__visual_root.add_child(__selection)
	
	var editor_scale = editor_interface.get_editor_scale()
	__palette = Palette.new(editor_scale)
	add_control_to_bottom_panel(__palette, "Tile Palette")
	__tool_bar = ToolBar.new(__visual_root, __selection, __drawing_settings, editor_scale)
	context_menu_hbox.add_child(__tool_bar)
	__tool_bar.connect("instruments_taken", self, "__on_tool_bar_instruments_taken")
	__tool_bar.connect("instruments_dropped", self, "__on_tool_bar_instruments_dropped")
	__tool_bar.connect("cell_type_selected", self, "__on_tool_bar_cell_type_selected")
	

func _exit_tree() -> void:
	Common.print_log("_exit_tree")
	__overlay.disconnect("mouse_entered", self, "__on_overlay_mouse_entered")
	__overlay.disconnect("mouse_exited", self, "__on_overlay_mouse_exited")
	
	__canvas_item_visibility_controller.unlock_all()
	__canvas_item_visibility_controller = null
	__editor_settings.disconnect("settings_changed", self, "__scan_settings")
	ProjectSettings.disconnect("project_settings_changed", self, "__scan_settings")
	
	__tool_bar.queue_free()
	__tool_bar = null
	remove_control_from_bottom_panel(__palette)
	__palette = null
	
	__visual_root.queue_free()
	__visual_root = null
	__selection = null

func handles(object: Object) -> bool:
	var result = object is TileMap and is_instance_valid(object)
	Common.print_log("handles(%s) -> %s" % [Common.to_string_pretty(object), result])
	return result

# called with true right after edit(object)
# called with false on work with object is finished
# can be called with false multiple times
func make_visible(visible: bool) -> void:
	Common.print_log("make_visible(%s)" % [visible])
	assert(not (__tile_map == null and __tool_bar.visible), \
		"inconsistent state: the plugin is visible without edited object")
	assert(not (__tile_map == null and not __tool_bar.visible and visible), \
		"invalid operation: set plugin visible without edited object")
	assert(not (__tile_map != null and __tool_bar.visible and visible), \
		"invalid operation: set plugin visible more than once in a row")
	if visible == __tool_bar.visible:
		return
	if visible:
		__tool_bar.visible = true
	else:
		__paper = null
		__tile_map = null
		__tool_bar.visible = false
		__palette.set_tile_set(null)
	pass

# can be called only if visible == false
# recalled on rename node with visibility blink
# but when user selects other TileMap after previous, visibility not changes
func edit(object: Object) -> void:
	Common.print_log("edit %s" % object)
	# при переключении карты с одной на другую, тут будет старая.
	assert(__tile_map == null, "на данный момент не должно быть текущей тайловой карты")
	__tile_map = object as TileMap
	__palette.set_tile_set(__tile_map.tile_set)
	__paper = Paper.new(__tile_map)
	assert(__tile_map != null, "тайловая карта должна быть обязательно передана")
	__original_tile_map_editor._node_removed(__tile_map)
	__original_tile_map_editor.hide()
	__selection.clear()

func has_main_screen() -> bool:
	Common.print_log("has_main_screen")
	return false

func __is_event_is_mouse_button_pressed_outside_viewport(event: InputEvent) -> bool:
	return event is InputEventMouseButton and \
		event.pressed and \
		not __overlay.get_rect().has_point(__overlay.get_local_mouse_position())

func __get_mouse_hex_cell() -> Vector2:
	assert(__tile_map != null)
	var zero: Vector2 = __tile_map.map_to_world(Vector2.ZERO)
	return (Transform2D(
		(__tile_map.map_to_world(Vector2.RIGHT * 2) - zero) / 2,
		(__tile_map.map_to_world(Vector2.DOWN * 2)  - zero) / 2,
		zero
		).affine_inverse().xform(__tile_map.get_local_mouse_position()) * 4).floor()

func forward_canvas_gui_input(event: InputEvent) -> bool:
	if __tile_map == null:
		return false

	var is_event_consumed: bool
	if event is InputEventMouseButton:
		var instrument: Instrument = __instruments.get(event.button_index)
		if instrument == null:
			pass
		elif event.pressed:
			if __current_instrument == null: # нет текущего рисования
				__current_instrument = instrument
				__current_instrument.push()
			elif instrument != __current_instrument: # есть текущее рисование, но нажата кнопка другого инструмента
				__current_instrument.interrupt()
				__current_instrument = null
			is_event_consumed = true
		else:
			if instrument == __current_instrument:
				__current_instrument.pull()
				__current_instrument = null
			is_event_consumed = true
	elif event is InputEventMouseMotion:
		var mouse_hex_cell = __get_mouse_hex_cell()
		for instrument in __instruments.values():
			instrument.move_to(mouse_hex_cell)
#		__right_instrument.move_to(mouse_hex_cell)
		is_event_consumed = true
#	elif event is InputEventKey and not event.echo:
#		var mode_flag = __key_mode_map.get(event.scancode, Common.InstrumentMode.NONE)
#		if mode_flag:
#			if event.pressed: current_instrument_tool_button.instrument.mode |=  mode_flag
#			else:             current_instrument_tool_button.instrument.mode &= ~mode_flag
#			return true
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
	var zero: Vector2 = __tile_map.map_to_world(Vector2.ZERO)
	# hack to skip half-offsetted row or column
	var right: Vector2 = (__tile_map.map_to_world(Vector2.RIGHT * 2) - zero) / 2
	var down: Vector2 = (__tile_map.map_to_world(Vector2.DOWN * 2)  - zero) / 2
	var cell_base_transform: Transform2D = Transform2D(right, down, zero)
	
	__visual_root.transform = __tile_map.get_viewport_transform() * __tile_map.get_global_transform() * cell_base_transform
	overlay.draw_set_transform_matrix(__visual_root.transform)
	(__current_instrument if __current_instrument else __default_instrument).draw(overlay, __tile_map)
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
	__default_instrument = left_instrument
	left_instrument.set_up(__paper)
	right_instrument.set_up(__paper)

func __on_tool_bar_instruments_dropped(left_instrument: Instrument, right_instrument: Instrument) -> void:
	assert(not __instruments.empty())
	assert(__instruments[BUTTON_LEFT] == left_instrument)
	assert(__instruments[BUTTON_RIGHT] == right_instrument)
	for instrument in __instruments.values():
		if instrument.is_pushed():
			instrument.pull()
		if instrument.is_ready():
			instrument.tear_down()
	__current_instrument = null
	__default_instrument = null
	__instruments.clear()

func __on_tool_bar_cell_type_selected(cell_type: int) -> void:
	__paper.cell_type = cell_type

func __on_select_tool_button_toggled(pressed: bool) -> void:
	if pressed:
		# выбрать первый инструмент
		pass
	else:
		# выбрать первый инструмент
		var pressed_tool_buton: BaseButton = __tool_bar.__button_group.get_pressed_button()
		if pressed_tool_buton:
			pressed_tool_buton.pressed = true

const plugin_settings_section = "enchanced_tile_map_editor/"
func __add_project_setting(setting_name: String, type: int, value) -> bool:
	var setting_path = plugin_settings_section + setting_name
	if ProjectSettings.has_setting(setting_path):
		return false
	ProjectSettings.set_setting(setting_path, value)
	ProjectSettings.add_property_info({
		"name": setting_path,
		"type": type,
#			"hint": PROPERTY_HINT_COL,
#		"hint_string": "Color of cursor"
		})
	ProjectSettings.set_initial_value(name, value)
	return true

func __scan_settings():
	var s: bool
	s = true if __add_project_setting("cursor_color", TYPE_COLOR, Color(1, 0.5, 0.25, 0.5)) else s
	s = true if __add_project_setting("drawn_cells_color", TYPE_COLOR, Color(1, 0.5, 0.25, 0.25)) else s
	s = true if __add_project_setting("grid_fragment_radius", TYPE_INT, 10) else s
	s = true if __add_project_setting("axis_fragment_radius", TYPE_INT, 20) else s
	s = true if __add_project_setting("cursor_color", TYPE_COLOR, Color(1, 0.5, 0.25, 0.5)) else s
	if s:
		var err = ProjectSettings.save()
		if err: push_error("Can't save project settings")
	
	__drawing_settings.display_grid_enabled = __editor_settings.get_setting("editors/tile_map/display_grid")
	__drawing_settings.grid_color = __editor_settings.get_setting("editors/tile_map/grid_color")
	__drawing_settings.axis_color = __editor_settings.get_setting("editors/tile_map/axis_color")
	__drawing_settings.cursor_color = ProjectSettings.get_setting(plugin_settings_section + "cursor_color")
	__drawing_settings.drawn_cells_color = ProjectSettings.get_setting(plugin_settings_section + "drawn_cells_color")
	__drawing_settings.grid_fragment_radius = ProjectSettings.get_setting(plugin_settings_section + "grid_fragment_radius")
	__drawing_settings.axis_fragment_radius = ProjectSettings.get_setting(plugin_settings_section + "axis_fragment_radius")

const CELL_LINES_POINTS: PoolVector2Array = PoolVector2Array([
	Vector2(0, 0   ), Vector2(1, 0   ),
	Vector2(0,    0), Vector2(0,    1),
])

const CELL_SUBLINES_POINTS: PoolVector2Array = PoolVector2Array([
	Vector2( 0,   -0.25), Vector2( 1,   -0.25),
	Vector2( 0,    0.25), Vector2( 1,    0.25),
	Vector2(-0.25, 0   ), Vector2(-0.25, 1   ),
	Vector2( 0.25, 0   ), Vector2( 0.25, 1   ),
])

func __draw_grid(overlay: Control):
	if __tile_map == null:
		return

	if __is_mouse_on_overlay or __current_instrument:
		var mouse_world_position = __get_mouse_hex_cell() / 4
		overlay.draw_rect(__paper.get_cell_world_rect(__paper.get_cell_in_world(mouse_world_position)), __drawing_settings.cursor_color)

		# Draw grid fragment
		var grid_color: Color = __drawing_settings.grid_color
		var mouse_map_cell: Vector2 = __paper.get_cell_in_world(mouse_world_position, Paper.CELL_TYPE_MAP)# __tile_map.world_to_map(__tile_map.get_local_mouse_position())
		var draw_transform = __visual_root.transform
		for y in range(mouse_map_cell.y - __drawing_settings.grid_fragment_radius, mouse_map_cell.y + __drawing_settings.grid_fragment_radius + 1):
			for x in range(mouse_map_cell.x - __drawing_settings.grid_fragment_radius, mouse_map_cell.x + __drawing_settings.grid_fragment_radius + 1):
				var map_cell_position = __paper.get_cell_world_rect(Vector2(x, y), Paper.CELL_TYPE_MAP).position # __paper.get_half_offsetted_map_cell_position(Vector2(x, y))
#				var d = __paper.get_cell_world_rect(mouse_map_cell, Paper.CELL_TYPE_MAP)
				overlay.draw_set_transform_matrix(draw_transform.translated(map_cell_position))
				grid_color.a = __drawing_settings.grid_color.a * (1 - mouse_map_cell.distance_squared_to(map_cell_position) / __drawing_settings.grid_fragment_radius_squared)
				overlay.draw_multiline(CELL_LINES_POINTS, grid_color)
				grid_color.a /= 3
				overlay.draw_multiline(CELL_SUBLINES_POINTS, grid_color)
		overlay.draw_set_transform_matrix(__visual_root.transform)


	# Draw axis fragment
	var axis_color: Color = __drawing_settings.axis_color
	var cell_position: Vector2
	for i in __drawing_settings.axis_fragment_radius + 1:
		axis_color.a = __drawing_settings.axis_color.a * (1 - float(i) / __drawing_settings.axis_fragment_radius)
		cell_position = __paper.get_cell_world_rect(Vector2(i, 0), Paper.CELL_TYPE_MAP).position
		overlay.draw_line(cell_position, cell_position + Vector2.RIGHT, axis_color)
		overlay.draw_line(- cell_position, - cell_position + Vector2.LEFT, axis_color)
		cell_position = __paper.get_cell_world_rect(Vector2(0, i), Paper.CELL_TYPE_MAP).position
		overlay.draw_line(cell_position, cell_position + Vector2.DOWN, axis_color)
		overlay.draw_line(- cell_position, - cell_position + Vector2.UP, axis_color)
#	for x in __drawing_settings.axis_fragment_radius + 1:
#		cell_position = __paper.get_half_offsetted_map_cell_position(Vector2(x, 0))
#		axis_color.a = __drawing_settings.axis_color.a * (1 - abs(x) / __drawing_settings.axis_fragment_radius)
#		overlay.draw_line(cell_position, cell_position + Vector2.RIGHT, axis_color, false)
#		overlay.draw_line(- cell_position, cell_position + Vector2.LEFT, axis_color, false)
	
#	for y in range(- __drawing_settings.axis_fragment_radius, __drawing_settings.axis_fragment_radius + 1):
#		var cell_position = __paper.get_cell_world_rect(Vector2(0, y)).position
#		axis_color.a = __drawing_settings.axis_color.a * (1 - abs(y) / __drawing_settings.axis_fragment_radius)
#		overlay.draw_line(cell_position, cell_position + Vector2.DOWN, axis_color, false)
#	for x in range(- __drawing_settings.axis_fragment_radius, __drawing_settings.axis_fragment_radius + 1):
#		var cell_position = __paper.get_half_offsetted_map_cell_position(Vector2(x, 0))
#		axis_color.a = __drawing_settings.axis_color.a * (1 - abs(x) / __drawing_settings.axis_fragment_radius)
#		overlay.draw_line(cell_position, cell_position + Vector2.RIGHT, axis_color, false)
