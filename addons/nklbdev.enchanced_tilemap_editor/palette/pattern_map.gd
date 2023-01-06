extends "_subpalette.gd"
#	var visible_area: Rect2 = __texture_rect.get_viewport_transform().affine_inverse().xform(__texture_rect.get_viewport_rect())

const Common = preload("../common.gd")
const TB = preload("../tree_builder.gd")

const TILE_COLORS = PoolColorArray([
	Color(1, 1, 0.3), # SINGLE_TILE = 0
	Color(0.3, 0.6, 1), # AUTO_TILE = 1
	Color(0.8, 0.8, 0.8), # ATLAS_TILE = 2
])
const SUBTILE_COLOR = Color(0.3, 0.7, 0.6)
const SHADOW_COLOR = SUBTILE_COLOR * Color(1, 1, 1, 0.4)
const SELECTED_RECT_COLOR = Color.white
const SELECTION_RECT_COLOR = Color.lightskyblue



class Tile:
	extends Control
	
	signal region_selected(region)

	var __tile_region: Rect2
	var __subtile_size: Vector2
	var __subtiles_grid_rect: Rect2
	var __subtile_spacing: float
	var tile_id: int
	var __tile_mode: int
	var __subtiles_map: TileMap
	var __half_offset_type: int
	var __subtiles_grid_points: PoolVector2Array
	var __tile_color = TILE_COLORS[__tile_mode]
	var __selection: Rect2
	var __selected: Rect2
	var __dragging: bool
	var __cell_base_transform: Transform2D
	func unselect() -> void:
		__selected = Rect2()
		update()
	func _init(tile_id: int, tile_map: TileMap, selection_subscriber: Object) -> void:
		self.tile_id = tile_id
		connect("region_selected", selection_subscriber, "__on_tile_region_selected", [self])
		mouse_filter = MOUSE_FILTER_IGNORE
		
		__subtiles_map = TileMap.new()
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
		__subtiles_map.show_behind_parent = true
		add_child(__subtiles_map)

		__cell_base_transform = Common.get_cell_base_transform(__subtiles_map)
		__half_offset_type = tile_map.cell_half_offset
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

	func __draw_rect(rect: Rect2, fill_color: Color, border_color: Color, grid_color: Color = Color.transparent) -> void:
		rect = rect.abs()
		for y in rect.size.y: for x in rect.size.x:
			var cell = rect.position + Vector2(x, y)
			var cell_position = cell + Common.get_half_offset(cell, __half_offset_type)
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
		__draw_rect(__subtiles_grid_rect, Color.transparent, __tile_color, SUBTILE_COLOR)
		__draw_rect(__selected, SHADOW_COLOR, SELECTED_RECT_COLOR)
		if __dragging:
			__draw_rect(__selection.abs().grow_individual(0, 0, 1, 1), SHADOW_COLOR, SELECTION_RECT_COLOR)
		
	func _my_gui_input(event: InputEvent) -> void:
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


class ClippingContentPanel:
	extends Panel

	func _init() -> void:
		rect_clip_content = true

	func _clips_input() -> bool:
		return true

var __content: Tile
var __content_panel: Panel
var __content_holder: Control
var __content_scale_slider: HSlider

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
								tb.node(HSlider.new(), "__content_scale_slider") \
									.with_props({
										size_flags_horizontal = SIZE_EXPAND_FILL,
										min_value = 0.01,
										step = 1.5,
										value = 0.5,
										ratio = 1,
										exp_edit = true,
										allow_greater = true,
										allow_lesser = true,
									}) \
									.connected("value_changed", "__on_content_scale_slider_value_changed")
							])
					]),
					tb.node(ClippingContentPanel.new(), "__content_panel") \
						.connected("gui_input", "__on_content_panel_gui_input") \
						.connected("resized", "__on_content_panel_resized") \
						.with_props({
							size_flags_vertical = SIZE_EXPAND_FILL,
							rect_clip_content = true }) \
						.with_children([
							tb.node(Control.new(), "__content_holder") \
								.with_props({ mouse_filter = MOUSE_FILTER_PASS }),
							tb.node(GridContainer.new()) \
								.with_props({
									columns = 2,
									anchor_right = 1, anchor_bottom = 1,
									size_flags_horizontal = SIZE_EXPAND_FILL,
									size_flags_vertical = SIZE_EXPAND_FILL,
									mouse_filter = MOUSE_FILTER_IGNORE,
								}).with_children([
									tb.node(Control.new()).with_props({ mouse_filter = MOUSE_FILTER_IGNORE }),
									tb.node(VScrollBar.new()).with_props({size_flags_vertical = SIZE_EXPAND_FILL}),
									tb.node(HScrollBar.new()).with_props({size_flags_horizontal = SIZE_EXPAND_FILL}),
									tb.node(Control.new()).with_props({ mouse_filter = MOUSE_FILTER_IGNORE }),
								])
						])
				])
			])
		]).build()

