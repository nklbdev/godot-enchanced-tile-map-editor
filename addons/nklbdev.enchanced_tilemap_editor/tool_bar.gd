extends HBoxContainer

const TreeBuilder = preload("tree_builder.gd")

const Common         = preload("common.gd")
const Selection      = preload("selection.gd")
const Paper          = preload("paper.gd")

# Instruments
const Instrument     = preload("instruments/_base.gd")
const InstrumentFreehand = preload("instruments/freehand.gd")
const InstrumentLine     = preload("instruments/line.gd")
const InstrumentRectangle     = preload("instruments/rectangle.gd")
const InstrumentFlood     = preload("instruments/flood.gd")
const InstrumentSame     = preload("instruments/same.gd")

# Brushes
const Brush    = preload("brushes/_base.gd")
const BrushSelection    = preload("brushes/selection.gd")
const BrushPattern    = preload("brushes/pattern.gd")
const BrushAutotile    = preload("brushes/autotile.gd")
const BrushTerrain    = preload("brushes/terrain.gd")

const __key_mode_map: Dictionary = {
	KEY_SHIFT: Common.InstrumentMode.MODE_A,
	KEY_CONTROL: Common.InstrumentMode.MODE_B,
	KEY_ALT: Common.InstrumentMode.MODE_C
}

const __button_map: Dictionary = {
	BUTTON_LEFT: Common.PatternType.FOREGROUND,
	BUTTON_RIGHT: Common.PatternType.BACKGROUND,
}

var __button_group: ButtonGroup
var __previous_visibility: bool
var __default_instrument_tool_button: ToolButton
var __last_instrument_tool_button: ToolButton
var __editor_scale: float = 1
var __cell_type_option_button: OptionButton

var __paper_holder: Common.ValueHolder = Common.ValueHolder.new()

var __selection_brush: BrushSelection
var __pattern_brush: BrushPattern
var __erasing_brush: BrushPattern
var __autotile_brush: BrushAutotile
var __terrain_brush: BrushTerrain

signal instruments_taken(left_handle, right_handle)
signal instruments_dropped(left_handle, right_handle)
signal cell_type_selected(cell_type)



func _init(drawing_settings: Common.DrawingSettings, editor_scale: float = 1) -> void:
	visible = false
	__editor_scale = editor_scale
	__previous_visibility = false
	__button_group = ButtonGroup.new()
	name = "EnchancedTileMapEditorToolBar"
	__selection_brush = BrushSelection.new(drawing_settings)
	__pattern_brush = BrushPattern.new(drawing_settings, Common.Pattern.new(Vector2.ONE * 3, PoolIntArray([
		0, 0, 2, 2,    0, 0, 3, 1,    0, 0, 3, 2,
		0, 0, 2, 1,    0, 0, 0, 0,    0, 0, 0, 1,
		0, 0, 1, 2,    0, 0, 1, 1,    0, 0, 0, 2,
	])))
	__erasing_brush = BrushPattern.new(drawing_settings, Common.Pattern.new(Vector2.ONE, PoolIntArray([TileMap.INVALID_CELL, 0, 0, 0])))
	__autotile_brush = BrushAutotile.new(drawing_settings)
	__terrain_brush = BrushTerrain.new(drawing_settings)

	__default_instrument_tool_button = __create_instrument_tool_button("Brush",     KEY_B,                  preload("icons/paint_tool_brush.svg"),     InstrumentFreehand.new(__pattern_brush, __paper_holder), InstrumentFreehand.new(__pattern_brush, __paper_holder))
	add_child(__create_instrument_tool_buttons_group("SelectionTools", [
#		__create_instrument_tool_button("Rectangle Selection", KEY_M,                  preload("icons/selection_tool_rectangle.svg"), HandlePair.new(__paper, TipRectangle.new())),
#		__create_instrument_tool_button("Lasso Selection",     KEY_Q,                  preload("icons/selection_tool_lasso.svg"),     HandleFreehand.new(__paper, TipPoly.new())),
#		__create_instrument_tool_button("Polygon Selection",   KEY_MASK_SHIFT | KEY_Q, preload("icons/selection_tool_polygon.svg"),   HandlePoly.new(__paper, TipPoly.new())),
#		__create_instrument_tool_button("Continous Selection", KEY_W,                  preload("icons/selection_tool_continous.svg"), HandleSingle.new(__paper, TipFlood.new())),
#		__create_instrument_tool_button("Same selection",      KEY_MASK_SHIFT | KEY_W, preload("icons/selection_tool_same.svg"),      HandleSingle.new(__paper, TipSame.new())),
	]))
	add_spacer(false)
	add_child(__create_instrument_tool_buttons_group("PaintTools", [
		__default_instrument_tool_button,
#		__create_instrument_tool_button("Bucket",    KEY_G,                  preload("icons/paint_tool_bucket.svg"),    HandleSingle.new(__paper, TipFlood.new())),
#		__create_instrument_tool_button("Contour",   KEY_D,                  preload("icons/paint_tool_contour.svg"),   HandleFreehand.new(__paper, TipPoly.new())),
		__create_instrument_tool_button("Eraser",    KEY_E,                  preload("icons/paint_tool_eraser.svg"),    InstrumentFreehand.new(__pattern_brush, __paper_holder), InstrumentFreehand.new(__pattern_brush, __paper_holder)),
		__create_instrument_tool_button("Line",      KEY_L,                  preload("icons/paint_tool_line.svg"),      InstrumentLine.new(__pattern_brush, __paper_holder), InstrumentLine.new(__pattern_brush, __paper_holder)),
#		__create_instrument_tool_button("Line",      KEY_L,                  preload("icons/paint_tool_line.svg"),      TipLine.new(__paper, BrushPencil.new())),
#		__create_instrument_tool_button("Polygon",   KEY_MASK_SHIFT | KEY_D, preload("icons/paint_tool_polygon.svg"),   HandlePoly.new(__paper, TipPoly.new())),
		__create_instrument_tool_button("Rectangle", KEY_U,                  preload("icons/paint_tool_rectangle.svg"), InstrumentRectangle.new(__pattern_brush, __paper_holder, false), InstrumentRectangle.new(__pattern_brush, __paper_holder, true)),
#		__create_instrument_tool_button("Classic Autotiler", KEY_U,          preload("icons/paint_tool_rectangle.svg"), HandleFreehand.new(TipLine.new(BrushAutotile.new())), HandleFreehand.new(TipLine.new(BrushAutotile.new()))),
#		__create_instrument_tool_button("Terrain brush", KEY_U,          preload("icons/paint_tool_rectangle.svg"), HandleFreehand.new(TipLine.new(BrushTerrain.new())), HandleFreehand.new(TipLine.new(BrushTerrain.new()))),
	]))
	__cell_type_option_button = __create_cell_type_option_button()
	add_child(__cell_type_option_button)
	connect("visibility_changed", self, "__on_visibility_changed")

