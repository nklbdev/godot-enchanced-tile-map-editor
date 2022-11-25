extends "res://addons/nklbdev.enchanced_tilemap_editor/utility_base.gd"

var _tile_map: TileMap

func _init(tile_map: TileMap) -> void:
	_tile_map = tile_map

func rect_world_to_map(rect: Rect2) -> Rect2:
	var result = Rect2()
	result.position = _tile_map.world_to_map(rect.position)
	result.end = _tile_map.world_to_map(rect.end)
	return result

func rect_map_to_world(rect: Rect2) -> Rect2:
	var result = Rect2()
	result.position = _tile_map.map_to_world(rect.position)
	result.end = _tile_map.map_to_world(rect.end)
	return result
