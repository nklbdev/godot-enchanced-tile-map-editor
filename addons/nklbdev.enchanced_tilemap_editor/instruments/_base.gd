extends "../_setupable.gd"

const Brush = preload("../brushes/_base.gd")

var _origin_hex_cell: Vector2 setget _set_origin_hex_cell
func _set_origin_hex_cell(value: Vector2) -> void:
	_origin_hex_cell = value
	if _paper != null:
		_origin_cell = _paper.get_cell_by_hex_cell(_origin_hex_cell)
var _origin_cell: Vector2
var _hex_cell: Vector2 setget _set_hex_cell
func _set_hex_cell(value: Vector2) -> void:
	_hex_cell = value
	if _paper != null:
		_cell = _paper.get_cell_by_hex_cell(_hex_cell)
var _cell: Vector2
var _is_pushed: bool
var _brush: Brush

func _init(brush: Brush, drawing_settings: Common.DrawingSettings).(drawing_settings) -> void:
	_brush = brush

func is_pushed() -> bool:
	return _is_pushed

func push() -> void:
	assert(is_ready())
	if _is_pushed:
		return
	_paper.reset_changes()
	_set_origin_hex_cell(_hex_cell)
	_is_pushed = true
	_after_pushed()

func pull() -> void:
	assert(is_ready())
	if not _is_pushed:
		return
	_paper.commit_changes()
	_before_pulled()
	_is_pushed = false

func interrupt() -> void:
	assert(is_ready())
	assert(is_pushed())
	_paper.reset_changes()
	pull()

func move_to(hex_cell: Vector2) -> void:
	_set_hex_cell(hex_cell)
	if not _is_pushed:
		_set_origin_hex_cell(hex_cell)
	_on_moved()


func _after_set_up() -> void:
	_brush.set_up(_paper)

func _before_tear_down() -> void:
	_brush.tear_down()

func _after_pushed() -> void:
	pass

func _before_pulled() -> void:
	pass

func _on_moved() -> void:
	pass

func _on_draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	pass
