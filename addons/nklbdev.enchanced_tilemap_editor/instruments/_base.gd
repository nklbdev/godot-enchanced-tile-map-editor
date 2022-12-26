extends Object

const Common = preload("../common.gd")
const Paper = preload("../paper.gd")
const Brush = preload("../brushes/_base.gd")


var _brush: Brush
var _paper_holder: Common.ValueHolder

func _init(brush: Brush, paper_holder: Common.ValueHolder) -> void:
	_brush = brush
	_paper_holder = paper_holder


#var _paper: Paper
#func is_ready() -> bool:
#	return _paper != null
#func set_up(paper: Paper) -> void:
#	assert(_paper == null, "can not set up twice")
#	_paper = paper
#	_after_set_up()
#func tear_down() -> void:
#	assert(_paper != null, "can not tear down twice")
#	_before_tear_down()
#	_paper = null
# for override
#func _after_set_up() -> void:
#	pass
#func _before_tear_down() -> void:
#	pass


var _origin_cell: Vector2
var _origin: Vector2 setget _set_origin
func _set_origin(value: Vector2) -> void:
	_origin = value
	_origin_cell = _brush.get_cell(_origin, _paper_holder.value.get_half_offset())

var _position_cell: Vector2
var _position: Vector2 setget _set_position
func _set_position(value: Vector2) -> void:
	_position = value
	_position_cell = _brush.get_cell(_position, _paper_holder.value.get_half_offset())







var _is_pushed: bool
func is_pushed() -> bool:
	return _is_pushed

func push() -> void:
	if _is_pushed:
		return
	_paper_holder.value.reset_changes()
	_set_origin(_position)
	_is_pushed = true
	_after_pushed()

func pull() -> void:
	if not _is_pushed:
		return
	_paper_holder.value.commit_changes()
	_before_pulled()
	_is_pushed = false

func interrupt() -> void:
	assert(is_pushed())
	_paper_holder.value.reset_changes()
	pull()

func move_to(position: Vector2) -> void:
	_set_position(position)
	if not _is_pushed:
		_set_origin(position)
	_on_moved()
# for override
func _after_pushed() -> void:
	pass
func _before_pulled() -> void:
	pass
func _on_moved() -> void:
	pass




func draw(overlay: Control) -> void:
	_on_draw(overlay)
func _on_draw(overlay: Control) -> void:
	pass
