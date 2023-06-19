extends "_base.gd"

const Common = preload("../common.gd")
const Paper = preload("../paper.gd")
const Patterns = preload("../patterns.gd")
const PatternLayoutMap = preload("../pattern_layout_map.gd")

var _settings: Common.Settings

var _paper: Paper
var _pattern_layout_map: PatternLayoutMap
var _selection_map: TileMap
var _paint_immediately_on_pushed: bool
var __paint_deferred: bool
var _paint_invalid_cell: bool

# updating on pattern or paper changed data
var _lines_count_in_pattern: int
var _random_number_generator: RandomNumberGenerator
var _stroke_seed: int
var random_tile_mode: bool setget __set_random_tile_mode

# updating on instrument moved data
var _pattern_grid_origin_map_cell: Vector2
var _pattern_grid_origin_map_cell_position: Vector2
var _pattern_grid_origin_position: Vector2
var _pattern_grid_position_cell: Vector2
var _pattern_grid_position_map_cell: Vector2
var _pattern_grid_position_map_cell_position: Vector2

var _drawing_area_limit: int

func _on_settings_changed() -> void:
	_drawing_area_limit = _settings.drawing_area_limit

func __set_random_tile_mode(value: bool) -> void:
	random_tile_mode = value
	__update_cached_data()
	

func _init(paper: Paper, pattern_layout_map: PatternLayoutMap, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) -> void:
	_settings = Common.get_static(Common.Statics.SETTINGS)
	_random_number_generator = RandomNumberGenerator.new()
	_random_number_generator.randomize()
	_stroke_seed = _random_number_generator.randi()
	_paper = paper
	_paper.connect("after_set_up", self, "__on_paper_after_set_up")
	_paper.connect("before_tear_down", self, "__on_paper_before_tear_down")
	_paper.connect("tile_map_settings_changed", self, "__update_cached_data")
	_paper.connect("tile_set_settings_changed", self, "__update_cached_data")
	_pattern_layout_map = pattern_layout_map
	_pattern_layout_map.connect("layout_changed", self, "__update_cached_data")
	_selection_map = selection_map
	_paint_immediately_on_pushed = paint_immediately_on_pushed
	_paint_invalid_cell = paint_invalid_cell
	
	_settings.connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed()
	__update_cached_data()

func __on_paper_after_set_up() -> void:
	__update_cached_data()
func __on_paper_before_tear_down() -> void:
	pass
func __on_paper_tile_map_settings_changed() -> void:
	__update_cached_data()
func __on_paper_tile_set_settings_changed() -> void:
	pass

func __update_cached_data() -> void:
	# if __pattern != __pattern_holder.value:
	# 	if __pattern:
	# 		__pattern.disconnect("changed", self, "__on_pattern_changed")
	# 		_pattern_used_cells.resize(0)
	# 	__pattern = __pattern_holder.value
	# 	if __pattern:
	# 		__pattern.connect("changed", self, "__on_pattern_changed")
	# 		for cell in __pattern.cells.keys():
	# 			if __pattern.cells[cell][0] >= 0:
	# 				_pattern_used_cells.append(cell)
	# _pattern_size = (Vector2.ONE if random_tile_mode else __pattern.size) if __pattern else Vector2.ZERO
	# _pattern_cells_count = (1 if random_tile_mode else __pattern.cells.size()) if __pattern else 0
	# _lines_count_in_pattern = (1 if random_tile_mode else _pattern_layout_map.cell_half_offset_type.conv(_pattern_size).y) if __pattern else 0
	pass

func _set_origin(value: Vector2) -> void:
	._set_origin(value)
	
	var pattern_grid_origin_map_cell = _pattern_layout_map.get_origin_map_cell(_origin)

	if pattern_grid_origin_map_cell != _pattern_grid_origin_map_cell:
		_pattern_grid_origin_map_cell = pattern_grid_origin_map_cell
		_pattern_grid_origin_map_cell_position = _pattern_layout_map.map_to_world(_pattern_grid_origin_map_cell)
		_pattern_grid_origin_position = _pattern_grid_origin_map_cell_position + _pattern_layout_map.origin_position_offset

func _set_position(value: Vector2) -> void:
	._set_position(value)
	# TODO: very strange implementation!!! check it!
	_position = value
	_pattern_grid_position_map_cell = _pattern_layout_map.world_to_map(_position)
	_pattern_grid_position_map_cell_position = _pattern_layout_map.map_to_world(_pattern_grid_position_map_cell)

func push() -> void:
	_before_pushed()
	.push()
	_paper.reset_changes()
	_stroke_seed = _random_number_generator.randi()
	_paper.freeze_input()
	_set_origin(_position)
	_is_pushed = true
	_after_pushed()
	if _paint_immediately_on_pushed:
		paint()
	else:
		__paint_deferred = true

func pull(force: bool = false) -> void:
	_before_pulled(force)
	.pull(force)
	if force:
		_paper.reset_changes()
	else:
		_paper.commit_changes()
	_paper.resume_input()
	_set_origin(_position)
	_pattern_grid_position_cell = Vector2.ZERO
	_is_pushed = false
	__paint_deferred = false
	_after_pulled(force)

func move_to(position: Vector2) -> void:
	if position == _position:
		return
	if __paint_deferred:
		paint()
	var previous_position = _position
	var previous_pattern_grid_position_cell: Vector2 = _pattern_grid_position_cell
	.move_to(position)
	if _is_pushed:
		_pattern_grid_position_cell = ((_position - _pattern_grid_origin_position) / _pattern_layout_map.pattern_size).floor()
	_on_moved(previous_position, previous_pattern_grid_position_cell)

