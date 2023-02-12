extends VBoxContainer

const Common = preload("common.gd")
const Instrument = preload("instruments/_base.gd")
const InstrumentStamp = preload("instruments/stamp.gd")
const ToolBar = preload("palette/tool_bar.gd")
const Palette = preload("palette/_base.gd")
const Paper = preload("paper.gd")
const Selection = preload("selection.gd")
const Patterns = preload("patterns.gd")
const TilesPalette = preload("palette/tiles.gd")
const AutotilesPalette = preload("palette/autotiles.gd")
const PatternLayoutMap = preload("pattern_layout_map.gd")


var __palettes_option_button: OptionButton
var __palette_panel: PanelContainer
var __header: HBoxContainer
var __current_palette: Palette
var __current_toolbar: ToolBar
var __instrument: Instrument
var __alternate_instrument: Instrument

signal instrument_changed
func get_instrument() -> Instrument:
	return __instrument
func get_alternate_instrument():
	return __alternate_instrument

func __set_instrument(instrument: Instrument) -> void:
	if instrument == __instrument:
		return
	__instrument = instrument
	emit_signal("instrument_changed")

func _init(selection_paper: Selection, tiles_paper: Paper, autotiles_paper: Paper, terrains_paper: Paper) -> void:
	rect_min_size.y = 200
	__palettes_option_button = OptionButton.new()
	var eraser_pattern_layout_map: PatternLayoutMap = PatternLayoutMap.new(tiles_paper)
	eraser_pattern_layout_map.pattern = Patterns.Pattern.new(Vector2.ONE, [-2, 0, 0, 0])

	var eraser = InstrumentStamp.new(tiles_paper, eraser_pattern_layout_map, selection_paper.get_selection_map(), true, true)
	__alternate_instrument = eraser
	__add_palette(TilesPalette.new(selection_paper, tiles_paper, eraser))
	__add_palette(AutotilesPalette.new(selection_paper, autotiles_paper, terrains_paper))
	__palettes_option_button.connect("item_selected", self, "__on_palettes_option_button_item_selected")

	__header = HBoxContainer.new()
	__header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	__header.add_child(__palettes_option_button)
	add_child(__header)

	__palette_panel = PanelContainer.new()
	__palette_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	__palette_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(__palette_panel)
	
	if __palettes_option_button.get_item_count() > 0:
		__on_palettes_option_button_item_selected(0)

func set_up(tile_map: TileMap) -> void:
	for palette_index in __palettes_option_button.get_item_count():
		__palettes_option_button.get_item_metadata(palette_index).set_up(tile_map)

func tear_down() -> void:
	for palette_index in __palettes_option_button.get_item_count():
		__palettes_option_button.get_item_metadata(palette_index).tear_down()

func process_input_event_key(event: InputEventKey) -> bool:
	return __current_palette.process_input_event_key(event)

func __add_palette(palette: Control) -> void:
	__palettes_option_button.add_icon_item(palette.icon, palette.title)
	__palettes_option_button.set_item_metadata(__palettes_option_button.get_item_count() - 1, palette)

func __on_palettes_option_button_item_selected(index: int) -> void:
	var previous_instrument: Instrument = __instrument
	var palette: Palette = __palettes_option_button.get_item_metadata(index) as Palette
	if palette != __current_palette:
		if __current_palette:
			__palette_panel.remove_child(__current_palette)
		if __current_toolbar:
			__current_toolbar.disconnect("instrument_changed", self, "__on_toolbar_instrument_changed")
			__header.remove_child(__current_toolbar)
	__current_palette = palette
	__current_toolbar = palette.toolbar if palette else null
	if __current_palette:
		__palette_panel.add_child(__current_palette)
	if __current_toolbar:
		__header.add_child(__current_toolbar)
		__set_instrument(__current_toolbar.get_instrument())
		__current_toolbar.connect("instrument_changed", self, "__on_toolbar_instrument_changed")

func __on_toolbar_instrument_changed() -> void:
	__set_instrument(__current_toolbar.get_instrument())
