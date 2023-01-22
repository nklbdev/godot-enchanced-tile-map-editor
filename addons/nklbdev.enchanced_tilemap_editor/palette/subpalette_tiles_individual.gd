extends "_list_and_content_subpalette.gd"
#	var visible_area: Rect2 = __texture_rect.get_viewport_transform().affine_inverse().xform(__texture_rect.get_viewport_rect())

const Base = preload("_list_and_content_subpalette.gd")

class TileOnTileMap:
	extends Base.Tile
	
	const Common = preload("../common.gd")
	
	signal region_selected(region)

	var __tile_region: Rect2
	var __subtile_size: Vector2
	var __subtiles_grid_rect: Rect2
	var __subtile_spacing: float
	var __tile_mode: int
	var __subtiles_map: TileMap
	var __subtiles_grid_points: PoolVector2Array
	var __tile_color = Common.TILE_COLORS[__tile_mode]
	var __selection: Rect2
	var __selected: Rect2
	var __dragging: bool
	var __cell_base_transform: Transform2D
	func unselect() -> void:
		__selected = Rect2()
		update()
	
	func __sync_subtiles_map(tile_map: TileMap) -> void:
		__subtiles_map.mode = tile_map.mode
		__subtiles_map.tile_set = tile_map.tile_set
		__subtiles_map.cell_size = tile_map.cell_size
		__subtiles_map.cell_quadrant_size = tile_map.cell_quadrant_size
		__subtiles_map.cell_custom_transform = tile_map.cell_custom_transform
		__subtiles_map.cell_custom_transform.origin = Vector2.ZERO
		__subtiles_map.cell_half_offset = tile_map.cell_half_offset
		__subtiles_map.cell_tile_origin = tile_map.cell_tile_origin
		__subtiles_map.cell_y_sort = tile_map.cell_y_sort
		__subtiles_map.compatibility_mode = tile_map.compatibility_mode
		__subtiles_map.centered_textures = tile_map.centered_textures
		__subtiles_map.cell_clip_uv = tile_map.cell_clip_uv
		__subtiles_map.update_dirty_quadrants()
		update()

	func _init(tile_id: int, tile_map: TileMap, selection_subscriber: Object) -> void:
		self.tile_id = tile_id
		connect("region_selected", selection_subscriber, "_on_tile_region_selected", [self])
		mouse_filter = MOUSE_FILTER_IGNORE
		
		__subtiles_map = TileMap.new()
		__subtiles_map.show_behind_parent = true
		tile_map.connect("settings_changed", self, "__sync_subtiles_map", [tile_map])
		__sync_subtiles_map(tile_map)
		add_child(__subtiles_map)

		__cell_base_transform = Common.get_cell_base_transform(__subtiles_map)
		__tile_mode = tile_map.tile_set.tile_get_tile_mode(tile_id)
		__tile_region = tile_map.tile_set.tile_get_region(tile_id)
		__subtile_size = __tile_region.size \
			if __tile_mode == TileSet.SINGLE_TILE else \
			tile_map.tile_set.autotile_get_size(tile_id)
		__subtile_spacing = tile_map.tile_set.autotile_get_spacing(tile_id)
		__subtiles_grid_rect.size = Vector2(
			int(__tile_region.size.x / (__subtile_size.x + __subtile_spacing)),
			int(__tile_region.size.y / (__subtile_size.y + __subtile_spacing)))
		for y in __subtiles_grid_rect.size.y: for x in __subtiles_grid_rect.size.x:
			__subtiles_map.set_cell(x, y, tile_id, false, false, false, Vector2(x, y))
		rect_position = - __cell_base_transform.xform(__subtiles_grid_rect.size / 2)

	func __draw_rect(rect: Rect2, fill_color: Color, border_color: Color, grid_color: Color = Color.transparent) -> void:
		rect = rect.abs()
		for y in rect.size.y: for x in rect.size.x:
			var cell = rect.position + Vector2(x, y)
			var cell_position = cell + Common.get_cell_half_offset(cell, __subtiles_map.cell_half_offset)
			if fill_color != Color.transparent:
				draw_rect(Rect2(cell_position, Vector2.ONE), fill_color, true)
			draw_line(cell_position, cell_position + Vector2.DOWN,
				border_color if x == 0 else grid_color)
			draw_line(cell_position + Vector2.RIGHT, cell_position + Vector2.ONE,
				border_color if x == rect.size.x - 1 else grid_color)
			draw_line(cell_position, cell_position + Vector2.RIGHT,
				border_color if y == 0 else grid_color)
			draw_line(cell_position + Vector2.DOWN, cell_position + Vector2.ONE,
				border_color if y == rect.size.y - 1 else grid_color)

	func _draw() -> void:
		draw_set_transform_matrix(__cell_base_transform)
		__draw_rect(__subtiles_grid_rect, Color.transparent, __tile_color, Common.SUBTILE_COLOR)
		__draw_rect(__selected, Common.SHADOW_COLOR, Common.SELECTED_RECT_COLOR)
		if __dragging:
			__draw_rect(__selection.abs().grow_individual(0, 0, 1, 1), Common.SHADOW_COLOR, Common.SELECTION_RECT_COLOR)
		
	func custom_gui_input(event: InputEvent) -> void:
		if event is InputEventMouse:
			var event_map_cell = __subtiles_map.world_to_map(__subtiles_map.get_local_mouse_position())
			if event is InputEventMouseButton:
				if event.button_index == BUTTON_LEFT:
					if event.pressed:
						if __subtiles_map.get_cellv(event_map_cell) != TileMap.INVALID_CELL:
							assert(not __dragging)
							__dragging = true
							__selection.position = event_map_cell
							__selection.size = Vector2.ZERO
							update()
					else:
						if __dragging:
							__dragging = false
							__selected = __selection.abs().grow_individual(0, 0, 1, 1)
							__selection.position = Vector2.ZERO
							__selection.size = Vector2.ZERO
							update()
							emit_signal("region_selected", __selected)
				elif event.button_index == BUTTON_RIGHT and event.pressed:
					__dragging = false
					__selection.position = Vector2.ZERO
					__selection.size = Vector2.ZERO
					update()
			if event is InputEventMouseMotion:
				if __dragging:
					__selection.end = Vector2(clamp(event_map_cell.x, 0, __subtiles_grid_rect.size.x - 1), clamp(event_map_cell.y, 0, __subtiles_grid_rect.size.y - 1))
					update()

func _init().("Individual", "tile") -> void:
	pass

func _post_process_content_panel_gui_input(event: InputEvent) -> void:
	if _content:
		_content.custom_gui_input(event)

func _after_set_up() -> void:
	var tile_set = _tile_map.tile_set
	for tile_id in tile_set.get_tiles_ids():
		var tile_texture: Texture = tile_set.tile_get_texture(tile_id)
		if tile_texture:
			var tile_mode = tile_set.tile_get_tile_mode(tile_id)
			var tile_region = tile_set.tile_get_region(tile_id)
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
			
			_add_item(
				"%s: %s" % [tile_id, tile_set.tile_get_name(tile_id)],
				tile_icon,
				TileOnTileMap.new(tile_id, _tile_map, self))

