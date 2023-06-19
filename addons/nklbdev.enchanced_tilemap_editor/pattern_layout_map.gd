extends TileMap

const Common = preload("common.gd")
const Patterns = preload("patterns.gd")
const Paper = preload("paper.gd")

signal layout_changed()

var __paper: Paper
var __previous_cell_half_offset: int

var pattern: Patterns.Pattern setget __set_pattern
var used_cells_count: int
var used_cells: Array
var cells_data: Dictionary
var pattern_size: Vector2
var layout_size: Vector2
var origin_position_offset: Vector2
var cell_offset: Vector2
var cell_offset_axis_index: int
var linear_size: Vector2

func __set_pattern(value: Patterns.Pattern) -> void:
	if value == pattern:
		return
	if pattern:
		pattern.disconnect("changed", self, "__lay_out_pattern")
	pattern = value
	if pattern:
		pattern.connect("changed", self, "__lay_out_pattern")
	__lay_out_pattern()

func _init(paper: Paper) -> void:
	cell_size = Vector2.ONE
	__paper = paper
	__paper.connect("after_set_up", self, "__after_paper_set_up")
	__paper.connect("before_tear_down", self, "__before_paper_tear_down")
	__paper.connect("tile_map_settings_changed", self, "__on_paper_tile_map_settings_changed")
	__previous_cell_half_offset = cell_half_offset
	connect("settings_changed", self, "__on_settings_changed")
	__lay_out_pattern()

func __after_paper_set_up() -> void:
	cell_half_offset = __paper.__tile_map.cell_half_offset
	__lay_out_pattern()

func __before_paper_tear_down() -> void:
	clear()
	cell_half_offset = TileMap.HALF_OFFSET_DISABLED

func __on_paper_tile_map_settings_changed() -> void:
	if __paper.__tile_map.cell_half_offset != cell_half_offset:
		cell_half_offset = __paper.__tile_map.cell_half_offset
		__lay_out_pattern()

func __on_settings_changed() -> void:
	if cell_half_offset != __previous_cell_half_offset:
		__previous_cell_half_offset = cell_half_offset
		__lay_out_pattern()

func __lay_out_pattern() -> void:
	clear()
	if not pattern:
		used_cells_count = 0
		used_cells.clear()
		pattern_size = Vector2.ONE
		layout_size = pattern_size * 2
		cells_data = {}
		return
	for cell in pattern.cells.keys():
		if pattern.cells[cell][0] != TileMap.INVALID_CELL:
			used_cells.append(cell)
	used_cells_count = used_cells.size()
	pattern_size = pattern.size if pattern.size.x > 0 and pattern.size.y > 0 else Vector2.ONE
	layout_size = pattern_size * 2
	cells_data = pattern.cells
	for i in 4:
		var pattern_grid_cell: Vector2 = Vector2(i % 2, i / 2)
		var pattern_grid_cell_origin_cell: Vector2 = pattern_grid_cell * pattern_size
		var pattern_grid_cell_origin_cell_position: Vector2 = map_to_world(pattern_grid_cell_origin_cell)
		for pattern_cell in cells_data.keys():
			var pattern_cell_relative_position: Vector2 = map_to_world(pattern_cell)
			var pattern_cell_absolute_position: Vector2 = pattern_grid_cell_origin_cell_position + pattern_cell_relative_position
			var target_map_cell = world_to_map(pattern_cell_absolute_position).posmodv(layout_size)
			Common.set_map_cell_data(self, target_map_cell, cells_data[pattern_cell])
	cell_offset_axis_index = (cell_half_offset % 3) & 1
	linear_size = Vector2(
		pattern_size[cell_offset_axis_index],
		pattern_size[cell_offset_axis_index ^ 1])
	cell_offset = map_to_world(Vector2.ONE) - Vector2.ONE
	origin_position_offset = cell_offset * (1 if int(linear_size.y) & 1 else 0.5)
	emit_signal("layout_changed")

func get_origin_map_cell(world_position: Vector2) -> Vector2:
	return world_to_map(world_position -
		(Vector2.ZERO
		if (pattern_size == Vector2.ONE) else
		(origin_position_offset + pattern_size / 2)))
