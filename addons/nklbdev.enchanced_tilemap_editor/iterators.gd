extends Object

const ERR_MESSAGE: String = "Attempt to iterate an invalidated iterator"

static func line(start: Vector2, finish: Vector2, finish_inclusive: bool = true) -> Iterator:
	return LineIterator.new(start, finish, finish_inclusive)

static func rect(rect: Rect2, finish_inclusive: bool = true):
	return RectIterator.new(rect, finish_inclusive)

static func iterate(array: Array) -> Iterator:
	return ArrayIterator.new(array)

static func interleave(iterators: Array) -> Iterator:
	return InterleaveIterator.new(iterate(iterators))

class Action:
	extends __Processor
	func perform() -> void:
		pass

class __Processor:
	func init():
		pass

class Mapper:
	extends __Processor
	func map(value):
		return value

class __VectorAddMapper:
	extends __Processor
	var __val: Vector2
	func _init(val: Vector2) -> void:
		__val = val
	func map(value: Vector2) -> Vector2:
		return value + __val

class __VectorMultiplyMapper:
	extends __Processor
	var __val: Vector2
	func _init(val: Vector2) -> void:
		__val = val
	func map(value: Vector2) -> Vector2:
		return value * __val

class PairMapper:
	extends __Processor
	func map(first, second):
		return [first, second]

class Predicate:
	extends __Processor
	func fit(value) -> bool:
		return false

class Aggregator:
	extends __Processor
	func add(value):
		pass
	func get_result():
		return null

class Iterator:
	func _iter_init(arg) -> bool:
		return false

	func _iter_next(arg) -> bool:
		return false

	func _iter_get(arg):
		return

	func take(count: int) -> TakeIterator:
		return TakeIterator.new(self, count)

	func skip(count: int) -> SkipIterator:
		return SkipIterator.new(self, count)

	func _while(predicate: Predicate) -> WhileIterator:
		return WhileIterator.new(self, predicate)

	func map(mapper) -> MapIterator:
		return MapIterator.new(self, mapper)

	func flatten() -> FlattenIterator:
		return FlattenIterator.new(self)

	func all(predicate: Predicate) -> bool:
		predicate.init()
		for value in self:
			if not predicate.fit(value):
				return false
		return true

	func any() -> bool:
		return _iter_init([[]])

	func concat(iterator: Iterator) -> Iterator:
		assert(false, "Not implemented yet")
		return null

	func front(default = null):
		return _iter_get([]) if _iter_init([[]]) else default

	func back(default = null):
		var last = default
		for value in self:
			last = value
		return last

	func filter(predicate: Predicate) -> FilterIterator:
		return FilterIterator.new(self, predicate)

	func to_array() -> Array:
		var array: Array = []
		for value in self:
			array.append(value)
		return array

	func aggregate(aggregator: Aggregator) -> Iterator:
		aggregator.init()
		for value in self:
			aggregator.add(value)
		return aggregator.get_result()

	func interleave(another_iterator: Iterator) -> Iterator:
		return InterleaveIterator.new(ArrayIterator.new([self, another_iterator]))

	func chain(pair_mapper: PairMapper, looped: bool = false) -> Iterator:
		return ChainIterator.new(self, pair_mapper, looped)

	func chunk(size: int) -> Iterator:
		return ChunkIterator.new(self, size)

	func default(iterator: Iterator) -> Iterator:
		return DefaultIterator.new(self, iterator)

	func skip_consecutive_duplicates() -> Iterator:
		return filter(SkipConsecutiveDuplicatesPredicate.new())

	func vector_add(val: Vector2) -> Iterator:
		return map(__VectorAddMapper.new(val))

	func vector_mul(val: Vector2) -> Iterator:
		return map(__VectorMultiplyMapper.new(val))

	func _to_string() -> String:
		return "[" + ", ".join(take(3).map(StringMapper.new()).to_array()) + "]"

	class StringMapper:
		extends Mapper
		func map(value) -> String:
			return str(value)

