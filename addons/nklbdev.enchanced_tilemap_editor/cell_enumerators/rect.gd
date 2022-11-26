extends "_base.gd"

var __rect: Rect2
var __current: Vector2

func _init(rect: Rect2) -> void:
	var abs_rect = rect.abs()
	__rect = Rect2()
	__rect.position = abs_rect.position.floor()
	__rect.end = abs_rect.end.floor()
	_iter_init(false)

func _should_continue() -> bool:
	return __current.x < __rect.end.x or __current.y < __rect.end.y

func _iter_init(arg) -> bool:
	__current = __rect.position
	return true

func _iter_next(arg) -> bool:
	if __current.x < __rect.end.x:
		__current.x += 1
		return true
	if __current.y < __rect.end.y:
		__current = Vector2(__rect.position.x, __current.y + 1)
		return true
	return false

func _iter_get(arg) -> Vector2:
	return __current
