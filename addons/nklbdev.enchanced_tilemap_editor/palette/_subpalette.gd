extends Control

const TreeBuilder = preload("../tree_builder.gd")

var __tile_map: TileMap
var __item_list_slider: HSlider = HSlider.new()
var __item_list: ItemList = ItemList.new()

signal selected(data)

func _init() -> void:
	__item_list.connect("item_selected", self, "__on_item_list_item_selected")
	__item_list_slider.connect("value_changed", self, "__on_item_list_value_changed")
	__item_list_slider.min_value = 0.1
	__item_list_slider.max_value = 1
	__item_list_slider.step = 0.1
	__item_list_slider.value = 0.5
	__item_list.connect("gui_input", self, "__on_item_list_gui_input")

func set_up(tile_map: TileMap) -> void:
	__tile_map = tile_map
	_after_set_up()

func tear_down() -> void:
	_before_tear_down()
	__item_list.clear()
	__tile_map = null


func unselect() -> void:
	__item_list.unselect_all()
	_on_unselect()

# Protected methods

func _add_item(text: String, icon: Texture, metadata) -> void:
	__item_list.add_item(text, icon)
	__item_list.set_item_metadata(__item_list.get_item_count() - 1, metadata)

# Methods to override

func _on_unselect() -> void:
	pass

func _after_set_up() -> void:
	pass

func _before_tear_down() -> void:
	pass

func _on_item_list_item_selected(index: int, metadata) -> void:
	pass

# Private methods

func __on_item_list_item_selected(index: int) -> void:
	_on_item_list_item_selected(index, __item_list.get_item_metadata(index))

func __on_item_list_value_changed(value):
	__item_list.icon_scale = value
	var item_list_rect_size = __item_list.rect_size
	__item_list.rect_size = Vector2.ZERO
	__item_list.rect_size = item_list_rect_size

func __on_item_list_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed and event.control:
			match event.button_index:
				BUTTON_WHEEL_UP: __item_list_slider.value += __item_list_slider.step
				BUTTON_WHEEL_DOWN: __item_list_slider.value -= __item_list_slider.step