func _after_set_up() -> void:
	var tile_set = __tile_map.tile_set
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
				Tile.new(tile_id, __tile_map, self))

func _before_tear_down() -> void:
	unselect()
	__clear_content_viewport()

func _on_unselect() -> void:
	if __previous_selected_tile:
		__previous_selected_tile.unselect()
		__previous_selected_tile = null
	__selected_pattern = null

func _on_item_list_item_selected(index: int, metadata: Tile) -> void:
	__clear_content_viewport()
	__content = __item_list.get_item_metadata(index)
	__content_holder.add_child(__content)

func __clear_content_viewport() -> void:
	if __content:
		__content_holder.remove_child(__content)
		__content = null

func __scale_content(factor: float, origin: Vector2) -> void:
	__change_content_scale(__content_holder.rect_scale.x * factor, origin)

func __change_content_scale(scale: float, origin = __content_panel.get_rect().get_center()) -> void:
	if is_equal_approx(scale, __content_holder.rect_scale.x):
		return
	var previous_content_global_position = __content.rect_global_position
	__content_holder.rect_position = origin
	__content.rect_global_position = previous_content_global_position
	__content_holder.rect_scale = Vector2.ONE * scale

var __warping: bool
var __content_dragging: bool
func __on_content_panel_gui_input(event: InputEvent) -> void:
	if __content == null:
		return
	if event is InputEventMouse:
		if event is InputEventMouseButton:
			if event.pressed:
				match event.button_index:
					BUTTON_MIDDLE: __content_dragging = true
			else:
				match event.button_index:
					BUTTON_MIDDLE: __content_dragging = false
					BUTTON_WHEEL_UP: __scale_content(1.5, event.position)
					BUTTON_WHEEL_DOWN: __scale_content(1 / 1.5, event.position)
		elif event is InputEventMouseMotion:
			if __content_dragging:
				if __warping:
					__warping = false
				else:
					__content_holder.rect_position += event.relative
				var warped_mouse_position: Vector2 = event.position.posmodv(__content_panel.rect_size)
				if event.position != warped_mouse_position:
					__warping = true
					__content_panel.warp_mouse(warped_mouse_position)
	__content._my_gui_input(event)


onready var __previous_content_panel_center: Vector2 = __content_panel.rect_size / 2
func __on_content_panel_resized() -> void:
	__content_holder.rect_position += __content_panel.rect_size / 2 - __previous_content_panel_center
	__previous_content_panel_center = __content_panel.rect_size / 2

func __on_content_scale_slider_value_changed(value: float) -> void:
	__change_content_scale(value)

var __previous_selected_tile: Tile
var __selected_pattern: Common.Pattern
func __on_tile_region_selected(region: Rect2, tile: Tile) -> void:
	if __previous_selected_tile and __previous_selected_tile != tile:
		__previous_selected_tile.unselect()
	__previous_selected_tile = tile
	# TODO сделать чо надо
	var data: PoolIntArray
	data.resize(region.size.x * region.size.y * 4)
	var i: int = 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			data[i    ] = tile.tile_id
			data[i + 1] = 0 # transformation
			data[i + 2] = x
			data[i + 3] = y
			i += 4
	__selected_pattern = Common.Pattern.new(region.size, data)
	emit_signal("selected", __selected_pattern)


