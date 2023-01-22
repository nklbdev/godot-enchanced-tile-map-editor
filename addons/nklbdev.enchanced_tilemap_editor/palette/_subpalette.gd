extends Control

const Common = preload("../common.gd")
const TreeBuilder = preload("../tree_builder.gd")
const Instrument = preload("../instruments/_base.gd")

var icon: Texture
var title: String

var _tile_map: TileMap
var _item_list: ItemList = ItemList.new()

signal selected(data)

func _init(title: String, icon_name: String) -> void:
	self.title = title
	icon = Common.get_icon(icon_name)
	anchor_right = 1
	anchor_bottom = 1
	_item_list.connect("item_selected", self, "__on_item_list_item_selected")

func set_up(tile_map: TileMap) -> void:
	_tile_map = tile_map
	_after_set_up()

func tear_down() -> void:
	_before_tear_down()
	_item_list.clear()
	_tile_map = null


func unselect() -> void:
	_item_list.unselect_all()
	_on_unselect()

# Protected methods

func _add_item(text: String, icon: Texture, metadata) -> void:
	_item_list.add_item(text, icon)
	_item_list.set_item_metadata(_item_list.get_item_count() - 1, metadata)

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
	_on_item_list_item_selected(index, _item_list.get_item_metadata(index))
