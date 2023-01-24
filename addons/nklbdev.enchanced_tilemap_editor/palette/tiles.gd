extends "_base.gd"

const TB = preload("../tree_builder.gd")

const Paper = preload("../paper.gd")
const Selection = preload("../selection.gd")
const Patterns = preload("../patterns.gd")

const TilesByTextureSubpalette  = preload("subpalette_tiles_by_texture.gd")
const TilesIndividualSubpalette = preload("subpalette_tiles_individual.gd")
const TilesPatternsSubpalette   = preload("subpalette_tiles_patterns.gd")

# Instruments
const InstrumentStamp     = preload("../instruments/stamp.gd")
const InstrumentLine      = preload("../instruments/line.gd")
const InstrumentRectangle = preload("../instruments/rectangle.gd")
const InstrumentFlood     = preload("../instruments/flood.gd")
const InstrumentPicker    = preload("../instruments/picker.gd")


var __place_random_tile_button: ToolButton
var __scattering_controls: HBoxContainer
var __scattering_spin_box: SpinBox

func _init(selection_paper: Selection, tiles_paper: Paper, eraser: Instrument).("Tiles", "tiles", [
	TilesByTextureSubpalette.new(),
	TilesIndividualSubpalette.new(),
	TilesPatternsSubpalette.new()]) -> void:

	var selection_map = selection_paper.get_selection_map()
	selection_paper.connect("pattern_copied", self, "__on_selection_pattern_copied")
	var selection_pattern_holder = Common.ValueHolder.new(Patterns.Pattern.new(Vector2.ONE, PoolIntArray([0, 0, 0, 0])))

	var tb = TB.tree(self)
	tb.node(toolbar).with_children([
		tb.node(toolbar.create_instrument_button("Rectangle Selection", KEY_B, "rectangle_selection", InstrumentRectangle.new(selection_pattern_holder, selection_paper, null, false))),
		tb.node(toolbar.create_instrument_button("Same Tile Selection", KEY_B, "magic_wand", InstrumentFlood.new(selection_pattern_holder, selection_paper, tiles_paper, null))),
		tb.node(VSeparator.new()),
		tb.node(toolbar.create_instrument_button("Stamp", KEY_B, "brush", InstrumentStamp.new(_pattern_holder, tiles_paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Rectangle", KEY_B, "rectangle", InstrumentRectangle.new(_pattern_holder, tiles_paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Line", KEY_B, "line", InstrumentLine.new(_pattern_holder, tiles_paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Fill", KEY_B, "bucket", InstrumentFlood.new(_pattern_holder, tiles_paper, tiles_paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Picker", KEY_B, "picker", InstrumentPicker.new(_pattern_holder, tiles_paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Eraser", KEY_B, "eraser", eraser)),
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

func __on_selection_pattern_copied(pattern: Patterns.Pattern) -> void:
	__on_subpalette_selected(pattern)

func __on_place_random_tile_button_toggled(button_pressed: bool) -> void:
	__scattering_controls.visible = button_pressed
	pass
