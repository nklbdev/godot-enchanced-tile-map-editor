extends Object

const Common = preload("common.gd")

class LinePairMapper:
	extends Common.Iterators.PairMapper
	var y_min: int
	var y_max: int
	func reset(default_y: int):
		y_min == default_y
		y_max == default_y
	func map(first: Vector2, second: Vector2):
		if first.y < y_min:
			y_min = first.y
		if first.y > y_max:
			y_max = first.y
		return Common.Iterators.line(first, second)


class SkipConsecutiveDuplicatesPredicate:
	extends Common.Iterators.Predicate
	var __started: bool
	var __previous
	
	func reset():
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

var __line_mapper = LinePairMapper.new()
var __skip_duplicates_predicate = SkipConsecutiveDuplicatesPredicate.new()

func fill_polygon(vertices: PoolVector2Array, liner: Common.HorizontalLineConsumer):
	if vertices.empty():
		return

	__line_mapper.reset(vertices[0].y)
	__skip_duplicates_predicate.reset()
	var stroke_cells = Common.Iterators \
		.iterate(vertices) \
		.chain(__line_mapper, true) \
		.flatten() \
		.filter(__skip_duplicates_predicate) \
		.to_array()

	var y_min: int = __line_mapper.y_min
	var y_max: int = __line_mapper.y_max

	# Scan Line Loop:
	for scan_line_y in range(y_min, y_max + 1):
		var intersections: Array = []
		var start = stroke_cells.back()
		for cell in stroke_cells:
			if start.y == cell.y:
				start.x = cell.x
				continue

			var finish: Vector2 = cell
			if start.y > finish.y:
				finish = start
				start = cell

			if (scan_line_y >= start.y and scan_line_y < finish.y) or \
				(scan_line_y == y_max and scan_line_y > start.y and scan_line_y <= finish.y):
				# Умно! Добавляется 0.5 для безопасности преобразования обратно в int
				intersections.append(
					int(((scan_line_y - start.y) * (finish.x - start.x)) / (finish.y - start.y) + 0.5 + start.x))

			start = cell

		intersections.sort()

		# Не очень понимаю, зачем здесь обходится весь периметр для каждого сканлайна
		# наверно, чтобы дозакрасить некоторые пропущенные клетки
		for stroke_cell in stroke_cells:
			if stroke_cell.y == scan_line_y:
				__create_union(intersections, stroke_cell.x)

		for intersection_pair_index in range(0, intersections.size(), 2):
			liner.push_line(scan_line_y, intersections[intersection_pair_index], intersections[intersection_pair_index + 1])

# createUnion() joins a single scan point "x" (a pixel in other words)
# to the input vector "pairs".
# Each pair "pairs[i], pairs[i+1]" is a representation
# of a horizontal scan segment "i".
# An added scan point "x" to the "pairs" vector is represented
# by two consecutive values of "x" if it is an insolated point.
# If "x" is between or next to a scan segment, this function creates an
# union, making a fusion between "x" <-> "pairs[i], pairs[i+1]".
# Additionally, after the union step, this function handles
# overlapped situations respect to the nexts scan segments "i+2",
# "i+4", etc.
# Note: "pairs" must be sorted prior execution of this function.
static func __create_union(intersection_pairs: Array, x: int):
	var size = intersection_pairs.size()
	if size % 2 == 1:
		intersection_pairs.pop_back()
		size -= 1

	if intersection_pairs.empty():
		intersection_pairs.append(x)
		intersection_pairs.append(x)
		return

	var intersection_pair_index: int = -2
	while intersection_pair_index + 2 < intersection_pairs.size():# or intersection_pairs.size() == 1:
		intersection_pair_index += 2
	#for intersection_pair_index in range(0, size, 2):
		var from = intersection_pairs[intersection_pair_index]
		var to = intersection_pairs[intersection_pair_index + 1]
		# Case:     pairs[i]      pairs[i+1]
		#               O --------- O
		#            -x-
		if x == from - 1:
			intersection_pairs[intersection_pair_index] = x
			return

		# Case:  pairs[i]      pairs[i+1]
		#           O --------- O
		#   -x-
		if x < from - 1:
			intersection_pairs.insert(intersection_pair_index, x)
			intersection_pairs.insert(intersection_pair_index, x)
			return

		# Case:   pairs[i]      pairs[i+1]
		#            O --------- O
		#                         -x-
		# or                    -x-
		if x == to or x == to + 1:
			intersection_pairs[intersection_pair_index + 1] = x

			# while next intersection pair is present and
			# next pair is close or overlapping current pair
			# then merge pairs
			while intersection_pairs.size() > intersection_pair_index + 2 and \
				intersection_pairs[intersection_pair_index + 2] <= x + 1:

				intersection_pairs.pop_at(intersection_pair_index + 1)
				intersection_pairs.pop_at(intersection_pair_index + 1)
			return

		# Case:   pairs[i]      pairs[i+1]
		#            O --------- O
		#                 -x-
		if x >= from and x < to:
			return

	# Case:    pairs[i]      pairs[i+1]
	#             O --------- O
	#                             -x-
	if x > intersection_pairs.back():
		intersection_pairs.append(x)
		intersection_pairs.append(x)
