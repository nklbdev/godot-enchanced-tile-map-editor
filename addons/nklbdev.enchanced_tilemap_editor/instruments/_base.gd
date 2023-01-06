extends Object

const Common = preload("../common.gd")
const Paper = preload("../paper.gd")
const Brush = preload("../brushes/_base.gd")


var _brush: Brush
var _paper: Paper
var _adjustments: Array = [ToolButton.new()]
var _modifiers: int
func get_adjustments() -> Array: # of Control
	return _adjustments

func get_brush_adjustments() -> Array: # of Control
	return _brush.get_adjustments()

func get_paper_adjustments() -> Array: # of Control
	return _paper.get_adjustments()

func _init(brush: Brush, paper: Paper) -> void:
	_adjustments[0].icon = preload("res://addons/nklbdev.enchanced_tilemap_editor/icons/paint_tool_contour.svg")
	_brush = brush
	_paper = paper


var _origin_cell: Vector2
var _origin: Vector2 setget _set_origin
func _set_origin(value: Vector2) -> void:
	assert(_paper)
	_origin = value
	_origin_cell = _brush.get_cell(_origin, _paper)

var _position_cell: Vector2
var _position: Vector2 setget _set_position
func _set_position(value: Vector2) -> void:
	assert(_paper)
	_position = value
	_position_cell = _brush.get_cell(_position, _paper)


var _is_pushed: bool
func is_pushed() -> bool:
	return _is_pushed

func push() -> void:
	assert(_paper)
	if _is_pushed:
		return
	_before_pushed()
	_paper.reset_changes()
	_paper.freeze_input()
	_set_origin(_position)
	_is_pushed = true
	_after_pushed()

func pull() -> void:
	assert(_paper)
	if not _is_pushed:
		return
	_before_pulled()
	if _paper.has_changes():
		_paper.commit_changes()
	_paper.resume_input()
	_set_origin(_position)
	_is_pushed = false
	_after_pulled()

func interrupt() -> void:
	assert(_paper)
	assert(_is_pushed)
	_paper.reset_changes()
	pull()

func move_to(position: Vector2) -> void:
	assert(_paper)
	var previous_position = _position
	var previous_position_cell = _position_cell
	_set_position(position)
	if not _is_pushed:
		_set_origin(_position)
	_on_moved(previous_position, previous_position_cell)

func process_input_event_key(event: InputEventKey) -> bool:
	if _is_pushed:
#		print("instrument is pushed")
		return true
	else:
		return _brush.process_input_event_key(event) or _paper.process_input_event_key(event)

# for override
func _before_pushed() -> void:
	pass
func _after_pushed() -> void:
	pass
func _before_pulled() -> void:
	pass
func _after_pulled() -> void:
	pass
func _on_moved(from_position: Vector2, from_cell: Vector2) -> void:
	pass




func draw(overlay: Control) -> void:
	assert(_paper)
	_on_draw(overlay)
func _on_draw(overlay: Control) -> void:
	pass
