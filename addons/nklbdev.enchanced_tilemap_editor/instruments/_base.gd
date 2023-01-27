extends Object

func _init() -> void:
	pass

var _origin: Vector2 setget _set_origin
func _set_origin(value: Vector2) -> void:
	_origin = value

var _position: Vector2 setget _set_position
func _set_position(value: Vector2) -> void:
	_position = value

var _is_pushed: bool
func is_pushed() -> bool:
	return _is_pushed

func push() -> void:
	assert(not _is_pushed)
	_is_pushed = true

func pull(force: bool = false) -> void:
	assert(_is_pushed)
	_is_pushed = false

func move_to(position: Vector2) -> void:
	if position == _position:
		return
	_set_position(position)
	if not _is_pushed:
		_set_origin(_position)

func process_input_event_key(event: InputEventKey) -> bool:
	return false

func paint() -> void:
	pass

func draw(overlay: Control) -> void:
	pass

func can_paint_at(map_cell: Vector2) -> bool:
	return false
