extends "_base.gd"

const TB = preload("../tree_builder.gd")

const AutotilesClassicSubpalette = preload("subpalette_autotiles_classic.gd")
const AutotilesTerrainsSubpalette = preload("subpalette_autotiles_terrains.gd")

const Paper = preload("../paper.gd")
const Selection = preload("../selection.gd")
# Instruments
const InstrumentStamp     = preload("../instruments/stamp.gd")
const InstrumentLine      = preload("../instruments/line.gd")
const InstrumentRectangle = preload("../instruments/rectangle.gd")
const InstrumentPicker     = preload("../instruments/picker.gd")


func _init(selection_paper: Selection, autotiles_paper: Paper, terrains_paper: Paper).("Autotiles", "autotiles", [AutotilesClassicSubpalette.new(autotiles_paper), AutotilesTerrainsSubpalette.new(terrains_paper)]) -> void:
	var tb = TB.tree(self)
	var pattern_holder = Common.ValueHolder.new()
	var paper = Paper.new()
	var selection_map: TileMap = selection_paper.get_selection_map()
	tb.node(toolbar).with_children([
		tb.node(toolbar.create_instrument_button("Stamp", KEY_B, "brush", InstrumentStamp.new(pattern_holder, paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Rectangle", KEY_B, "rectangle", InstrumentRectangle.new(pattern_holder, paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Line", KEY_B, "line", InstrumentLine.new(pattern_holder, paper, selection_map))),
		tb.node(toolbar.create_instrument_button("Picker", KEY_B, "picker", InstrumentPicker.new(pattern_holder, paper, selection_map))),
	]).build()


