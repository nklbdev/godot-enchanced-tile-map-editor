extends Object

const Iterators = preload("iterators.gd")

class PointPairToSegmentCellsMapper:
	extends Iterators.PairMapper
	func map(start: Vector2, finish: Vector2):
		return Iterators.line(start, finish, false)

class TransitionToScanlinesDataAggregator:
	extends Iterators.Aggregator
	var __first_line_position: int
	var __lines: Array

	func init():
		__first_line_position = 0
		__lines = []

	func add(value: Rect2):
		var current_line = __get_or_create_line(value.position.y)
		current_line.append(value.position.x)
		current_line.append(value.position.x)
		if value.size.y > 0:
			current_line.append(value.position.x)
		elif value.size.y < 0:
			__get_or_create_line(value.end.y).append(value.end.x)

	func get_result():
		for line in __lines:
			line.sort()
		return { lines = __lines, first_line_position = __first_line_position }

	func __get_or_create_line(line_position: int) -> Array:
		if __lines.empty() or line_position < __first_line_position:
			var line: Array
			__lines.push_front(line)
			__first_line_position = line_position
			return line
		elif line_position >= __first_line_position + __lines.size():
			var line: Array
			__lines.push_back(line)
			return line
		return __lines[line_position - __first_line_position]

class PointPairToTransitionMapper:
	extends Iterators.PairMapper
	func map(first: Vector2, second: Vector2):
		return Rect2(first, second - first)

class ScanlinePointToGlobalPointMapper:
	extends Iterators.Mapper
	var global_scanline_position: int
	func map(value: int) -> Vector2:
		return Vector2(value, global_scanline_position)

class IntervalToPointsSequenceMapper:
	extends Iterators.Mapper
	func map(value: Array):
#		return Iterators.iterate(range(value.front(), value.back() + 1))
		return Iterators.iterate(range(value.front() + 1, value.back()))

class ScanlineToFilledPointsMapper:
	extends Iterators.Mapper
	var first_line_position: int
	var __line_index: int
	var __scanline_point_to_global_point_mapper = ScanlinePointToGlobalPointMapper.new()
	var __interval_to_points_sequence_mapper = IntervalToPointsSequenceMapper.new()
	
	func init():
		__line_index = 0
	func map(scanline: Array):
		__scanline_point_to_global_point_mapper.global_scanline_position = first_line_position + __line_index
		__line_index += 1
		return Iterators \
			.iterate(scanline) \
			.chunk(2) \
			.map(__interval_to_points_sequence_mapper) \
			.flatten() \
			.skip_consecutive_duplicates() \
			.map(__scanline_point_to_global_point_mapper)

var __point_pair_to_segment_cells_mapper = PointPairToSegmentCellsMapper.new()
var __transition_to_scanlines_data_aggregator = TransitionToScanlinesDataAggregator.new()
var __point_pair_to_transition_mapper = PointPairToTransitionMapper.new()
var __scanline_to_filled_points_mapper = ScanlineToFilledPointsMapper.new()

func polygon_points(vertices: Array):
	var scanlines = polygon_stroke(vertices) \
		.chain(__point_pair_to_transition_mapper, true) \
		.aggregate(__transition_to_scanlines_data_aggregator)

	__scanline_to_filled_points_mapper.first_line_position = scanlines.first_line_position

	return Iterators \
		.iterate(scanlines.lines) \
		.map(__scanline_to_filled_points_mapper) \
		.flatten() \
#		.default(Iterators.iterate(vertices).take(1))

func polygon_stroke(vertices: Array):
	return Iterators \
		.iterate(vertices) \
		.chain(__point_pair_to_segment_cells_mapper, true) \
		.flatten() \
		.default(Iterators.iterate(vertices).take(1))
