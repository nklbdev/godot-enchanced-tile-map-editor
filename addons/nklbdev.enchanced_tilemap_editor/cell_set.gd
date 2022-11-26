extends Object
const Iterators = preload("iterators.gd")

var __rects: Array = []

func get_rects() -> Iterators.Iterator:
	return Iterators.map(__rects)

func get_cells() -> Iterators.Iterator:
	return Iterators.flat_map(__rects, __RectToRectIteratorMapper.get_instance())

func add(cell_set):
	return null

func subtract(cell_set):
	return null

func intersect(cell_set):
	return null

static func from_rects(rects): # array or iterator
	pass

static func from_cells(cells): # array or iterator
	pass

class RectCellSet

class SortedCellSet:
	extends CellSet
	pass

class CellSet:
	# for cell in cell_set:
	pass

##########################################
#               ITERATION                #
##########################################

class __RectToRectIteratorMapper:
	extends Iterators.Mapper
	const STATICS = []
	
	static func get_instance() -> __RectToRectIteratorMapper:
		if STATICS.empty():
			STATICS.append(__RectToRectIteratorMapper.new())
		return STATICS[0]
	
	# func map(value: Rect) -> Iterators.RectIterator:
	func map(value):
		return Iterators.RectIterator.new(value)
