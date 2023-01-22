extends Object

const Iterators = preload("iterators.gd")

static func get_line(from_cell: Vector2, to_cell: Vector2, cell_half_offset_type: int) -> PoolVector2Array:
	if cell_half_offset_type == TileMap.HALF_OFFSET_DISABLED:
		return PoolVector2Array(Iterators.line(from_cell, to_cell).to_array())
	
	# Adapt the bresenham line algorithm to half-offset shapes.
	# See this blog post: http://zvold.blogspot.com/2010/01/bresenhams-line-drawing-algorithm-on_26.html
	var points: PoolVector2Array
	points.push_back(from_cell)

	var transposed: bool = cell_half_offset_type == TileMap.HALF_OFFSET_Y or cell_half_offset_type == TileMap.HALF_OFFSET_NEGATIVE_Y

	if transposed:
		from_cell = Vector2(from_cell.y, from_cell.x)
		to_cell = Vector2(to_cell.y, to_cell.x)
	
	if cell_half_offset_type > 2:
		if int(from_cell.y) & 1: from_cell.x -= 1
		if int(to_cell.y) & 1: to_cell.x -= 1

	var delta: Vector2 = to_cell - from_cell
	delta = Vector2(2 * delta.x + (int(to_cell.y) & 1) - (int(from_cell.y) & 1), delta.y);
	var delta_sign: Vector2 = delta.sign()

	var err: int
	if abs(delta.y) < abs(delta.x):
		var err_step: Vector2 = 3 * delta.abs()
		while from_cell != to_cell:
			err += err_step.y;
			if err > abs(delta.x):
				from_cell += \
					Vector2(delta_sign.y, 0) \
					if delta_sign.x == 0 else \
					Vector2(delta_sign.x * ((int(from_cell.y) & 1) ^ int(delta_sign.x < 0)), delta_sign.y)
					# если четный либо уходящий влево => сдвинуть влево на 1
				err -= err_step.x
			else:
				from_cell += Vector2(delta_sign.x, 0)
				err += err_step.y
			var cell = from_cell
			if cell_half_offset_type > 2 and (int(cell.y) & 1): cell.x += 1
			if transposed: cell = Vector2(cell.y, cell.x)
			points.push_back(cell)
	else:
		var err_step: Vector2 = delta.abs()
		while from_cell != to_cell:
			err += err_step.x;
			if err > 0:
				from_cell += \
					Vector2(0, delta_sign.y) \
					if delta_sign.x == 0 else \
					Vector2(delta_sign.x * ((int(from_cell.y) & 1) ^ int(delta_sign.x < 0)), delta_sign.y)
				err -= err_step.y
			else:
				from_cell += \
					Vector2(0, delta_sign.y) \
					if delta_sign.x == 0 else \
					Vector2(-delta_sign.x * ((int(from_cell.y) & 1) ^ int(delta_sign.x > 0)), delta_sign.y)
				err += err_step.y

			var cell = from_cell
			if cell_half_offset_type > 2 and (int(cell.y) & 1): cell.x += 1
			if transposed: cell = Vector2(cell.y, cell.x)
			points.push_back(cell)
	return points