class SkipConsecutiveDuplicatesPredicate:
	extends Predicate
	var __started: bool
	var __previous
	
	func init():
		__started = false
		__previous = null

	func fit(value) -> bool:
		if __started:
			if value == __previous:
				return false
		else:
			__started = true
		__previous = value
		return true

class ChunkIterator:
	extends Iterator
	var __iterator: Iterator
	var __size: int
	var __chunk: Array
	var __values_count_in_chunk: int

	func _init(iterator: Iterator, size: int) -> void:
		assert(size > 0, "Chunk size must be positive! Actual size is: %s" % size)
		__iterator = iterator
		__size = size

	func _iter_init(arg) -> bool:
		__chunk.resize(__size)
		__values_count_in_chunk = 0
		if not __iterator._iter_init(arg):
			return false
		__chunk[0] = __iterator._iter_get(arg)
		__values_count_in_chunk = 1
		__fill_chunk(arg)
		return true

	func _iter_next(arg) -> bool:
		__values_count_in_chunk = 0
		__fill_chunk(arg)
		if __values_count_in_chunk > 0:
			__chunk.resize(__values_count_in_chunk)
			return true
		else:
			__chunk.fill(null)
			return false

	func _iter_get(arg):
		return __chunk

	func __fill_chunk(arg):
		while __values_count_in_chunk < __size and __iterator._iter_next(arg):
			__chunk[__values_count_in_chunk] = __iterator._iter_get(arg)
			__values_count_in_chunk += 1

class ChainIterator:
	extends Iterator
	var __iterator: Iterator
	var __pair_mapper: PairMapper
	var __first
	var __current
	var __value
	var __is_completed: bool
	var __looped: bool

	func _init(iterator: Iterator, pair_mapper: PairMapper, looped: bool = false) -> void:
		__iterator = iterator
		__pair_mapper = pair_mapper
		__looped = looped

	func _iter_init(arg) -> bool:
		__pair_mapper.init()
		__first = null
		if not __iterator._iter_init(arg):
			return false
		__current = __iterator._iter_get(arg)
		if __looped:
			__first = __current
		return _iter_next(arg)

	func _iter_next(arg) -> bool:
		if __is_completed:
			return false
		if __iterator._iter_next(arg):
			var previous = __current
			__current = __iterator._iter_get(arg)
			__value = __pair_mapper.map(previous, __current)
			return true
		else:
			if not __looped:
				return false
			__value = __pair_mapper.map(__current, __first)
			__is_completed = true
			return true

	func _iter_get(arg):
		return __value

class DefaultIterator:
	extends Iterator
	var __iterator: Iterator
	var __defaults: Iterator
	var __iterator_continues: bool
	var __defaults_continues: bool
	var __value

	func _init(iterator: Iterator, defaults: Iterator) -> void:
		__iterator = iterator
		__defaults = defaults

	func _iter_init(arg) -> bool:
		__value = null
		__iterator_continues = __iterator._iter_init(arg)
		__defaults_continues = __defaults._iter_init(arg)
		return __update_value(arg)

	func _iter_next(arg) -> bool:
		__iterator_continues = __iterator_continues and __iterator._iter_next(arg)
		__defaults_continues = __defaults_continues and __defaults._iter_next(arg)
		return __update_value(arg)

	func _iter_get(arg):
		return __value

	func __update_value(arg):
		if __iterator_continues:
			__value = __iterator._iter_get(arg)
			return true
		elif __defaults_continues:
			__value = __defaults._iter_get(arg)
			return true
		return false

class FilterIterator:
	extends Iterator
	var __iterator: Iterator
	var __predicate: Predicate
	var __value

	func _init(iterator: Iterator, predicate: Predicate) -> void:
		__iterator = iterator
		__predicate = predicate

	func _iter_init(arg) -> bool:
		__predicate.init()
		__value = null
		if __iterator._iter_init(arg):
			__value = __iterator._iter_get(arg)
			return true if __predicate.fit(__value) else _iter_next(arg)
		__value = null
		return false

	func _iter_next(arg) -> bool:
		while __iterator._iter_next(arg):
			__value = __iterator._iter_get(arg)
			if __predicate.fit(__value):
				return true
		__value = null
		return false

	func _iter_get(arg):
		return __value

