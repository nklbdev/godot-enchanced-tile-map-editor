extends TileMap

const Common = preload("common.gd")

var cell_half_offset_type: Common.CellHalfOffsetType
var size: Vector2
var linear_size: Vector2
var center_offset: Vector2
var linear_growth: float
var has_offsetted_cell_lines: bool
var has_offsetted_pattern_lines: bool

func _init() -> void:
	connect("settings_changed", self, "__on_settings_changed")

func __on_settings_changed() -> void:
	cell_half_offset_type = Common.CELL_HALF_OFFSET_TYPES[cell_half_offset]
	var used_rect: Rect2 = get_used_rect()
	assert(used_rect.position == Vector2.ZERO)
	size = used_rect.size
	linear_size = cell_half_offset_type.conv(size)
	has_offsetted_cell_lines = linear_size.y > 1
	has_offsetted_pattern_lines = int(linear_size.y) & 1
	linear_growth = (int(has_offsetted_cell_lines) + int(has_offsetted_pattern_lines)) * 0.5 * cell_half_offset_type.offset_sign
	center_offset = (Vector2.ONE - linear_size + Vector2.RIGHT * linear_growth) / 2

func get_origin_map_cell(world_position: Vector2) -> Vector2:
	return world_to_map(world_position - cell_half_offset_type.conv(center_offset))

func get_origin_position(map_cell: Vector2) -> Vector2:
	return map_to_world(map_cell) + cell_half_offset_type.line_direction * linear_growth

func get_pattern_cell_for_map_cell(grid_origin_map_cell: Vector2, map_cell: Vector2) -> Vector2:
	if cell_half_offset_type.index == TileMap.HALF_OFFSET_DISABLED:
		return (map_cell - grid_origin_map_cell).posmodv(size)
	
	var w = cell_half_offset_type.conv(map_to_world(map_cell) - map_to_world(grid_origin_map_cell))
	if has_offsetted_pattern_lines and posmod(w.y, linear_size.y * 2) >= linear_size.y:
		w.x -= cell_half_offset_type.offset_sign * 0.5
	w.y = posmod(w.y, linear_size.y)
	if int(w.y) & 1:
		w.x -= cell_half_offset_type.offset_sign * 0.5
	w.x = posmod(w.x, linear_size.x)
	return world_to_map(cell_half_offset_type.conv(w))
