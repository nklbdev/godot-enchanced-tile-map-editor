extends Object

const ERR_MESSAGE = "Attempt to iterate an invalidated iterator"

static func to_iterator(array: Array) -> Iterator:
	return ArrayIterator.new(array)

static func flat_map(iterables, mapper = null) -> Iterator:
	return FlatMap.new(iterables, mapper)

static func map(iterable, mapper = null):
	return Map.new(iterable, mapper)

class Mapper:
	func map(value):
		return null

class Map:
	extends Iterator
	var __iterable
	var __mapper: Mapper
	
	func _init(iterable, mapper: Mapper = null) -> void:
		__iterable = iterable
		__mapper = mapper

	func _iter_init(arg) -> bool:
		return __iterable._iter_init(arg)

	func _iter_next(arg) -> bool:
		return __iterable._iter_next(arg)

	func _iter_get(arg):
		return __iterable._iter_get(arg) \
		if __mapper == null else \
		__mapper.map(__iterable._iter_get(arg))

class FlatMap:
	extends Iterator

	var __iterators: Iterator
	var __current_iterator: Iterator
	var __mapper: Mapper
	
	func _init(iterators: Iterator, mapper: Mapper = null) -> void:
		__iterators = iterators
	
	func _iter_init(arg) -> bool:
		if not ._iter_init(arg):
			return false
		if not __iterators._iter_init(arg):
			__current_iterator = null
			return false
		__current_iterator = __iterators._iter_get(arg)
		while true:
			if __current_iterator._iter_init(arg):
				return true
			elif not __iterators._iter_next(arg):
				break
		__current_iterator = null
		return false

	func _iter_next(arg) -> bool:
		while true:
			if __current_iterator._iter_next(arg):
				return true
			if not __iterators._iter_next(arg):
				break
			__current_iterator = __iterators._iter_get(arg)
		__current_iterator = null
		return false

	func _iter_get(arg):
		return __current_iterator._iter_get(arg) \
		if __mapper == null else \
		__mapper.map(__current_iterator._iter_get(arg))

class Iterator:
	func _iter_init(arg) -> bool:
		return false

	func _iter_next(arg) -> bool:
		return false

	func _iter_get(arg):
		return
	
class ArrayIterator:
	extends Iterator
	var __array: Array
	var __current: int
	var __size: int
	
	func _init(array: Array) -> void:
		__array = array
		__size = array.size()
	
	func _iter_init(arg) -> bool:
		__current = 0
		return __current < __size

	func _iter_next(arg) -> bool:
		__current += 1
		return __current < __size

	func _iter_get(arg):
		return __array[__current]

class InvalidatingIterator:
	extends Iterator
	var __is_valid: bool = true

	func _iter_init(arg) -> bool:
		if __is_valid:
			var result = _initialize(arg)
			if __is_valid:
				return result
		assert(false, ERR_MESSAGE)
		print_stack()
		return false

	func _iter_next(arg) -> bool:
		if __is_valid:
			var result = _next(arg)
			if __is_valid:
				return result
		assert(false, ERR_MESSAGE)
		print_stack()
		return false

	func _initialize(arg) -> bool:
		return false
	
	func _next(arg) -> bool:
		return false

	func _iter_get(arg):
		return

	func _iter_invalidate() -> void:
		__is_valid = false

#class SelectManyIterator:
#	extends Iterator
#
#	var __iterators: Iterator
#	var __current_iterator: Iterator
#
#	func _init(iterators: Iterator) -> void:
#		__iterators = iterators
#
#	func _iter_init(arg) -> bool:
#		if not ._iter_init(arg):
#			return false
#		if not __iterators._iter_init(arg):
#			__current_iterator = null
#			return false
#		__current_iterator = __iterators._iter_get(arg)
#		while true:
#			if __current_iterator._iter_init(arg):
#				return true
#			elif not __iterators._iter_next(arg):
#				break
#		__current_iterator = null
#		return false
#
#	func _iter_next(arg) -> bool:
#		while true:
#			if __current_iterator._iter_next(arg):
#				return true
#			if not __iterators._iter_next(arg):
#				break
#			__current_iterator = __iterators._iter_get(arg)
#		__current_iterator = null
#		return false
#
#	func _iter_get(arg):
#		__current_iterator._iter_get(arg)

class RectIterator:
	extends Iterator
	var __rect: Rect2
	var __current: Vector2

	func _init(rect: Rect2) -> void:
		var abs_rect = rect.abs()
		__rect = Rect2()
		__rect.position = abs_rect.position.floor()
		__rect.end = abs_rect.end.floor()
		_iter_init(false)

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
