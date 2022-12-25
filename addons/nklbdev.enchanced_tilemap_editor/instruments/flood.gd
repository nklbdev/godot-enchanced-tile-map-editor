extends "_base.gd"

const Iterators = preload("../iterators.gd")

func _init(brush: Brush, drawing_settings: Common.DrawingSettings).(brush, drawing_settings) -> void:
	pass

func _after_pushed() -> void:
	pass
#	var sections_data: PoolVector3Array = _paper.get_sections_in_cell(_origin_cell) 
#	_brush.paint(_origin_cell)
#
#	var cell_queue: Array
#	if not cell_checker.fit(position):
#		return
#	cell_queue.append(position)
#
#	var upper_trigger: bool
#	var lower_trigger: bool
#	var temp_trigger_value: bool
#
#	var triggers = [false, false]
#	while not cell_queue.empty():
#		var cell = cell_queue.pop_front()
#		var start = cell.x
#		# quickly walk left to the wall
#		while true:
#			cell.x -= 1
#			if not cell_checker.fit(cell):
#				break
#		# walk right to other wall with paint and two triggers
#		upper_trigger = false
#		lower_trigger = false
#		while true:
#			cell.x += 1
#			# skip passed cells checking
#			if cell.x > start and not cell_checker.fit(cell):
#				break
#
#			filler.position = cell
#			filler.perform()
#
#			temp_trigger_value = upper_trigger
#			upper_trigger = cell_checker.fit(cell + Vector2.UP)
#			if upper_trigger and not temp_trigger_value:
#				cell_queue.append(cell + Vector2.UP)
#
#			temp_trigger_value = lower_trigger
#			lower_trigger = cell_checker.fit(cell + Vector2.DOWN)
#			if lower_trigger and not temp_trigger_value:
#				cell_queue.append(cell + Vector2.DOWN)


#func _on_moved() -> void:
#	if _is_pushed:
#		_paper.reset_changes()
#		# draw line
#		# todo: improve line algorithm
#		for cell in Iterators.line(_origin_cell, _cell):
#			_brush.paint(cell)

func _on_draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
#	if _is_pushed:
#		# draw line
#		# todo: improve line algorithm
#		for cell in Iterators.line(_origin_cell, _cell):
#			overlay.draw_rect(_paper.get_cell_world_rect(cell), )
	pass
