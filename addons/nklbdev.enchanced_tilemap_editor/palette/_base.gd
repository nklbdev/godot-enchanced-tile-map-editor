extends Control

const Common = preload("../common.gd")
const WeakRefStorage = preload("../weakref_storage.gd")
const Subpalette = preload("_subpalette.gd")
const ToolBar = preload("tool_bar.gd")
const Instrument = preload("../instruments/_base.gd")

var title: String
var icon: Texture
var toolbar: ToolBar

var __subpalettes_option_button: OptionButton
var __current_subpalette: Subpalette
var _alternate_instrument: Instrument

func _init(title: String, icon_name: String, subpalettes: Array) -> void:
	self.title = title
	icon = Common.get_icon(icon_name)
	toolbar = ToolBar.new()
	__subpalettes_option_button = OptionButton.new()
	for subpalette in subpalettes:
		__add_subpalette(subpalette)
	__subpalettes_option_button.connect("item_selected", self, "__on_subpalettes_option_button_item_selected")
	toolbar.add_child(__subpalettes_option_button)
	if __subpalettes_option_button.get_item_count() > 0:
		__on_subpalettes_option_button_item_selected(0)


var __tile_map: TileMap
var __last_states: WeakRefStorage = WeakRefStorage.new()
func set_up(tile_map: TileMap) -> void:
	__tile_map = tile_map
	if __tile_map.tile_set:
		var last_selected_subpalette_id = __last_states.pop(__tile_map.tile_set)
		if last_selected_subpalette_id != null:
			last_selected_subpalette_id = last_selected_subpalette_id as int
			var idx = __subpalettes_option_button.get_item_index(last_selected_subpalette_id)
			if __subpalettes_option_button.selected != idx:
				__subpalettes_option_button.select(idx)
				__subpalettes_option_button.emit_signal("item_selected", idx)
	for subpalette_index in __subpalettes_option_button.get_item_count():
		__subpalettes_option_button.get_item_metadata(subpalette_index).set_up(tile_map)

func tear_down() -> void:
	var last_selected_subpalette_id = __subpalettes_option_button.get_selected_id()
	if __tile_map.tile_set:
		__last_states.push(__tile_map.tile_set, last_selected_subpalette_id)
		__tile_map = null
	
	for subpalette_index in __subpalettes_option_button.get_item_count():
		__subpalettes_option_button.get_item_metadata(subpalette_index).tear_down()

func process_input_event_key(event: InputEventKey) -> bool:
	return toolbar.process_input_event_key(event)

func __add_subpalette(subpalette: Control) -> void:
	__subpalettes_option_button.add_icon_item(subpalette.icon, subpalette.title)
	__subpalettes_option_button.set_item_metadata(__subpalettes_option_button.get_item_count() - 1, subpalette)
	subpalette.connect("selected", self, "_on_subpalette_selected")

func _on_subpalette_selected(data) -> void:
	return

func __on_subpalettes_option_button_item_selected(index: int) -> void:
	var subpalette: Subpalette = __subpalettes_option_button.get_item_metadata(index) as Subpalette
	if subpalette != __current_subpalette:
		if __current_subpalette:
			remove_child(__current_subpalette)
	__current_subpalette = subpalette
	if __current_subpalette:
		add_child(__current_subpalette)
