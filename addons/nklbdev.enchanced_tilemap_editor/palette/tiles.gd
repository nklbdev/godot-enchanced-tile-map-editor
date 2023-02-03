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
var __rotation_menu_button: MenuButton
var __flipping_menu_button: MenuButton

var __ruler_grid_map: TileMap

func _init(selection_paper: Selection, tiles_paper: Paper, eraser: Instrument).("Tiles", "tiles", [
	TilesByTextureSubpalette.new(),
	TilesIndividualSubpalette.new(),
	TilesPatternsSubpalette.new()]) -> void:

	tiles_paper.connect("after_set_up", self, "__on_tiles_paper_after_set_up")
	tiles_paper.connect("before_tear_down", self, "__on_tiles_paper_before_tear_down")
	tiles_paper.connect("tile_map_settings_changed", self, "__on_tiles_paper_tile_map_settings_changed")
	__ruler_grid_map = tiles_paper.get_ruler_grid_map()

	var selection_map: TileMap = selection_paper.get_selection_map()
	selection_paper.connect("pattern_copied", self, "__on_selection_pattern_copied")
	var selection_pattern_holder: Common.ValueHolder = Common.ValueHolder.new(Patterns.Pattern.new(Vector2.ONE, [0, 0, 0, 0]))

	var instrument_line: InstrumentLine = InstrumentLine.new(_pattern_holder, tiles_paper, selection_map)
	var instrument_rectangle: InstrumentRectangle = InstrumentRectangle.new(_pattern_holder, tiles_paper, selection_map)
	var instrument_bucket_fill: InstrumentFlood = InstrumentFlood.new(_pattern_holder, tiles_paper, tiles_paper, selection_map)
	var combined_brush_instrument: InstrumentCombined = InstrumentCombined.new(InstrumentStamp.new(_pattern_holder, tiles_paper, selection_map))
	combined_brush_instrument.set_instrument(KEY_SHIFT, instrument_line)
	combined_brush_instrument.set_instrument(KEY_CONTROL | KEY_SHIFT, instrument_rectangle)
	combined_brush_instrument.set_instrument(KEY_ALT | KEY_SHIFT, instrument_bucket_fill)
	
	__brush_instrument_tool_button = toolbar.create_instrument_button("Brush\nShift+LMB: Line\nShift+Ctrl+LMB: Rectangle", KEY_B, "brush", combined_brush_instrument)
	_pattern_holder.connect("value_changed", self, "__on_pattern_holder_value_changed")

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
		]),
		tb.node(HBoxContainer.new()) \
			.with_children([
				tb.node(MenuButton.new(), "__rotation_menu_button") \
					.with_props({ text = "Rotate...", icon = Common.get_icon("random") }),
				tb.node(MenuButton.new(), "__flipping_menu_button") \
					.with_props({ text = "Flip...", icon = Common.get_icon("random") }),
		])
	]).build()
	PopupMenuBuilder.new(__rotation_menu_button.get_popup()) \
		.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
		.item("rotate_60", "Rotate 60° without cells", 0, KEY_MASK_CTRL | KEY_R,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, rotation = Patterns.Rotation.ROTATE_60 }) \
		.submenu("rotate_90", "Rotate 90°...", 1, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, KEY_MASK_ALT | KEY_MASK_CTRL | KEY_R,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, rotation = Patterns.Rotation.ROTATE_90, cell_transform = Patterns.CellTransform.ROTATE_90 }) \
			.item("random", "without cells", 1, KEY_MASK_CTRL | KEY_R,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, rotation = Patterns.Rotation.ROTATE_90 }) \
			.item("random", "cells only", 2, KEY_MASK_ALT | KEY_R,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.ROTATE_90 }) \
			.get_popup_menu()) \
		.item("rotate_120", "Rotate 120° without cells", 2, 0,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, rotation = Patterns.Rotation.ROTATE_120 }) \
		.submenu("rotate_180", "Rotate 180°...", 3, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, 0,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, rotation = Patterns.Rotation.ROTATE_180, cell_transform = Patterns.CellTransform.ROTATE_180 }) \
			.item("random", "without cells", 1, 0,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, rotation = Patterns.Rotation.ROTATE_180 }) \
			.item("random", "cells only", 2, 0,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.ROTATE_180 }) \
			.get_popup_menu()) \
		.item("rotate_240", "Rotate 240° without cells", 4, 0,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, rotation = Patterns.Rotation.ROTATE_240 }) \
		.submenu("rotate_270", "Rotate 270°...", 1, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, KEY_MASK_ALT | KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_R,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, rotation = Patterns.Rotation.ROTATE_270, cell_transform = Patterns.CellTransform.ROTATE_270 }) \
			.item("random", "without cells", 1, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_R,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, rotation = Patterns.Rotation.ROTATE_270 }) \
			.item("random", "cells only", 2, KEY_MASK_ALT | KEY_MASK_SHIFT | KEY_R,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.ROTATE_270 }) \
			.get_popup_menu()) \
		.item("rotate_300", "Rotate 300° without cells", 6, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_R,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, rotation = Patterns.Rotation.ROTATE_300 })
	PopupMenuBuilder.new(__flipping_menu_button.get_popup()) \
		.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
		.submenu("flip_0", "Flip 0°...", 0, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, KEY_MASK_ALT | KEY_MASK_CTRL | KEY_F, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, flipping = Patterns.Flipping.FLIP_0, cell_transform = Patterns.CellTransform.FLIP_0 }) \
			.item("random", "without cells", 1, KEY_MASK_CTRL | KEY_F, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, flipping = Patterns.Flipping.FLIP_0 }) \
			.item("random", "cells only", 2, KEY_MASK_ALT | KEY_F,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.FLIP_0 }) \
			.get_popup_menu()) \
		.item("flip_30", "Flip 30° without cells", 1, 0,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, flipping = Patterns.Flipping.FLIP_30 }) \
		.submenu("flip_45", "Flip 45°...", 0, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, KEY_MASK_ALT | KEY_MASK_CTRL | KEY_T, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, flipping = Patterns.Flipping.FLIP_45, cell_transform = Patterns.CellTransform.FLIP_45 }) \
			.item("random", "without cells", 1, KEY_MASK_CTRL | KEY_T, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, flipping = Patterns.Flipping.FLIP_45 }) \
			.item("random", "cells only", 2, KEY_MASK_ALT | KEY_T,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.FLIP_45 }) \
			.get_popup_menu()) \
		.item("flip_60", "Flip 60° without cells", 2, 0,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, flipping = Patterns.Flipping.FLIP_60 }) \
		.submenu("flip_90", "Flip 90°...", 3, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, KEY_MASK_ALT | KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_F, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, flipping = Patterns.Flipping.FLIP_90, cell_transform = Patterns.CellTransform.FLIP_90 }) \
			.item("random", "without cells", 1, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_F, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, flipping = Patterns.Flipping.FLIP_90 }) \
			.item("random", "cells only", 2, KEY_MASK_ALT | KEY_MASK_SHIFT | KEY_F, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.FLIP_90 }) \
			.get_popup_menu()) \
		.item("flip_120", "Flip 120° without cells", 4, 0,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, flipping = Patterns.Flipping.FLIP_120 }) \
		.submenu("flip_135", "Flip 135°...", 0, null, PopupMenuBuilder.new() \
			.connected("index_pressed", self, "__on_transform_popup_menu_item_pressed", true) \
			.item("random", "with cells", 0, KEY_MASK_ALT | KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_T, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, flipping = Patterns.Flipping.FLIP_135, cell_transform = Patterns.CellTransform.FLIP_135 }) \
			.item("random", "without cells", 1, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_T, \
				{ compatibility = Common.HalfOffsetCompatibilityFlags.NOT_OFFSETTED, flipping = Patterns.Flipping.FLIP_135 }) \
			.item("random", "cells only", 2, KEY_MASK_ALT | KEY_MASK_SHIFT | KEY_T,
				{ compatibility = Common.HalfOffsetCompatibilityFlags.ALL, cell_transform = Patterns.CellTransform.FLIP_135 }) \
			.get_popup_menu()) \
		.item("flip_150", "Flip 150° without cells", 5, 0,
			{ compatibility = Common.HalfOffsetCompatibilityFlags.OFFSETTED, flipping = Patterns.Flipping.FLIP_150 })

