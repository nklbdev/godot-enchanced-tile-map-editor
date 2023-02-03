extends "_base.gd"

const Common = preload("../common.gd")
const Paper = preload("../paper.gd")
const Patterns = preload("../patterns.gd")

var _settings: Common.Settings

var _pattern_holder: Common.ValueHolder
var _pattern: Patterns.Pattern
var _paper: Paper
var _selection_map: TileMap
var _paint_immediately_on_pushed: bool
var __paint_deferred: bool
var _paint_invalid_cell: bool
var _ruler_grid_map: Paper.RulerGridMap

# updating on pattern or paper changed data
var _lines_count_in_pattern: int

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

func _init(pattern_holder: Common.ValueHolder, paper: Paper, selection_map: TileMap = null, paint_immediately_on_pushed: bool = true, paint_invalid_cell: bool = false) -> void:
	_settings = Common.get_static(Common.Statics.SETTINGS)
	_paper = paper
	_paper.connect("after_set_up", self, "__on_paper_after_set_up")
	_paper.connect("before_tear_down", self, "__on_paper_before_tear_down")
	_paper.connect("tile_map_settings_changed", self, "__update_cached_data")
	_paper.connect("tile_set_settings_changed", self, "__update_cached_data")
	_ruler_grid_map = _paper.get_ruler_grid_map()
	_pattern_holder = pattern_holder
	_pattern_holder.connect("value_changed", self, "__update_cached_data")
	_pattern = _pattern_holder.value
	_selection_map = selection_map
	_paint_immediately_on_pushed = paint_immediately_on_pushed
	_paint_invalid_cell = paint_invalid_cell
	
	_settings.connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed()

func __on_paper_after_set_up() -> void:
	__update_cached_data()
func __on_paper_before_tear_down() -> void:
	pass
func __on_paper_tile_map_settings_changed() -> void:
	__update_cached_data()
func __on_paper_tile_set_settings_changed() -> void:
	pass

func __update_cached_data() -> void:
	_pattern = _pattern_holder.value
	_lines_count_in_pattern = (_ruler_grid_map.cell_half_offset_type.conv(_pattern.size).y) if _pattern else 0
	__cell_poly = \
		SQUARE if _ruler_grid_map.cell_half_offset == TileMap.HALF_OFFSET_DISABLED else \
		(HEXAGON_VERTICAL if (_ruler_grid_map.cell_half_offset % 3) & 1 else HEXAGON_HORIZONTAL)

func _set_origin(value: Vector2) -> void:
	._set_origin(value)
	
	var pattern_grid_origin_map_cell = \
		_ruler_grid_map.world_to_map(_origin) \
		if not _pattern or _pattern.size == Vector2.ONE else \
		_pattern.get_origin_map_cell(_origin, _ruler_grid_map) \

	if pattern_grid_origin_map_cell != _pattern_grid_origin_map_cell:
		_pattern_grid_origin_map_cell = pattern_grid_origin_map_cell
		
		
		_pattern_grid_origin_map_cell_position = _ruler_grid_map.map_to_world(_pattern_grid_origin_map_cell)
		_pattern_grid_origin_position = _pattern_grid_origin_map_cell_position + \
			_ruler_grid_map.cell_half_offset_type.line_direction * _ruler_grid_map.cell_half_offset_type.offset_sign * \
			(0.5 if _lines_count_in_pattern & 1 else 0.25)

func _set_position(value: Vector2) -> void:
	._set_position(value)
	_position = value
	_pattern_grid_position_map_cell = _ruler_grid_map.world_to_map(_position)
	_pattern_grid_position_map_cell_position = _ruler_grid_map.map_to_world(_pattern_grid_position_map_cell)

func push() -> void:
	_before_pushed()
	.push()
	_ruler_grid_map.clear()
	_paper.reset_changes()
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
	_ruler_grid_map.clear()
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
		_pattern_grid_position_cell = ((_position - _pattern_grid_origin_position) / (_pattern.size if _pattern else Vector2.ONE)).floor()
	_on_moved(previous_position, previous_pattern_grid_position_cell)

func process_input_event_key(event: InputEventKey) -> bool:
	return true if _is_pushed else _paper.process_input_event_key(event)

func paint() -> void:
	if _pattern:
		_on_paint()

func draw(overlay: Control) -> void:
	if _pattern:
		_on_draw(overlay)
	if not _pattern or _pattern.size == Vector2.ONE:
		overlay.draw_colored_polygon(
			Transform2D(0, _pattern_grid_origin_map_cell_position).xform(__cell_poly),
			Color.red * Color(1, 1, 1, 0.25))
#		overlay.draw_rect(
#			Rect2(_pattern_grid_origin_map_cell_position, Vector2.ONE),
#			Color.red * Color(1, 1, 1, 0.25))
		if _pattern_grid_position_map_cell != _pattern_grid_origin_map_cell:
			overlay.draw_colored_polygon(
				Transform2D(0, _pattern_grid_position_map_cell_position).xform(__cell_poly),
				Color.red * Color(1, 1, 1, 0.25))
#			overlay.draw_rect(
#				Rect2(_pattern_grid_position_map_cell_position, Vector2.ONE),
#				Color.red * Color(1, 1, 1, 0.25))
	else:
		draw_pattern_hint_at(overlay, Vector2.ZERO)
		if _pattern_grid_position_cell != Vector2.ZERO:
			draw_pattern_hint_at(overlay, _pattern_grid_position_cell)

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
	return _selection_map == null or _selection_map.get_used_rect().has_no_area() or _selection_map.get_cellv(map_cell) == 0