class TakeIterator:
	extends Iterator
	var __iterator: Iterator
	var __take_count: int
	var __current: int
	var __value

	func _init(iterator: Iterator, count: int) -> void:
		__iterator = iterator
		__take_count = count

	func _iter_init(arg) -> bool:
		__value = null
		__current = 0
		if __take_count > 0 and __iterator._iter_init(arg):
			__value = __iterator._iter_get(arg)
			return true
		__value = null
		return false

	func _iter_next(arg) -> bool:
		__current += 1
		if __current < __take_count and __iterator._iter_next(arg):
			__value = __iterator._iter_get(arg)
			return true
		__value = null
		return false

	func _iter_get(arg):
		return __value

class SkipIterator:
	extends Iterator
	var __iterator: Iterator
	var __skip_count: int
	var __current: int
	var __value

	func _init(iterator: Iterator, count: int) -> void:
		__iterator = iterator
		__skip_count = count

	func _iter_init(arg) -> bool:
		__value = null
		__current = 0
		if __iterator._iter_init(arg):
			while __current < __skip_count:
				if not __iterator._iter_next(arg):
					return false
				__current += 1
			__value = __iterator._iter_get(arg)
			return true
		__value = null
		return false

	func _iter_next(arg) -> bool:
		if __iterator._iter_next(arg):
			__value = __iterator._iter_get(arg)
			return true
		return false

	func _iter_get(arg):
		return __value

class WhileIterator:
	extends Iterator
	var __iterator: Iterator
	var __predicate: Predicate
	var __value

	func _init(iterator: Iterator, predicate: Predicate) -> void:
		__iterator = iterator
		__predicate = predicate

	func _iter_init(arg) -> bool:
		__predicate.init()
		__value = null
		if __iterator._iter_init(arg):
			__value = __iterator._iter_get(arg)
			return __predicate.fit(__iterator._iter_get(arg))
		__value = null
		return false

	func _iter_next(arg) -> bool:
		if __iterator._iter_next(arg):
			__value = __iterator._iter_get(arg)
			return __predicate.fit(__iterator._iter_get(arg))
		__value = null
		return false

	func _iter_get(arg):
		return __value

class MapIterator:
	extends Iterator
	var __iterator
	var __mapper: Mapper
	var __value
	
	func _init(iterator, mapper: Mapper = null) -> void:
		__iterator = iterator
		__mapper = mapper

	func _iter_init(arg) -> bool:
		__mapper.init()
		__value = null
		if __iterator._iter_init(arg):
			__value = __mapper.map(__iterator._iter_get(arg))
			return true
		__value = null
		return false

	func _iter_next(arg) -> bool:
		if __iterator._iter_next(arg):
			__value = __mapper.map(__iterator._iter_get(arg))
			return true
		__value = null
		return false

	func _iter_get(arg):
		return __value

class InterleaveIterator:
	extends Iterator

	var __iterators: Iterator
	var __first_iteration: bool = true
	var __value
	
	func _init(iterators: Iterator) -> void:
		__iterators = iterators
	
	func _iter_init(arg) -> bool:
		__value = null
		if not __iterators._iter_init(arg):
			return false
		var iterator = __iterators._iter_get(arg)
		if iterator._iter_init(arg):
			__value = iterator._iter_get(arg)
			return true
		return false

	func _iter_next(arg) -> bool:
		if __iterators._iter_next(arg):
			var iterator = __iterators._iter_get(arg)
			if iterator._iter_init(arg) if __first_iteration else iterator._iter_next(arg):
				__value = iterator._iter_get(arg)
				return true
			else:
				__value = null
				return false
		else:
			__first_iteration = false
			__iterators._iter_init(arg)
			return _iter_next(arg)

	func _iter_get(arg):
		return __value