func __update_transform_menu(menu: PopupMenu) -> void:
	var half_offset_type: Common.CellHalfOffsetType = Common.CELL_HALF_OFFSET_TYPES[__ruler_grid_map.cell_half_offset]
	for item_index in menu.get_item_count():
		var meta = menu.get_item_metadata(item_index)
		menu.set_item_icon(item_index, meta.icons[half_offset_type.offset_orientation])
		menu.set_item_disabled(item_index, not(half_offset_type.offset_orientation_flag & meta.get("compatibility", Common.HalfOffsetCompatibilityFlags.ALL)))
	for child in menu.get_children():
		if child is PopupMenu:
			__update_transform_menu(child)

func __update_transform_menus() -> void:
	__update_transform_menu(__rotation_menu_button.get_popup())
	__update_transform_menu(__flipping_menu_button.get_popup())

func __on_pattern_holder_value_changed() -> void:
	__update_transform_menus()

func __on_tiles_paper_after_set_up() -> void:
	__rotation_menu_button.disabled = false
	__flipping_menu_button.disabled = false
	__update_transform_menus()


func __on_tiles_paper_before_tear_down() -> void:
	__rotation_menu_button.disabled = true
	__flipping_menu_button.disabled = true

func __on_tiles_paper_tile_map_settings_changed() -> void:
	__update_transform_menus()

