extends "_base.gd"

const TB = preload("../tree_builder.gd")

const Paper = preload("../paper.gd")
const Selection = preload("../selection.gd")
const Patterns = preload("../patterns.gd")

const TilesByTextureSubpalette  = preload("subpalette_tiles_by_texture.gd")
const TilesIndividualSubpalette = preload("subpalette_tiles_individual.gd")
const TilesPatternsSubpalette   = preload("subpalette_tiles_patterns.gd")

# Instruments
const InstrumentCombined  = preload("../instruments/combined.gd")
const InstrumentStamp     = preload("../instruments/stamp.gd")
const InstrumentLine      = preload("../instruments/line.gd")
const InstrumentRectangle = preload("../instruments/rectangle.gd")
const InstrumentFlood     = preload("../instruments/flood.gd")
const InstrumentPicker    = preload("../instruments/picker.gd")


var __brush_instrument_tool_button: ToolButton

var __place_random_tile_button: ToolButton
var __scattering_controls: HBoxContainer
var __scattering_spin_box: SpinBox

func _init(selection_paper: Selection, tiles_paper: Paper, eraser: Instrument).("Tiles", "tiles", [
	TilesByTextureSubpalette.new(),
	TilesIndividualSubpalette.new(),
	TilesPatternsSubpalette.new()]) -> void:

	var selection_map: TileMap = selection_paper.get_selection_map()
	selection_paper.connect("pattern_copied", self, "__on_selection_pattern_copied")
	var selection_pattern_holder: Common.ValueHolder = Common.ValueHolder.new(Patterns.Pattern.new(Vector2.ONE, PoolIntArray([0, 0, 0, 0])))

	var instrument_line: InstrumentLine = InstrumentLine.new(_pattern_holder, tiles_paper, selection_map)
	var instrument_rectangle: InstrumentRectangle = InstrumentRectangle.new(_pattern_holder, tiles_paper, selection_map)
	var instrument_bucket_fill: InstrumentFlood = InstrumentFlood.new(_pattern_holder, tiles_paper, tiles_paper, selection_map)
	var combined_brush_instrument: InstrumentCombined = InstrumentCombined.new(InstrumentStamp.new(_pattern_holder, tiles_paper, selection_map))
	combined_brush_instrument.set_instrument(KEY_SHIFT, instrument_line)
	combined_brush_instrument.set_instrument(KEY_CONTROL | KEY_SHIFT, instrument_rectangle)
	combined_brush_instrument.set_instrument(KEY_ALT | KEY_SHIFT, instrument_bucket_fill)
	
	__brush_instrument_tool_button = toolbar.create_instrument_button("Brush\nShift+LMB: Line\nShift+Ctrl+LMB: Rectangle", KEY_B, "brush", combined_brush_instrument)

	var tb = TB.tree(self)
	tb.node(toolbar).with_children([
		tb.node(toolbar.create_instrument_button("Rectangle Selection", KEY_M, "rectangle_selection", InstrumentRectangle.new(selection_pattern_holder, selection_paper, null, false))),
		tb.node(toolbar.create_instrument_button("Same Tile Selection", KEY_W, "magic_wand", InstrumentFlood.new(selection_pattern_holder, selection_paper, tiles_paper, null))),
		tb.node(VSeparator.new()),
		tb.node(__brush_instrument_tool_button),
		tb.node(toolbar.create_instrument_button("Line", KEY_L, "line", instrument_line)),
		tb.node(toolbar.create_instrument_button("Rectangle", KEY_R, "rectangle", instrument_rectangle)),
		tb.node(toolbar.create_instrument_button("Fill", KEY_F, "bucket", instrument_bucket_fill)),
		tb.node(toolbar.create_instrument_button("Picker", KEY_I, "picker", InstrumentPicker.new(_pattern_holder, tiles_paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Eraser", KEY_E, "eraser", eraser)),
		tb.node(VSeparator.new()),
		tb.node(ToolButton.new(), "__place_random_tile_button").with_props({
			focus_mode = Control.FOCUS_NONE,
			hint_tooltip = "Place Random Tile",
			icon = Common.get_icon("random"),
			toggle_mode = true,
		}).connected("toggled", "__on_place_random_tile_button_toggled"),
		tb.node(HBoxContainer.new(), "__scattering_controls") \
			.with_props({ visible = false }) \
			.with_children([
				tb.node(Label.new()).with_props({ text = "Scattering:"} ),
				tb.node(SpinBox.new(), "__scattering_spin_box").with_props({
					step = 0.001,
				})
		])
	]).build()

func _ready() -> void:
	__brush_instrument_tool_button.pressed = true
	__brush_instrument_tool_button.emit_signal("toggled", true)

func __on_selection_pattern_copied(pattern: Patterns.Pattern) -> void:
	__on_subpalette_selected(pattern)

func __on_place_random_tile_button_toggled(button_pressed: bool) -> void:
	__scattering_controls.visible = button_pressed