class FlattenIterator:
	extends Iterator

	var __iterators: Iterator
	var __current_iterator: Iterator
	var __value
	
	func _init(iterators: Iterator) -> void:
		__iterators = iterators
	
	func _iter_init(arg) -> bool:
		__current_iterator = null
		__value = null
		if not __iterators._iter_init(arg):
			return false
		__current_iterator = __iterators._iter_get(arg)
		if __current_iterator._iter_init(arg):
			__value = __current_iterator._iter_get(arg)
			return true
		return __next_initialized_iterator(arg)

	func _iter_next(arg) -> bool:
		if __current_iterator._iter_next(arg):
			__value = __current_iterator._iter_get(arg)
			return true
		return __next_initialized_iterator(arg)

	func __next_initialized_iterator(arg) -> bool:
		while __iterators._iter_next(arg):
			__current_iterator = __iterators._iter_get(arg)
			if __current_iterator._iter_init(arg):
				__value = __current_iterator._iter_get(arg)
				return true
		__current_iterator = null
		__value = null
		return false

	func _iter_get(arg):
		return __value

class ArrayIterator:
	extends Iterator
	var __array: Array
	var __current: int
	var __size: int
	
	func _init(array: Array) -> void:
		__array = array
		__size = array.size()
	
	func _iter_init(arg) -> bool: # arg is array. first element is empty array - no iterated items
		__current = 0
		return __current < __size

	func _iter_next(arg) -> bool: # arg is array. first element is array with items were iterated
		__current += 1
		return __current < __size

	func _iter_get(arg): # arg is array with items were iterated
		return __array[__current]

class InvalidatingIterator:
	extends Iterator
	var __is_valid: bool = true

	func _iter_init(arg) -> bool:
		if __is_valid:
			var result = _iter_init_valid(arg)
			if __is_valid:
				return result
		assert(false, ERR_MESSAGE)
		print_stack()
		return false

	func _iter_init_valid(arg) -> bool:
		return false

	func _iter_next(arg) -> bool:
		if __is_valid:
			var result = _iter_next_valid(arg)
			if __is_valid:
				return result
		assert(false, ERR_MESSAGE)
		print_stack()
		return false

	func _iter_next_valid(arg) -> bool:
		return false

	func _iter_get(arg):
		return

	func _iter_invalidate() -> void:
		__is_valid = false

class RectIterator:
	extends Iterator
	var __left_top: Vector2
	var __right_bottom: Vector2
	var __current: Vector2

	func _init(rect: Rect2, finish_inclusive: bool = true) -> void:
		var abs_rect = rect.abs()
		__left_top = abs_rect.position.floor()
		__right_bottom = abs_rect.end.floor()
		if not finish_inclusive:
			__right_bottom -= Vector2.ONE

	func _iter_init(arg) -> bool:
		__current = __left_top
		return __current.x < __right_bottom.x and __current.y < __right_bottom.y

	func _iter_next(arg) -> bool:
		if __current.x < __right_bottom.x:
			__current.x += 1
			return true
		if __current.y < __right_bottom.y:
			__current = Vector2(__left_top.x, __current.y + 1)
			return true
		return false

	func _iter_get(arg) -> Vector2:
		return __current

class LineIterator:
	extends Iterator
	
	var __start: Vector2
	var __finish: Vector2
	var __step_count: int
	var __current_step: int
	var __limit: int
	
	func _init(start: Vector2, finish: Vector2, finish_inclusive: bool = true) -> void:
		__start = start
		__finish = finish
		var path = (finish - start).abs()
		__step_count = max(path.x, path.y)
		__limit = __step_count + 1 if finish_inclusive else __step_count

	func _iter_init(arg) -> bool:
		__current_step = 0
		return __limit > 0

	func _iter_next(arg) -> bool:
		__current_step += 1
		return __current_step < __limit

	func _iter_get(arg) -> Vector2:
		return __start if __step_count == 0 else \
			__start.linear_interpolate(__finish, float(__current_step) / __step_count).round()