func __on_transform_popup_menu_item_pressed(item_index: int, popup_menu: PopupMenu) -> void:
	var pattern = _pattern_holder.value as Patterns.Pattern
	if pattern:
		var meta = popup_menu.get_item_metadata(item_index)
		if meta:
			if "flipping" in meta:
				pattern.flip(meta.flipping, __ruler_grid_map.cell_half_offset)
			if "rotation" in meta:
				pattern.rotate_ccw(meta.rotation, __ruler_grid_map.cell_half_offset)
			if "cell_transform" in meta:
				pattern.transform_cells(meta.cell_transform)

func __transform_pattern(rotation: int = -1, flipping: int = -1, cell_transform: int = 0) -> void:
	
	pass

class PopupMenuBuilder:
	const Common = preload("../common.gd")
	var __popup_menu: PopupMenu
	func _init(popup_menu = null) -> void:
		__popup_menu = popup_menu if popup_menu else PopupMenu.new()
	func item(icon_base_name: String, label: String, id: int, accel: int = 0, metadata = null) -> PopupMenuBuilder:
		if not metadata:
			metadata = {}
		var default_icon: Texture = __get_icon(icon_base_name, "_def")
		metadata["icons"] = [
			__get_icon(icon_base_name, "_rect"),
			__get_icon(icon_base_name, "_hex_h"),
			__get_icon(icon_base_name, "_hex_v"),
			default_icon,
		]
		__popup_menu.add_icon_item(default_icon, label, id, accel)
		__popup_menu.set_item_metadata(__popup_menu.get_item_count() - 1, metadata)
		return self
	func submenu(icon_base_name: String, label: String, id: int, metadata, popup_submenu: PopupMenu) -> PopupMenuBuilder:
		if not metadata:
			metadata = {}
		var default_icon: Texture = __get_icon(icon_base_name, "_def")
		metadata["icons"] = [
			__get_icon(icon_base_name, "_rect"),
			__get_icon(icon_base_name, "_hex_h"),
			__get_icon(icon_base_name, "_hex_v"),
			default_icon,
		]
		__popup_menu.add_child(popup_submenu)
		__popup_menu.add_submenu_item(label, popup_submenu.name, id)
		__popup_menu.set_item_icon(__popup_menu.get_item_count() - 1, default_icon)
		__popup_menu.set_item_metadata(__popup_menu.get_item_count() - 1, metadata)
		return self
	func connected(signal_name: String, method_owner: Object, method_name: String, pass_popup_menu_as_first_bind: bool = false, binds: Array = []) -> PopupMenuBuilder:
		__popup_menu.connect(signal_name, method_owner, method_name, ([__popup_menu] if pass_popup_menu_as_first_bind else []) + binds)
		return self
	func get_popup_menu() -> PopupMenu:
		return __popup_menu
	const __possible_icon_suffixes: PoolStringArray = PoolStringArray(["", "_def", ""])
	static func __get_icon(icon_base_name: String, desired_suffix: String) -> Texture:
		__possible_icon_suffixes[0] = desired_suffix
		for icon_suffix in __possible_icon_suffixes:
			var icon_name = icon_base_name + icon_suffix
			if Common.has_icon(icon_name):
				return Common.get_icon(icon_name)
		return null

func _ready() -> void:
	__brush_instrument_tool_button.pressed = true
	__brush_instrument_tool_button.emit_signal("toggled", true)

func __on_selection_pattern_copied(pattern: Patterns.Pattern) -> void:
	__on_subpalette_selected(pattern)

func __on_place_random_tile_button_toggled(button_pressed: bool) -> void:
	__scattering_controls.visible = button_pressed