func process_input_event_key(event: InputEventKey) -> bool:
	return true if _is_pushed else _paper.process_input_event_key(event)

func paint() -> void:
	if _pattern_layout_map.used_cells_count > 0:
		_on_paint()

const __CELL_LINES: PoolVector2Array = PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
func draw(overlay: Control) -> void:
	_on_draw(overlay)
	draw_pattern_hint_at(overlay, Vector2.ZERO)
	if _pattern_grid_position_cell != Vector2.ZERO:
		draw_pattern_hint_at(overlay, _pattern_grid_position_cell)

	# Draw paper grid
	var current_cell: Vector2 = _pattern_layout_map.world_to_map(_position)
	var grid_color: Color = _settings.grid_color
	var grid_color_a: float = grid_color.a
	var cell: Vector2
	var radius: int = _settings.grid_fragment_radius
	var radius_squared: int = radius * radius
	for y in range(current_cell.y - radius, current_cell.y + radius + 1):
		for x in range(current_cell.x - radius, current_cell.x + radius + 1):
			cell = Vector2(x, y)
			__CELL_LINES.fill(_pattern_layout_map.map_to_world(cell))
			__CELL_LINES[1].x += 1
			__CELL_LINES[3].y += 1
			grid_color.a = grid_color_a * (1 - cell.distance_squared_to(current_cell) / radius_squared)
			if grid_color.a > 0:
				overlay.draw_multiline(__CELL_LINES, grid_color)

	# Draw pattern grid
	var pattern_size: Vector2 = _pattern_layout_map.pattern_size
	if pattern_size != Vector2.ONE:
		current_cell = _pattern_grid_position_cell
		grid_color = _settings.pattern_grid_color
		grid_color_a = grid_color.a
		radius = _settings.pattern_grid_fragment_radius
		radius_squared = radius * radius
		for y in range(current_cell.y - radius, current_cell.y + radius + 1):
			for x in range(current_cell.x - radius, current_cell.x + radius + 1):
				cell = Vector2(x, y)
				__CELL_LINES.fill(_pattern_grid_origin_position + cell * pattern_size)
				__CELL_LINES[1].x += pattern_size.x
				__CELL_LINES[3].y += pattern_size.y
				grid_color.a = max(0, grid_color_a * (1 - cell.distance_squared_to(current_cell) / radius_squared))
				if grid_color.a > 0:
					overlay.draw_multiline(__CELL_LINES, grid_color)

# for override
func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	pass
func _before_pulled(force: bool) -> void:
	pass
func _after_pulled(force: bool) -> void:
	pass
func _on_moved(from_position: Vector2, previous_pattern_grid_position_cell: Vector2) -> void:
	pass

func _on_paint() -> void:
	pass
func _on_draw(overlay: Control) -> void:
	pass

func can_paint_at(map_cell: Vector2) -> bool:
	return _selection_map == null or \
		_selection_map.get_used_rect().has_no_area() or \
		_selection_map.get_cellv(map_cell) == 0

func paint_pattern_at(pattern_grid_cell: Vector2) -> void:
	if _pattern_layout_map.pattern_size == Vector2.ONE:
		var map_cell: Vector2 = _pattern_grid_origin_map_cell + pattern_grid_cell
		if can_paint_at(map_cell):
			paint_pattern_cell_at(map_cell)
	else:
		var pattern_offset_in_grid_cell: Vector2 = _pattern_layout_map.map_to_world(pattern_grid_cell) - pattern_grid_cell
		var pattern_position: Vector2 = \
			_pattern_grid_origin_map_cell_position + \
			pattern_grid_cell * _pattern_layout_map.pattern_size + \
			pattern_offset_in_grid_cell
		for pattern_cell in _pattern_layout_map.cells_data.keys():
			var pattern_cell_position: Vector2 = pattern_position + _pattern_layout_map.map_to_world(pattern_cell)
			var map_cell = _pattern_layout_map.world_to_map(pattern_cell_position)
			if can_paint_at(map_cell):
				paint_pattern_cell_at(map_cell)

func paint_pattern_cell_at(map_cell: Vector2) -> void:
	var map_cell_position: Vector2 = _pattern_layout_map.map_to_world(map_cell)
	var map_cell_position_on_layout: Vector2 = map_cell_position - _pattern_grid_origin_map_cell_position
	var layout_cell: Vector2 = _pattern_layout_map.world_to_map(map_cell_position_on_layout).posmodv(_pattern_layout_map.layout_size)
	var data: PoolIntArray = Common.get_map_cell_data(_pattern_layout_map, layout_cell)
	if _paint_invalid_cell or data[0] >= 0:
		if data[0] == -2:
			data[0] = -1
		_paper.set_map_cell_data(map_cell, data)

func draw_pattern_hint_at(overlay: Control, pattern_grid_cell: Vector2) -> void:
	var pattern_size: Vector2 = _pattern_layout_map.pattern_size
	var pattern_position: Vector2 = _pattern_grid_origin_map_cell_position + \
		_pattern_layout_map.map_to_world(pattern_grid_cell * pattern_size)
	var cell: Vector2
	var color = _settings.cursor_color
	for y in pattern_size.y: for x in pattern_size.x:
		cell = Vector2(x, y)
		overlay.draw_rect(Rect2(pattern_position + _pattern_layout_map.map_to_world(cell), Vector2.ONE), color * (Color.white if _pattern_layout_map.cells_data.has(cell) else Color(1, 1, 1, 0.5)))