func set_up(paper: Paper) -> void:
	__paper_holder.value = paper
	visible = true

func tear_down() -> void:
	__paper_holder.value = null
	visible = false

func __on_instrument_tool_button_toggled(pressed: bool, tool_button: ToolButton, left_instrument: Instrument, right_instrument: Instrument) -> void:
	if pressed:
		__last_instrument_tool_button = tool_button
		emit_signal("instruments_taken", left_instrument, right_instrument)
	else:
		emit_signal("instruments_dropped", left_instrument, right_instrument)

func __on_cell_type_option_button_selected(item_index: int) -> void:
	__pattern_brush.cell_type = __cell_type_option_button.get_item_metadata(item_index)
#	emit_signal("cell_type_selected", __cell_type_option_button.get_item_metadata(item_index))


func __on_visibility_changed() -> void:
	if visible == __previous_visibility:
		return
	if visible:
		assert(__button_group.get_pressed_button() == null)
		var button = __default_instrument_tool_button if __last_instrument_tool_button == null else __last_instrument_tool_button
		button.pressed = true
	else:
		var current_instrument_tool_button = __button_group.get_pressed_button()
		if current_instrument_tool_button:
			current_instrument_tool_button.pressed = false
	__previous_visibility = visible



func __create_shortcut(scancode_with_modifiers: int) -> ShortCut:
	var event = InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.shift = scancode_with_modifiers & KEY_MASK_SHIFT
	event.alt = scancode_with_modifiers & KEY_MASK_ALT
	event.meta = scancode_with_modifiers & KEY_MASK_META
	event.control = scancode_with_modifiers & KEY_MASK_CTRL
	event.command = scancode_with_modifiers & KEY_MASK_CMD
	event.scancode = scancode_with_modifiers & KEY_CODE_MASK
	var shortcut = ShortCut.new()
	shortcut.shortcut = event
	return shortcut

func __create_instrument_tool_button(tooltip: String, scancode_with_modifiers: int, icon: Texture, left_instrument: Instrument, right_instrument: Instrument) -> ToolButton:
	var tool_button = ToolButton.new()
	tool_button.focus_mode = Control.FOCUS_NONE
	tool_button.hint_tooltip = tooltip
	tool_button.icon = Common.resize_texture(icon, __editor_scale / 4)
	tool_button.toggle_mode = true
	tool_button.group = __button_group
	tool_button.shortcut_in_tooltip = true
	tool_button.shortcut = __create_shortcut(scancode_with_modifiers)
	tool_button.connect("toggled", self, "__on_instrument_tool_button_toggled", [tool_button, left_instrument, right_instrument])
	return tool_button

func __create_instrument_tool_buttons_group(group_name: String, instrument_tool_buttons: Array) -> HBoxContainer:
	var instrument_tool_buttons_container = HBoxContainer.new()
	instrument_tool_buttons_container.name = group_name
	for instrument_tool_button in instrument_tool_buttons:
		instrument_tool_buttons_container.add_child(instrument_tool_button)
	return instrument_tool_buttons_container

func __create_cell_type_option_button() -> OptionButton:
	var ob = OptionButton.new()
	ob.flat = true
	ob.clip_text = true
	ob.add_icon_item(preload("icons/png/cell_type_hex.png"), "Hexademic")
	ob.set_item_metadata(0, 0)
	ob.add_icon_item(preload("icons/png/cell_type_tet.png"), "Tetrademic")
	ob.set_item_metadata(1, 1)
	ob.add_icon_item(preload("icons/png/cell_type_map.png"), "Map")
	ob.set_item_metadata(2, 2)
	ob.add_icon_item(preload("icons/png/cell_type_map.png"), "Pattern")
	ob.set_item_metadata(3, 3)
	ob.connect("item_selected", self, "__on_cell_type_option_button_selected")
	return ob
