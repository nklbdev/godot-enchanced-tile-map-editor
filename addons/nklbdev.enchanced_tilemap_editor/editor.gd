tool
extends EditorPlugin

const Common = preload("common.gd")
const Selection = preload("selection.gd")
const BottomPanel = preload("bottom_panel.gd")
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

var __bottom_panel: BottomPanel
var __selection: Selection

var __canvas_item_visibility_controller: CanvasItemVisibilityController
var __is_mouse_on_overlay: bool

var __visual_root: Node2D
var __settings: Common.Settings
var __tile_map_paper: Paper

var __active_instrument: Instrument
func __set_active_instrument(instrument: Instrument) -> void:
	if instrument == __active_instrument:
		return
	__active_instrument = instrument
	update_overlays()
var __instrument: Instrument setget __set_instrument
func __set_instrument(value: Instrument) -> void:
	if value != __instrument:
		__instrument = value
	if __active_instrument == null:
		update_overlays()


##########################################
#           OVERRIDEN METHODS            #
##########################################

func _init():
	name = "EnchancedTileMapEditorPlugin"
	

func _enter_tree() -> void:
	var editor_interface = get_editor_interface()
	Common.set_up_statics(editor_interface)
	Common.print_log("_enter_tree")
	
	__settings = Common.get_static(Common.Statics.SETTINGS) as Common.Settings

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
	__tile_map_paper.connect("changes_committed", self, "__on_tile_map_paper_changes_committed")
	var __autotile_paper = Paper.new()
	var __terrain_paper = Paper.new()
	__selection = Selection.new()
	__visual_root.add_child(__selection.get_selection_map())
	__visual_root.add_child(__selection.get_selection_operand_map())
	
	__bottom_panel = BottomPanel.new(__selection, __tile_map_paper, __autotile_paper, __terrain_paper)
	__bottom_panel.connect("instrument_changed", self, "__on_instrument_changed")
	add_control_to_bottom_panel(__bottom_panel, "Tile Map")

func __on_tile_map_paper_changes_committed(tile_map: TileMap, backup: Dictionary) -> void:
	if backup.empty():
		return
	var original_state: Dictionary = backup.duplicate()
	var current_state: Dictionary
	for cell in backup.keys():
		current_state[cell] = Common.get_map_cell_data(tile_map, cell)
	var undo_redo: UndoRedo = get_undo_redo()
	undo_redo.create_action("Change TileMap Cells")
	undo_redo.add_undo_method(self, "__change_tile_map_cells", tile_map, original_state)
	undo_redo.add_do_method(self, "__change_tile_map_cells", tile_map, current_state)
	undo_redo.commit_action()

func __change_tile_map_cells(tile_map: TileMap, changes: Dictionary) -> void:
	for cell in changes.keys():
		Common.set_map_cell_data(tile_map, cell, changes[cell])

func _exit_tree() -> void:
	Common.print_log("_exit_tree")
	__tear_down()
	__overlay.disconnect("mouse_entered", self, "__on_overlay_mouse_entered")
	__overlay.disconnect("mouse_exited", self, "__on_overlay_mouse_exited")
	
	__canvas_item_visibility_controller.unlock_all()
	__canvas_item_visibility_controller = null
	
	remove_control_from_bottom_panel(__bottom_panel)
	__bottom_panel = null
	
	__visual_root.queue_free()
	__visual_root = null
	Common.tear_down_statics()

func handles(object: Object) -> bool:
	var result = object is TileMap and is_instance_valid(object)
	Common.print_log("handles(%s) -> %s" % [Common.to_string_pretty(object), result])
	return result

func __set_up(tile_map: TileMap) -> void:
	assert(__tile_map == null)
	assert(tile_map != null)
	__tile_map = tile_map
	__bottom_panel.set_up(__tile_map)
	__tile_map_paper.set_up(__tile_map)
	__selection.set_up(__tile_map)
	__original_tile_map_editor._node_removed(__tile_map)
	__original_tile_map_editor.hide()

func __tear_down() -> void:
	if __tile_map:
		__selection.tear_down()
		__tile_map_paper.tear_down()
		__tile_map = null
		__bottom_panel.tear_down()


