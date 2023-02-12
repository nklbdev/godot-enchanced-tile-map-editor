extends "_base.gd"

const TB = preload("../tree_builder.gd")

const AutotilesClassicSubpalette = preload("subpalette_autotiles_classic.gd")
const AutotilesTerrainsSubpalette = preload("subpalette_autotiles_terrains.gd")

const Paper = preload("../paper.gd")
const Selection = preload("../selection.gd")
const PatternLayoutMap = preload("../pattern_layout_map.gd")
# Instruments
const InstrumentCombined  = preload("../instruments/combined.gd")
const InstrumentStamp     = preload("../instruments/stamp.gd")
const InstrumentLine      = preload("../instruments/line.gd")
const InstrumentRectangle = preload("../instruments/rectangle.gd")
const InstrumentPicker    = preload("../instruments/picker.gd")

var __brush_instrument_tool_button: ToolButton

func _init(selection_paper: Selection, autotiles_paper: Paper, terrains_paper: Paper).("Autotiles", "autotiles", [AutotilesClassicSubpalette.new(autotiles_paper), AutotilesTerrainsSubpalette.new(terrains_paper)]) -> void:
	var tb = TB.tree(self)
	var paper = Paper.new()
	var paint_pattern_layout_map: PatternLayoutMap = PatternLayoutMap.new(autotiles_paper)
	var selection_map: TileMap = selection_paper.get_selection_map()
	
	var instrument_line: InstrumentLine = InstrumentLine.new(paper, paint_pattern_layout_map, selection_map)
	var instrument_rectangle: InstrumentRectangle = InstrumentRectangle.new(paper, paint_pattern_layout_map, selection_map)
	var combined_brush_instrument: InstrumentCombined = InstrumentCombined.new(InstrumentStamp.new(paper, paint_pattern_layout_map, selection_map))
	combined_brush_instrument.set_instrument(KEY_SHIFT, instrument_line)
	combined_brush_instrument.set_instrument(KEY_CONTROL | KEY_SHIFT, instrument_rectangle)
	
	__brush_instrument_tool_button = toolbar.create_instrument_button("Brush\nShift+LMB: Line\nShift+Ctrl+LMB: Rectangle", KEY_B, "brush", combined_brush_instrument)
	
	tb.node(toolbar).with_children([
		tb.node(__brush_instrument_tool_button),
		tb.node(toolbar.create_instrument_button("Line", KEY_L, "line", instrument_line)),
		tb.node(toolbar.create_instrument_button("Rectangle", KEY_R, "rectangle", instrument_rectangle)),
		tb.node(toolbar.create_instrument_button("Picker", KEY_I, "picker", InstrumentPicker.new(paper, paint_pattern_layout_map, selection_map))),
	]).build()

func _ready() -> void:
	__brush_instrument_tool_button.pressed = true
	__brush_instrument_tool_button.emit_signal("toggled", true)

