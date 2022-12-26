extends "_subpalette.gd"

const TB = preload("../tree_builder.gd")

class Subtile:
	extends ReferenceRect
	func _init(subtile_coord: Vector2, tile_id: int, tile_set: TileSet) -> void:
		var tile_region = tile_set.tile_get_region(tile_id)
		rect_position = tile_region.position
		rect_size = tile_region.size
	pass

const SUBTILE_COLORS = PoolColorArray([
	Color.yellow, # SINGLE_TILE = 0
	Color.cyan, # AUTO_TILE = 1
	Color.white # ATLAS_TILE = 2
])

class Tile:
	extends ReferenceRect
	func _init(tile_id: int, tile_set: TileSet) -> void:
		var tile_region = tile_set.tile_get_region(tile_id)
		var tile_mode = tile_set.tile_get_tile_mode(tile_id)
		var subtile_size = tile_region.size \
			if tile_mode == TileSet.SINGLE_TILE else \
			tile_set.autotile_get_size(tile_id)
		var subtile_spacing = tile_set.autotile_get_spacing(tile_id)
		var subtile_color = SUBTILE_COLORS[tile_mode]

		rect_position = tile_region.position
		rect_min_size = tile_region.size
		rect_size = tile_region.size

		var tb = TB.tree(self)

		var subtiles: Array
		var column_count = rect_min_size.x / (subtile_size.x + subtile_spacing)
		var row_count = rect_min_size.y / (subtile_size.y + subtile_spacing)
		for y in row_count: for x in column_count:
			var subtile = tb.node(Subtile.new(Vector2(x, y), tile_id, tile_set)) \
				.with_props({
					border_color = subtile_color,
					rect_min_size = subtile_size,
					rect_size = subtile_size})
			#TODO сделать выбор паттерна subtile.connect("gui_input", self, "__on_subtile_gui_input", [subtile])
			subtiles.append(subtile)

		tb.node(self).with_children([
			tb.node(GridContainer.new()) \
				.with_props({ columns = column_count }) \
				.with_overrides({ hseparation = subtile_spacing, vseparation = subtile_spacing }) \
				.with_children(subtiles) \
		]).build()

class TileTextureRect:
	extends TextureRect

	var __ref_rect: ReferenceRect

	func _init(texture: Texture, tile_set: TileSet) -> void:
		var tb = TB.tree(self)

		var children: Array
		for tile_id in tile_set.get_tiles_ids():
			if tile_set.tile_get_texture(tile_id) == texture:
				children.append(tb.node(Tile.new(tile_id, tile_set)))

		tb.node(self).with_props({ texture = texture }).with_children(children).build()

var __texture_viewport: Viewport

func _init().() -> void:
	var tb = TreeBuilder.tree(self)

	tb.node(self).with_children([
		tb.node(HSplitContainer.new()) \
			.with_props({anchor_right = 1, anchor_bottom = 1,}) \
			.with_children([
				tb.node(VBoxContainer.new()).with_children([
					tb.node(__item_list_slider),
					tb.node(__item_list) \
						.with_props({
							anchor_right = 1, anchor_bottom = 1,
							size_flags_vertical = SIZE_EXPAND_FILL,
							max_columns = 0,
							same_column_width = true,
							icon_mode = ItemList.ICON_MODE_TOP,
							icon_scale = 0.5,
							fixed_icon_size = Vector2.ONE * 256,
							rect_min_size = Vector2.RIGHT * 128 }),
					]),
				tb.node(VBoxContainer.new()).with_children([
					tb.node(HBoxContainer.new()).with_children([
						tb.node(HBoxContainer.new()).with_children([
								tb.node(ToolButton.new())]),
						tb.node(HBoxContainer.new()) \
							.with_props({ size_flags_horizontal = SIZE_EXPAND_FILL }) \
							.with_children([
								tb.node(CheckBox.new()),
								tb.node(ToolButton.new()),
								tb.node(HSlider.new()).with_props({ size_flags_horizontal = SIZE_EXPAND_FILL })])
					]),
					tb.node(Panel.new()) \
						.with_props({ size_flags_vertical = SIZE_EXPAND_FILL }) \
						.with_children([
							tb.node(ViewportContainer.new()) \
								.with_props({
									anchor_right = 1, anchor_bottom = 1,
									stretch = true}) \
								.with_children([
									tb.node(Viewport.new(), "__texture_viewport") \
										.with_props({
											usage = Viewport.USAGE_2D,
											disable_3d = true,
											transparent_bg = true })
								])
						])
				])
			])
		]).build()

func _on_fill(tile_set: TileSet) -> void:
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
					TileTextureRect.new(tile_texture, tile_set))

func _on_clear() -> void:
	__clear_texture_viewport()

func _on_unselect() -> void:
	__clear_texture_viewport()

func _on_item_list_item_selected(index: int, metadata: TileTextureRect) -> void:
	__clear_texture_viewport()
	var tex_rect = __item_list.get_item_metadata(index)
	__texture_viewport.add_child(tex_rect)


func __clear_texture_viewport() -> void:
	for child in __texture_viewport.get_children():
		__texture_viewport.remove_child(child)
