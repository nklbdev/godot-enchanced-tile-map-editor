extends "_subpalette.gd"

const TB = preload("../tree_builder.gd")
const Patterns = preload("../patterns.gd")

class ClippingContentPanel:
	extends Panel

	func _init() -> void:
		rect_clip_content = true

	func _clips_input() -> bool:
		return true

class Tile:
	extends Control
	var tile_id: int
	func unselect() -> void:
		assert(false)

var _content: Control
var __content_panel: Panel
var __content_holder: Control
var __content_scaler: Control
var __zoom_reset_button: ToolButton
var __center_view_button: ToolButton
var __content_zoom: float = 1.0
var EDSCALE: float
var _previous_selected_tile: Tile
var _selected_pattern: Patterns.Pattern
var _settings: Common.Settings = Common.get_static(Common.Statics.SETTINGS)

func _init(title: String, icon_name: String).(title, icon_name) -> void:
	EDSCALE = Common.get_static(Common.Statics.EDITOR_SCALE)
	var tb = TreeBuilder.tree(self)

	tb.node(self).with_children([
		tb.node(HSplitContainer.new()) \
			.with_props({anchor_right = 1, anchor_bottom = 1,}) \
			.with_children([
				tb.node(_item_list) \
					.with_props({
						anchor_right = 1, anchor_bottom = 1,
						size_flags_vertical = SIZE_EXPAND_FILL,
						max_columns = 0,
						same_column_width = true,
						icon_mode = ItemList.ICON_MODE_TOP,
						icon_scale = 0.5,
						fixed_icon_size = Vector2.ONE * 256,
						rect_min_size = Vector2.RIGHT * 128 }),
				tb.node(ClippingContentPanel.new(), "__content_panel") \
					.connected("gui_input", "__on_content_panel_gui_input") \
					.connected("resized", "__on_content_panel_resized") \
					.with_props({
						size_flags_vertical = SIZE_EXPAND_FILL,
						rect_clip_content = true }) \
					.with_children([
						tb.node(Control.new(), "__content_scaler") \
							.with_props({ mouse_filter = MOUSE_FILTER_PASS, rect_scale = Vector2.ONE * EDSCALE }) \
							.with_children([
								tb.node(Control.new(), "__content_holder") \
								.with_props({ mouse_filter = MOUSE_FILTER_PASS })]),
						tb.node(HBoxContainer.new()) \
							.with_props({ anchor_right = 1, mouse_filter = MOUSE_FILTER_IGNORE, }) \
							.with_overrides({ separation = round(-8 * EDSCALE) }) \
							.with_children([
								tb.node(ToolButton.new()).with_props({
									icon = Common.get_icon("zoom_less"),
									hint_tooltip = "Zoom Out",
									focus_mode = FOCUS_NONE,
									shortcut = Common.create_shortcut(KEY_MASK_CMD | KEY_MINUS),
								}).connected("pressed", "__zoom_content", [_settings.palette_zoom_step_factor]),
								tb.node(ToolButton.new(), "__zoom_reset_button").with_props({
									hint_tooltip = "Zoom Reset",
									focus_mode = FOCUS_NONE,
									shortcut = Common.create_shortcut(KEY_MASK_CMD | KEY_0),
									align = Button.ALIGN_CENTER,
									rect_min_size = Vector2.RIGHT * 75 * EDSCALE,
								}).connected("pressed", "__set_content_zoom", [EDSCALE]),
								tb.node(ToolButton.new()).with_props({
									icon = Common.get_icon("zoom_more"),
									hint_tooltip = "Zoom In",
									focus_mode = FOCUS_NONE,
									shortcut = Common.create_shortcut(KEY_MASK_CMD | KEY_PLUS),
								}).connected("pressed", "__zoom_content", [1 / _settings.palette_zoom_step_factor]),
							]),
						tb.node(ToolButton.new(), "__center_view_button").with_props({
							icon = Common.get_icon("center_view"),
							hint_tooltip = "Center View",
							focus_mode = FOCUS_NONE,
							disabled = true,
#							shortcut = Common.create_shortcut(KEY_MASK_CMD | KEY_PLUS),
						}).connected("pressed", "__center_view")
					])
			])
		]).build()
	__center_view_button.set_anchors_and_margins_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE)


func _before_tear_down() -> void:
	unselect()
	__clear_content_viewport()

func _on_item_list_item_selected(index: int, metadata) -> void:
	__clear_content_viewport()
	_content = _item_list.get_item_metadata(index)
	__content_holder.add_child(_content)
	__center_view()
	__set_content_zoom(EDSCALE)
	if _content.has_meta("content_holder_position"):
		__content_holder.rect_position = _content.get_meta("content_holder_position")
	if _content.has_meta("content_scaler_position"):
		__content_scaler.rect_position = _content.get_meta("content_scaler_position")
	if _content.has_meta("content_scaler_scale"):
		__content_scaler.rect_scale = _content.get_meta("content_scaler_scale")
	if _content.has_meta("content_zoom"):
		__content_zoom = _content.get_meta("content_zoom")
	__update_zoom_label()
	__update_center_view_button()

