extends "_list_and_content_subpalette.gd"

const Base = preload("_list_and_content_subpalette.gd")

class TileOnTexture:
	extends Base.Tile
	const Common = preload("../common.gd")
	var __tile_region: Rect2
	var __tile_rect: Rect2
	var __tile_mode: int
	var __subtile_size: Vector2
	var __subtile_spacing: Vector2
	var __tile_color: Color
	var __tile_highlight_color: Color
	const __tile_shadow_color: Color = Color(0, 0, 0, 0.125)
	var __hover: bool
	func _init(tile_id: int, tile_set: TileSet) -> void:
		self.tile_id = tile_id
		__tile_region = tile_set.tile_get_region(tile_id)
		__tile_rect = Rect2(Vector2.ZERO, __tile_region.size)
		__tile_mode = tile_set.tile_get_tile_mode(tile_id)
		__subtile_size = __tile_region.size \
			if __tile_mode == TileSet.SINGLE_TILE else \
			tile_set.autotile_get_size(tile_id)
		__subtile_spacing = Vector2.ONE * tile_set.autotile_get_spacing(tile_id)
		__tile_color = Common.TILE_COLORS[__tile_mode]
		__tile_highlight_color = __tile_color * Color(1, 1, 1, 0.0625)

		rect_position = __tile_region.position
		rect_min_size = __tile_region.size
		rect_size = __tile_region.size
		mouse_filter = MOUSE_FILTER_PASS
		connect("mouse_entered", self, "__on_hover_changed", [true])
		connect("mouse_exited", self, "__on_hover_changed", [false])
	
	var __selected: Rect2 # in subtile coords
	var __selection: Rect2 # in subtile coords
	var __dragging: bool
	var __selection_rect: Rect2 # in absolute coords
	signal region_selected(selected)
	
	func unselect() -> void:
		__selected = Rect2()
		__selection_rect = Rect2()
		__update_selection()
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.pressed and not event.control:
					assert(not __dragging)
					__dragging = true
					__selection_rect.position = event.position
					__selection_rect.size = Vector2.ZERO
					__update_selection()
				else:
					if __dragging:
						__dragging = false
						var selected: bool
						if not __selection.has_no_area():
							__selected = __selection
							selected = true
						__selection_rect.position = Vector2.ZERO
						__selection_rect.size = Vector2.ZERO
						__update_selection()
						if selected:
							emit_signal("region_selected", __selected)
			elif event.button_index == BUTTON_RIGHT and event.pressed:
				__dragging = false
				__selection_rect.position = Vector2.ZERO
				__selection_rect.size = Vector2.ZERO
				__update_selection()
		if event is InputEventMouseMotion:
			if __dragging:
				__selection_rect.end = Vector2(clamp(event.position.x, 0, __tile_region.size.x), clamp(event.position.y, 0, __tile_region.size.y))
				__update_selection()
	func __update_selection() -> void:
		var abs_selection_rect = __selection_rect.abs()
		__selection.position = ((abs_selection_rect.position + __subtile_spacing) / (__subtile_size + __subtile_spacing)).floor()
		__selection.end = ((abs_selection_rect.end) / (__subtile_size + __subtile_spacing)).ceil()
		if __selection.size.x < 0: __selection.size.x = 0
		if __selection.size.y < 0: __selection.size.y = 0
		update()

	func __on_hover_changed(hover: bool) -> void:
		__hover = hover
		update()

	func __get_subtiles_region_rect(subtiles_rect: Rect2) -> Rect2:
		return Rect2(
				subtiles_rect.position * (__subtile_size  + __subtile_spacing),
				subtiles_rect.size * (__subtile_size  + __subtile_spacing) - __subtile_spacing)
	func _draw() -> void:
		var selected_rect = __get_subtiles_region_rect(__selected).clip(__tile_rect).abs()
		var selection_rect = __get_subtiles_region_rect(__selection).clip(__tile_rect).abs()
#		var visible_area: Rect2 = get_viewport_transform().affine_inverse().xform(get_viewport_rect())
		
		draw_rect(Rect2(Vector2.ZERO, __tile_region.size), __tile_highlight_color if __hover else __tile_shadow_color, true)
		for y in range(0, __tile_region.size.y, __subtile_size.y + __subtile_spacing.y):
			for x in range(0, __tile_region.size.x, __subtile_size.x + __subtile_spacing.x):
				var subtile_rect = Rect2(Vector2(x, y), __subtile_size).clip(__tile_rect)
				draw_rect(subtile_rect, Common.SUBTILE_COLOR, false)
		draw_rect(Rect2(Vector2.ZERO, __tile_region.size), __tile_color, false)
		if not __selected.has_no_area():
			draw_rect(selected_rect, Common.SELECTED_RECT_COLOR, false)
			draw_rect(selected_rect, Common.SHADOW_COLOR, true)
		if __dragging and not __selection.has_no_area():
			draw_rect(selection_rect, Common.SELECTION_RECT_COLOR, false)
			draw_rect(selection_rect, Common.SHADOW_COLOR, true)

class TilesTextureRect:
	extends TextureRect

	var __ref_rect: ReferenceRect

	func _init(texture: Texture, tile_set: TileSet, selection_subscriber: Object) -> void:
		self.texture = texture
		rect_position = - texture.get_size() / 2
		mouse_filter = MOUSE_FILTER_PASS
		for tile_id in tile_set.get_tiles_ids():
			if tile_set.tile_get_texture(tile_id) == texture:
				var tile = TileOnTexture.new(tile_id, tile_set)
				tile.connect("region_selected", selection_subscriber, "_on_tile_region_selected", [tile, false])
				add_child(tile)

func _init().("By Texture", "texture") -> void: pass

func _after_set_up() -> void:
	var tile_set = _tile_map.tile_set
	var textures: Array
	for tile_id in tile_set.get_tiles_ids():
		var tile_texture: Texture = tile_set.tile_get_texture(tile_id)
		if tile_texture:
			var texture_index = textures.find(tile_texture)
			if texture_index < 0:
				textures.append(tile_texture)
				_add_item(
					tile_texture.resource_path.get_file() if tile_texture.resource_path else "",
					tile_texture,
					TilesTextureRect.new(tile_texture, tile_set, self))