func paint_pattern_at(pattern_grid_cell: Vector2) -> void:
	var pattern_position: Vector2 = __get_pattern_position(pattern_grid_cell)
	var pattern_used_rect: Rect2 = _pattern.__map.get_used_rect()
	if pattern_used_rect.has_no_area():
		return
	if pattern_used_rect.size == Vector2.ONE:
		var data: PoolIntArray = Common.get_map_cell_data(_pattern.__map, pattern_used_rect.position)
		if _paint_invalid_cell or data[0] >= 0 and can_paint_at(pattern_position):
			_paper.set_map_cell_data(pattern_position, data)
		return
	if _ruler_grid_map.cell_half_offset == TileMap.HALF_OFFSET_DISABLED:
		for y in pattern_used_rect.size.y: for x in pattern_used_rect.size.x:
			var pattern_cell: Vector2 = pattern_used_rect.position + Vector2(x, y)
			var data: PoolIntArray = Common.get_map_cell_data(_pattern.__map, pattern_cell)
			if data[0] >= 0 or _paint_invalid_cell:
				var map_cell: Vector2 = pattern_position + Vector2(x, y)
				if can_paint_at(map_cell):
					if data[0] == -2:
						data[0] = -1
					_paper.set_map_cell_data(map_cell, data)
	else:
		var pattern_position_c: Vector3 = Common.map_to_cube(pattern_position, _ruler_grid_map.cell_half_offset)
		var pattern_used_rect_position_c: Vector3 = Common.map_to_cube(pattern_used_rect.position, _pattern.__map.cell_half_offset)
		for y in pattern_used_rect.size.y: for x in pattern_used_rect.size.x:
			var pattern_cell: Vector2 = pattern_used_rect.position + Vector2(x, y)
			var data: PoolIntArray = Common.get_map_cell_data(_pattern.__map, pattern_cell)
			if _paint_invalid_cell or data[0] >= 0:
				var pattern_cell_c: Vector3 = Common.map_to_cube(pattern_cell, _pattern.__map.cell_half_offset)
				var pattern_used_cell_c: Vector3 = pattern_cell_c - pattern_used_rect_position_c
				var map_cell_c: Vector3 = pattern_position_c + pattern_used_cell_c
				var map_cell: Vector2 = Common.cube_to_map(map_cell_c, _ruler_grid_map.cell_half_offset)
				if can_paint_at(map_cell):
					if data[0] == -2:
						data[0] = -1
					_paper.set_map_cell_data(map_cell, data)

func get_pattern_cell_for_map_cell(map_cell: Vector2) -> Vector2:
	return (map_cell - _pattern_grid_origin_map_cell).posmodv(_pattern.size) \
		if _ruler_grid_map.cell_half_offset == TileMap.HALF_OFFSET_DISABLED else \
		_ruler_grid_map.world_to_map(
			_ruler_grid_map.map_to_world(map_cell) -
			_pattern_grid_origin_map_cell_position -
			(_ruler_grid_map.map_to_world(_pattern.size) if (_lines_count_in_pattern & 1) else Vector2.ZERO)) \
			.posmodv(_pattern.size)

func paint_pattern_cell_at(map_cell: Vector2) -> void:
	if _lines_count_in_pattern > 0:
		var data = _pattern.get_cell_data(get_pattern_cell_for_map_cell(map_cell))
		if _paint_invalid_cell or data[0] >= 0:
			_paper.set_map_cell_data(map_cell, data)

const SQUARE: PoolVector2Array = PoolVector2Array([
	Vector2(0, 0), Vector2(1, 0),
	Vector2(1, 1), Vector2(0, 1),
])

const HEXAGON_HORIZONTAL: PoolVector2Array = PoolVector2Array([
	Vector2(0,   1.0/6.0), Vector2(0,    5.0/6.0),
	Vector2(0.5, 7.0/6.0), Vector2(1,    5.0/6.0),
	Vector2(1,   1.0/6.0), Vector2(0.5, -1.0/6.0),
])

const HEXAGON_VERTICAL: PoolVector2Array = PoolVector2Array([
	Vector2(1.0/6.0, 0  ), Vector2( 5.0/6.0, 0  ),
	Vector2(7.0/6.0, 0.5), Vector2( 5.0/6.0, 1  ),
	Vector2(1.0/6.0, 1  ), Vector2(-1.0/6.0, 0.5),
])

var __cell_poly: PoolVector2Array
const __cursor_color: Color = Color.red * Color(1, 1, 1, 0.25)
func draw_pattern_hint_at(overlay: Control, pattern_grid_cell: Vector2) -> void:
	var pattern_positon: Vector2 = __get_pattern_position(pattern_grid_cell)
	var translation: Transform2D
	for y in _pattern.size.y: for x in _pattern.size.x:
		translation.origin = pattern_positon + _ruler_grid_map.map_to_world(Vector2(x, y))
		overlay.draw_colored_polygon(translation.xform(__cell_poly), __cursor_color)

func __get_pattern_position(pattern_grid_cell: Vector2) -> Vector2:
	return _pattern_grid_origin_map_cell_position + _ruler_grid_map.map_to_world(pattern_grid_cell * _pattern.size)