# called with true right after edit(object)
# called with false on work with object is finished
# can be called with false multiple times
func make_visible(visible: bool) -> void:
	Common.print_log("make_visible(%s)" % [visible])
	if visible:
		make_bottom_panel_item_visible(__bottom_panel)
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
	return Common.get_cell_base_transform(__tile_map).affine_inverse().xform(__tile_map.get_local_mouse_position())

var __dragging_button: int
const __dragging_buttons: PoolIntArray = PoolIntArray([BUTTON_LEFT, BUTTON_RIGHT])
func forward_canvas_gui_input(event: InputEvent) -> bool:
	if __tile_map == null or not __select_tool_button.pressed:
		return false

	var is_event_consumed: bool
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			if event.button_index in __dragging_buttons:
				if event.pressed:
					if __dragging_button == 0:
						__dragging_button = event.button_index
						__set_active_instrument(__instrument if __dragging_button == BUTTON_LEFT else __bottom_panel.get_alternate_instrument())
						if __active_instrument:
							__active_instrument.move_to(__get_mouse_position())
							__active_instrument.push()
					else:
						if event.button_index != __dragging_button:
							__dragging_button = 0
							if __active_instrument:
								__active_instrument.pull(true)
								__set_active_instrument(null)
				else:
					if event.button_index == __dragging_button:
						__dragging_button = 0
						if __active_instrument:
							__active_instrument.pull()
							__set_active_instrument(null)
				is_event_consumed = true
		elif event is InputEventMouseMotion:
			var instrument = __active_instrument if __active_instrument else __instrument
			if instrument:
				instrument.move_to(__get_mouse_position())
				is_event_consumed = true
	elif event is InputEventKey:
		if __active_instrument:
			if event.scancode == KEY_ESCAPE:
				if event.pressed:
					if __active_instrument:
						__active_instrument.pull(true)
						__set_active_instrument(null)
						is_event_consumed = true
			else:
				is_event_consumed = __active_instrument.process_input_event_key(event)
		if not is_event_consumed:
			is_event_consumed = __selection.process_input_event_key(event)
		if not is_event_consumed:
			is_event_consumed = __bottom_panel.process_input_event_key(event)
	if is_event_consumed:
		update_overlays()
	return is_event_consumed

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	__draw(overlay)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	__draw(overlay, true)

func __draw(overlay: Control, force: bool = false) -> void:
	if __tile_map == null or not __select_tool_button.pressed:
		return
	__visual_root.transform = \
		__tile_map.get_viewport_transform() * \
		__tile_map.get_global_transform() * \
		Common.get_cell_base_transform(__tile_map)
	overlay.draw_set_transform_matrix(__visual_root.transform)
	var instrument: Instrument = __active_instrument if __active_instrument else __instrument
	if instrument:
		instrument.draw(overlay)
	__draw_grid(overlay)
	overlay.draw_set_transform_matrix(Transform2D.IDENTITY)

##########################################
#            PRIVATE METHODS             #
##########################################

func __on_overlay_mouse_entered() -> void:
	__is_mouse_on_overlay = true
	if __tile_map and __select_tool_button.pressed:
		update_overlays()

func __on_overlay_mouse_exited() -> void:
	__is_mouse_on_overlay = false
	if __tile_map and __select_tool_button.pressed:
		update_overlays()

func __on_instrument_changed() -> void:
	__set_instrument(__bottom_panel.get_instrument())

func __on_select_tool_button_toggled(pressed: bool) -> void:
	update_overlays()

const Algorithms = preload("algorithms.gd")
var __temp_grid_color: Color
func __draw_grid(overlay: Control):
	if __tile_map == null or not __select_tool_button.pressed:
		return

	var cell_half_offset_type = __tile_map.cell_half_offset
	var cell_position: Vector2

	# Draw axis fragment
	var axis_color: Color = __settings.axis_color
	for i in __settings.axis_fragment_radius + 1:
		axis_color.a = __settings.axis_color.a * (1 - float(i) / __settings.axis_fragment_radius)
		var direction = Vector2.RIGHT
		for r in 4:
			cell_position = direction * (i + int(r > 1))
			cell_position += Common.get_cell_half_offset(cell_position, cell_half_offset_type)
			overlay.draw_line(cell_position, cell_position + direction.abs(), axis_color)
			direction = direction.tangent()
