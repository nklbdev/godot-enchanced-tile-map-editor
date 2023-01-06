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
	var tile_id: int
	var __tile_region: Rect2
	var __tile_rect: Rect2
	var __tile_mode: int
	var __subtile_size: Vector2
	var __subtile_spacing: Vector2
	var __tile_color: Color
	func _init(tile_id: int, tile_set: TileSet) -> void:
		self.tile_id = tile_id
		__tile_region = tile_set.tile_get_region(tile_id)
		__tile_rect = Rect2(Vector2.ZERO, __tile_region.size)
		__tile_mode = tile_set.tile_get_tile_mode(tile_id)
		__subtile_size = __tile_region.size \
			if __tile_mode == TileSet.SINGLE_TILE else \
			tile_set.autotile_get_size(tile_id)
		__subtile_spacing = Vector2.ONE * tile_set.autotile_get_spacing(tile_id)
		__tile_color = TILE_COLORS[__tile_mode]

		rect_position = __tile_region.position
		rect_min_size = __tile_region.size
		rect_size = __tile_region.size
		mouse_filter = MOUSE_FILTER_PASS
	
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
			print("asdfasfd")
			if event.button_index == BUTTON_LEFT:
				if event.pressed:
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

	func __get_subtiles_region_rect(subtiles_rect: Rect2) -> Rect2:
		return Rect2(
				subtiles_rect.position * (__subtile_size  + __subtile_spacing),
				subtiles_rect.size * (__subtile_size  + __subtile_spacing) - __subtile_spacing)
	func _draw() -> void:
		var selected_rect = __get_subtiles_region_rect(__selected).clip(__tile_rect).abs()
		var selection_rect = __get_subtiles_region_rect(__selection).clip(__tile_rect).abs()
#		var visible_area: Rect2 = get_viewport_transform().affine_inverse().xform(get_viewport_rect())
		
		# draw shadow
#		draw_rect(__tile_rect.grow_margin(MARGIN_BOTTOM, selected_rect.position.y - __tile_rect.end.y), SHADOW_COLOR)
#		draw_rect(selected_rect.grow_margin(MARGIN_RIGHT, - selected_rect.end.x), SHADOW_COLOR)
#		draw_rect(selected_rect.grow_margin(MARGIN_LEFT, selected_rect.position.x - __tile_rect.end.x), SHADOW_COLOR)
#		draw_rect(__tile_rect.grow_margin(MARGIN_TOP, - selected_rect.end.y), SHADOW_COLOR)
		
		
		for y in range(0, __tile_region.size.y, __subtile_size.y + __subtile_spacing.y):
			for x in range(0, __tile_region.size.x, __subtile_size.x + __subtile_spacing.x):
				var subtile_rect = Rect2(Vector2(x, y), __subtile_size).clip(__tile_rect)
				draw_rect(subtile_rect, SUBTILE_COLOR, false)
		if not __selected.has_no_area():
			draw_rect(selected_rect, SELECTED_RECT_COLOR, false)
			draw_rect(selected_rect, SHADOW_COLOR, true)
		if __dragging and not __selection.has_no_area():
			draw_rect(selection_rect, SELECTION_RECT_COLOR, false)
			draw_rect(selection_rect, SHADOW_COLOR, true)
		draw_rect(Rect2(Vector2.ZERO, __tile_region.size), __tile_color, false)

class TilesTextureRect:
	extends TextureRect

	var __ref_rect: ReferenceRect

	func _init(texture: Texture, tile_set: TileSet, selection_subscriber: Object) -> void:
		self.texture = texture
		mouse_filter = MOUSE_FILTER_PASS
		for tile_id in tile_set.get_tiles_ids():
			if tile_set.tile_get_texture(tile_id) == texture:
				var tile = Tile.new(tile_id, tile_set)
				tile.connect("region_selected", selection_subscriber, "__on_tile_region_selected", [tile])
				add_child(tile)

class ClippingContentPanel:
	extends Panel

	func _init() -> void:
		rect_clip_content = true

	func _clips_input() -> bool:
		return true

var __content: TilesTextureRect
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

func _before_tear_down() -> void:
	unselect()
	__clear_content_viewport()

func _on_unselect() -> void:
	if __previous_selected_tile:
		__previous_selected_tile.unselect()
		__previous_selected_tile = null
	__selected_pattern = null

func _on_item_list_item_selected(index: int, metadata: TilesTextureRect) -> void:
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


