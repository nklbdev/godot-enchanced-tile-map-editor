extends "_list_subpalette.gd"

const Paper = preload("../paper.gd")

func _init(autotiles_paper: Paper).("Classic", "classic_autotiling") -> void: pass

func _after_set_up() -> void:
	var tile_set = _tile_map.tile_set
	for tile_id in tile_set.get_tiles_ids():
		var tile_texture = _tile_map.tile_set.tile_get_texture(tile_id)
		var tile_region = tile_set.tile_get_region(tile_id)
		var tile_mode = tile_set.tile_get_tile_mode(tile_id)
		var subtile_size = tile_region.size \
			if tile_mode == TileSet.SINGLE_TILE else \
			tile_set.autotile_get_size(tile_id)
		var subtile_spacing = tile_set.autotile_get_spacing(tile_id)
		var icon_coordinate = Vector2.ZERO \
			if tile_mode == TileSet.SINGLE_TILE else \
			tile_set.autotile_get_icon_coordinate(tile_id)
		var tile_icon = AtlasTexture.new()
		tile_icon.atlas = tile_texture
		tile_icon.region = \
			Rect2(tile_region.position + (subtile_size + Vector2.ONE * subtile_spacing) * icon_coordinate, subtile_size)
		tile_icon.flags = tile_texture.flags
		_add_item("%s: %s" % [tile_id, tile_set.tile_get_name(tile_id)], tile_icon, tile_id)

func _before_tear_down() -> void:
	pass