func _on_unselect() -> void:
	if _previous_selected_tile:
		_previous_selected_tile.unselect()
		_previous_selected_tile = null
	_selected_pattern = null

func __clear_content_viewport() -> void:
	if _content:
		_content.set_meta("content_holder_position", __content_holder.rect_position)
		_content.set_meta("content_scaler_position", __content_scaler.rect_position)
		_content.set_meta("content_scaler_scale", __content_scaler.rect_scale)
		_content.set_meta("content_zoom", __content_zoom)
		__content_holder.remove_child(_content)
		_content = null
	__center_view()
	__content_scaler.rect_scale = Vector2.ONE * EDSCALE

func __center_view() -> void:
	__center_view_button.disabled = true
	__content_scaler.rect_position = __get_content_panel_center()
	__content_holder.rect_position = Vector2.ZERO

func __update_center_view_button() -> void:
	__center_view_button.disabled = \
		(__content_scaler.get_transform() * __content_holder.get_transform()) \
		.origin.is_equal_approx(__get_content_panel_center())

func __update_zoom_label() -> void:
	# The zoom level displayed is relative to the editor scale
	# (like in most image editors). Its lower bound is clamped to 1 as some people
	# lower the editor scale to increase the available real estate,
	# even if their display doesn't have a particularly low DPI.
	# Don't show a decimal when the zoom level is higher than 1000 %.
	var zoom: float = (__content_zoom / max(1, EDSCALE)) * 100
	__zoom_reset_button.text = "%s %%" % [round(zoom) if __content_zoom >= 10 else stepify(zoom, 0.1)]

func __zoom_content(factor: float, origin: Vector2 = __get_content_panel_center()) -> void:
	__set_content_zoom(__content_zoom * factor, origin)

func __get_content_panel_center() -> Vector2:
	return __content_panel.rect_size / 2

func __set_content_zoom(zoom: float, origin: Vector2 = __get_content_panel_center()) -> void:
	if is_equal_approx(zoom, __content_zoom):
		return
	var previous_content_holder_global_position = __content_holder.rect_global_position
	__content_scaler.rect_position = origin
	__content_holder.rect_global_position = previous_content_holder_global_position
	__content_scaler.rect_scale = Vector2.ONE * zoom
	__content_zoom = zoom
	__update_zoom_label()
	__update_center_view_button()

var __warping: bool
var __content_dragging_button: int
func __on_content_panel_gui_input(event: InputEvent) -> void:
	if _content == null:
		return
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			if event.pressed:
				match event.button_index:
					BUTTON_LEFT, BUTTON_MIDDLE, BUTTON_RIGHT:
						if event.button_index != BUTTON_LEFT or event.control:
							__content_dragging_button = event.button_index
							return
			else:
				if event.button_index == __content_dragging_button:
					__content_dragging_button = 0
					return
				else:
					match event.button_index:
						BUTTON_WHEEL_UP:
							__zoom_content(_settings.palette_zoom_step_factor, event.position)
							return
						BUTTON_WHEEL_DOWN:
							__zoom_content(1 / _settings.palette_zoom_step_factor, event.position)
							return
		
		elif event is InputEventMouseMotion:
			if __content_dragging_button > 0:
				if __warping:
					__warping = false
				else:
					__content_scaler.rect_position += event.relative
					__update_center_view_button()
				var warped_mouse_position: Vector2 = event.position.posmodv(__content_panel.rect_size)
				if event.position != warped_mouse_position:
					__warping = true
					__content_panel.warp_mouse(warped_mouse_position)
	elif event is InputEventPanGesture:
		__content_scaler.rect_position -= event.delta * 20.0
		__update_center_view_button()
	if __content_dragging_button == 0:
		_post_process_content_panel_gui_input(event)

func _post_process_content_panel_gui_input(event: InputEvent) -> void:
	pass


onready var __previous_content_panel_center: Vector2 = __content_panel.rect_size / 2
func __on_content_panel_resized() -> void:
	var center = __get_content_panel_center()
	__content_scaler.rect_position += center - __previous_content_panel_center
	__previous_content_panel_center = center

func _on_tile_region_selected(region: Rect2, tile: Tile, offsetted: bool = false) -> void:
	if _previous_selected_tile and _previous_selected_tile != tile:
		_previous_selected_tile.unselect()
	_previous_selected_tile = tile
	region = region.abs()
	var data: PoolIntArray = PoolIntArray()
	data.resize(region.size.x * region.size.y * 4)
	var cell_idx: int
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			data[cell_idx    ] = tile.tile_id
			data[cell_idx + 1] = 0 # transformation
			data[cell_idx + 2] = x
			data[cell_idx + 3] = y
			cell_idx += 4
	_selected_pattern = Patterns.Pattern.new(region.size, data)
	emit_signal("selected", _selected_pattern)
