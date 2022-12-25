extends Object

const Common = preload("common.gd")
const Iterators = preload("iterators.gd")

static func flood(position: Vector2, cell_checker: Iterators.Predicate, filler: Common.CellFiller):
	var cell_queue: Array
	cell_checker.init()
	filler.init()
	if not cell_checker.fit(position):
		return
	cell_queue.append(position)

	var upper_trigger: bool
	var lower_trigger: bool
	var temp_trigger_value: bool

	var triggers = [false, false]
	while not cell_queue.empty():
		var cell = cell_queue.pop_front()
		var start = cell.x
		# quickly walk left to the wall
		while true:
			cell.x -= 1
			if not cell_checker.fit(cell):
				break
		# walk right to other wall with paint and two triggers
		upper_trigger = false
		lower_trigger = false
		while true:
			cell.x += 1
			# skip passed cells checking
			if cell.x > start and not cell_checker.fit(cell):
				break

			filler.position = cell
			filler.perform()

			temp_trigger_value = upper_trigger
			upper_trigger = cell_checker.fit(cell + Vector2.UP)
			if upper_trigger and not temp_trigger_value:
				cell_queue.append(cell + Vector2.UP)

			temp_trigger_value = lower_trigger
			lower_trigger = cell_checker.fit(cell + Vector2.DOWN)
			if lower_trigger and not temp_trigger_value:
				cell_queue.append(cell + Vector2.DOWN)
