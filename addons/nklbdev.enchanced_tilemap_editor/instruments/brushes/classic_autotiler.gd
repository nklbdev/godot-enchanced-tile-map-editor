#extends "../_base.gd"
#
#const Instrument = preload("../_base.gd")
#
#var __tile_set: TileSet
#
#func _on_start() -> void:
#	__tile_set = _transaction_parent.get_tile_set()
#
#func _on_apply_changes_and_close_inner_transactions() -> void:
#	pass
#
#func _on_break_last_change() -> bool:
#	return true
#
#func _on_break_all_changes_and_close_inner_transactions() -> void:
#	pass
#
#func _on_finish() -> void:
#	__tile_set = null
#
#func _on_mode_changed() -> void:
#	pass
#
#func _on_pushed() -> void:
#	if is_active():
#		__paint(true)
#
#func _on_pulled() -> void:
#	pass
#
#func _on_moved(previous_position: Vector2) -> void:
#	if is_active() and _is_pushed and _position.floor() != previous_position.floor():
#		__paint(true)
#
#
#
#
##func forward_canvas_draw_over_viewport(overlay: Control) -> void:
##	pass
#
#func forward_canvas_force_draw_over_viewport(overlay: Control, tile_map: TileMap) -> void:
#	pass
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#var __current_tile_id = 0
#var __dragging_button: int
#
#const square: Rect2 = Rect2(Vector2.ZERO, Vector2.ONE)
#const bitmask_color: Color = Color.red * Color(1, 1, 1, 0.5)
#const grid_color: Color = Color.coral * Color(1, 1, 1, 0.5)
#
#const ZONES: PoolVector2Array = PoolVector2Array([
#	# 2X2 index 0 count 9
#	Vector2(0, 0) / 2, Vector2(1, 1) / 2,
#	Vector2(1, 0) / 2, Vector2(0, 1) / 2,
#	Vector2(1, 0) / 2, Vector2(1, 1) / 2,
#
#	Vector2(0, 1) / 2, Vector2(1, 0) / 2,
#	Vector2(1, 1) / 2, Vector2(0, 0) / 2,
#	Vector2(1, 1) / 2, Vector2(1, 0) / 2,
#
#	Vector2(0, 1) / 2, Vector2(1, 1) / 2,
#	Vector2(1, 1) / 2, Vector2(0, 1) / 2,
#	Vector2(1, 1) / 2, Vector2(1, 1) / 2,
#
#	# 3X3 index 9 count 9
#	Vector2(0, 0) / 4, Vector2(1, 1) / 4,
#	Vector2(1, 0) / 4, Vector2(2, 1) / 4,
#	Vector2(3, 0) / 4, Vector2(1, 1) / 4,
#
#	Vector2(0, 1) / 4, Vector2(1, 2) / 4,
#	Vector2(1, 1) / 4, Vector2(2, 2) / 4,
#	Vector2(3, 1) / 4, Vector2(1, 2) / 4,
#
#	Vector2(0, 3) / 4, Vector2(1, 1) / 4,
#	Vector2(1, 3) / 4, Vector2(2, 1) / 4,
#	Vector2(3, 3) / 4, Vector2(1, 1) / 4,
#])
#
#
## TOPLEFT       1  0
## TOP           2  1
## TOPRIGHT      4  2
## LEFT          8  3
## CENTER       16  4
## RIGHT        32  5
## BOTTOMLEFT   64  6
## BOTTOM      128  7
## BOTTOMRIGHT 256  8
#
#enum {
#	IND_TOPLEFT     = 0,
#	IND_TOP         = 1,
#	IND_TOPRIGHT    = 2,
#	IND_LEFT        = 3,
#	IND_CENTER      = 4,
#	IND_RIGHT       = 5,
#	IND_BOTTOMLEFT  = 6,
#	IND_BOTTOM      = 7,
#	IND_BOTTOMRIGHT = 8,
#}
#
#enum {
#	BIT_TYPE_CORNER = 0,
#	BIT_TYPE_SIDE   = 1,
#	BIT_TYPE_CENTER = 2,
#}
#
#const BIT_TYPES: PoolIntArray = PoolIntArray([
#	BIT_TYPE_CORNER, # TOPLEFT       1  0
#	BIT_TYPE_SIDE,   # TOP           2  1
#	BIT_TYPE_CORNER, # TOPRIGHT      4  2
#	BIT_TYPE_SIDE,   # LEFT          8  3
#	BIT_TYPE_CENTER, # CENTER       16  4
#	BIT_TYPE_SIDE,   # RIGHT        32  5
#	BIT_TYPE_CORNER, # BOTTOMLEFT   64  6
#	BIT_TYPE_SIDE,   # BOTTOM      128  7
#	BIT_TYPE_CORNER, # BOTTOMRIGHT 256  8
#])
#
#const NEIGHBOR_DATA_INDICES: PoolIntArray = PoolIntArray([
#	# start, count
#	0,  3, # TOPLEFT       1           1  0
#	3,  1, # TOP           2          10  1
#	4,  3, # TOPRIGHT      4         100  2
#	7,  1, # LEFT          8        1000  3
#	8,  0, # CENTER       16       10000  4
#	8,  1, # RIGHT        32      100000  5
#	9,  3, # BOTTOMLEFT   64     1000000  6
#	12, 1, # BOTTOM      128    10000000  7
#	13, 3, # BOTTOMRIGHT 256   100000000  8
#])
#
#const NEIGHBOR_CELL_POSITIONS: PoolVector2Array = PoolVector2Array([
#	# TOPLEFT       1
#	Vector2(-1,  0), #  0
#	Vector2(-1, -1), #  1
#	Vector2( 0, -1), #  2
#	# TOP           2
#	Vector2( 0, -1), #  3
#	# TOPRIGHT      4
#	Vector2( 0, -1), #  4
#	Vector2( 1, -1), #  5
#	Vector2( 1,  0), #  6
#	# LEFT          8
#	Vector2(-1,  0), #  7
#	# CENTER       16
#	# RIGHT        32
#	Vector2( 1,  0), #  8
#	# BOTTOMLEFT   64
#	Vector2( 0,  1), #  9
#	Vector2(-1,  1), # 10
#	Vector2(-1,  0), # 11
#	# BOTTOM      128
#	Vector2( 0,  1), # 12
#	# BOTTOMRIGHT 256
#	Vector2( 1,  0), # 13
#	Vector2( 1,  1), # 14
#	Vector2( 0,  1), # 15
#])
#
#const NEIGHBOR_CELL_BIT_INDICES: PoolIntArray = PoolIntArray([
#	# TOPLEFT       1
#	IND_TOPRIGHT,    #  0
#	IND_BOTTOMRIGHT, #  1
#	IND_BOTTOMLEFT,  #  2
#	# TOP           2
#	IND_BOTTOM,      #  3
#	# TOPRIGHT      4
#	IND_BOTTOMRIGHT, #  4
#	IND_BOTTOMLEFT,  #  5
#	IND_TOPLEFT,     #  6
#	# LEFT          8
#	IND_RIGHT,       #  7
#	# CENTER       16
#	# RIGHT        32
#	IND_LEFT,        #  8
#	# BOTTOMLEFT   64
#	IND_TOPLEFT,     #  9
#	IND_TOPRIGHT,    # 10
#	IND_BOTTOMRIGHT, # 11
#	# BOTTOM      128
#	IND_TOP,         # 12
#	# BOTTOMRIGHT 256
#	IND_BOTTOMLEFT,  # 13
#	IND_TOPLEFT,     # 14
#	IND_TOPRIGHT,    # 15
#])
#
#const DIRECTIONS: PoolVector2Array = PoolVector2Array([
#	Vector2(-1, -1), # TOPLEFT       1  0
#	Vector2( 0, -1), # TOP           2  1
#	Vector2( 1, -1), # TOPRIGHT      4  2
#	Vector2(-1,  0), # LEFT          8  3
#	Vector2( 0,  0), # CENTER       16  4
#	Vector2( 1,  0), # RIGHT        32  5
#	Vector2(-1,  1), # BOTTOMLEFT   64  6
#	Vector2( 0,  1), # BOTTOM      128  7
#	Vector2( 1,  1), # BOTTOMRIGHT 256  8
#])
#
#const INNER_NEIGHBOR_DATA_INDICES: PoolIntArray = PoolIntArray([
#	# start, count
#	0,  3, # TOPLEFT       1           1  0
#	3,  5, # TOP           2          10  1
#	8,  3, # TOPRIGHT      4         100  2
#	11, 5, # LEFT          8        1000  3
#	16, 8, # CENTER       16       10000  4
#	24, 5, # RIGHT        32      100000  5
#	29, 3, # BOTTOMLEFT   64     1000000  6
#	32, 5, # BOTTOM      128    10000000  7
#	37, 3, # BOTTOMRIGHT 256   100000000  8
#])
#
#const INNER_NEIGHBORS: PoolIntArray = PoolIntArray([
#	IND_TOP, IND_CENTER, IND_LEFT,                                                                        # TOPLEFT       1  0
#	IND_TOPRIGHT, IND_RIGHT, IND_CENTER, IND_LEFT, IND_TOPLEFT,                                           # TOP           2  1
#	IND_RIGHT, IND_CENTER, IND_TOP,                                                                       # TOPRIGHT      4  2
#	IND_TOPLEFT, IND_TOP, IND_CENTER, IND_BOTTOM, IND_BOTTOMLEFT,                                         # LEFT          8  3
#	IND_TOPLEFT, IND_TOP, IND_TOPRIGHT, IND_RIGHT, IND_BOTTOMRIGHT, IND_BOTTOM, IND_BOTTOMLEFT, IND_LEFT, # CENTER       16  4
#	IND_BOTTOMRIGHT, IND_BOTTOM, IND_CENTER, IND_TOP, IND_TOPRIGHT,                                       # RIGHT        32  5
#	IND_LEFT, IND_CENTER, IND_BOTTOM,                                                                     # BOTTOMLEFT   64  6
#	IND_BOTTOMLEFT, IND_LEFT, IND_CENTER, IND_RIGHT, IND_BOTTOMRIGHT,                                     # BOTTOM      128  7
#	IND_BOTTOM, IND_CENTER, IND_RIGHT,                                                                    # BOTTOMRIGHT 256  8
#])
#
#const BITS_TO_SET_3X3_MINIMAL: PoolIntArray = PoolIntArray([
#	TileSet.BIND_TOP | TileSet.BIND_CENTER | TileSet.BIND_LEFT,     # TOPLEFT       1  0
#	TileSet.BIND_CENTER,                                            # TOP           2  1
#	TileSet.BIND_RIGHT | TileSet.BIND_CENTER | TileSet.BIND_TOP,    # TOPRIGHT      4  2
#	TileSet.BIND_CENTER,                                            # LEFT          8  3
#	0,                                                              # CENTER       16  4
#	TileSet.BIND_CENTER,                                            # RIGHT        32  5
#	TileSet.BIND_LEFT | TileSet.BIND_CENTER | TileSet.BIND_BOTTOM,  # BOTTOMLEFT   64  6
#	TileSet.BIND_CENTER,                                            # BOTTOM      128  7
#	TileSet.BIND_BOTTOM | TileSet.BIND_CENTER | TileSet.BIND_RIGHT, # BOTTOMRIGHT 256  8
#])
#
#const BITS_TO_CLEAR_3X3_MINIMAL: PoolIntArray = PoolIntArray([
#	0,                                                                         # TOPLEFT       1  0
#	TileSet.BIND_TOPLEFT     | TileSet.BIND_TOPRIGHT,                          # TOP           2  1
#	0,                                                                         # TOPRIGHT      4  2
#	TileSet.BIND_BOTTOMLEFT  | TileSet.BIND_TOPLEFT,                           # LEFT          8  3
#
#	TileSet.BIND_TOPLEFT     | TileSet.BIND_TOP    | TileSet.BIND_TOPRIGHT    | \
#	TileSet.BIND_LEFT        | TileSet.BIND_CENTER | TileSet.BIND_RIGHT       | \
#	TileSet.BIND_BOTTOMLEFT  | TileSet.BIND_BOTTOM | TileSet.BIND_BOTTOMRIGHT, # CENTER       16  4
#
#	TileSet.BIND_TOPRIGHT    | TileSet.BIND_BOTTOMRIGHT,                       # RIGHT        32  5
#	0,                                                                         # BOTTOMLEFT   64  6
#	TileSet.BIND_BOTTOMRIGHT | TileSet.BIND_BOTTOMLEFT,                        # BOTTOM      128  7
#	0,                                                                         # BOTTOMRIGHT 256  8
#])
#
#const MASK_BIT_3X3_INDEX_BY_HEXLET_INDEX: PoolIntArray = PoolIntArray([
#	IND_TOPLEFT,    IND_TOP,    IND_TOP,    IND_TOPRIGHT,
#	IND_LEFT,       IND_CENTER, IND_CENTER, IND_RIGHT,
#	IND_LEFT,       IND_CENTER, IND_CENTER, IND_RIGHT,
#	IND_BOTTOMLEFT, IND_BOTTOM, IND_BOTTOM, IND_BOTTOMRIGHT
#])
#
#const MASK_BIT_2X2_INDEX_BY_HEXLET_INDEX: PoolIntArray = PoolIntArray([
#	IND_TOPLEFT,    IND_TOPLEFT,    IND_TOPRIGHT,    IND_TOPRIGHT,
#	IND_TOPLEFT,    IND_TOPLEFT,    IND_TOPRIGHT,    IND_TOPRIGHT,
#	IND_BOTTOMLEFT, IND_BOTTOMLEFT, IND_BOTTOMRIGHT, IND_BOTTOMRIGHT,
#	IND_BOTTOMLEFT, IND_BOTTOMLEFT, IND_BOTTOMRIGHT, IND_BOTTOMRIGHT
#])
#
#func __paint(value: bool) -> void:
#	if __tile_set.tile_get_tile_mode(__current_tile_id) != TileSet.AUTO_TILE:
#		return
#	var hexlet = ((_position - _position.floor()) * 4).floor()
#	var mask_bit_index = \
#		MASK_BIT_2X2_INDEX_BY_HEXLET_INDEX[hexlet.y * 4 + hexlet.x] \
#		if __tile_set.autotile_get_bitmask_mode(__current_tile_id) == TileSet.BITMASK_2X2 else \
#		MASK_BIT_3X3_INDEX_BY_HEXLET_INDEX[hexlet.y * 4 + hexlet.x]
#	__set_mask_bit(_position.floor(), mask_bit_index, value)
#
#func __set_mask_bit(cell: Vector2, bit_index: int, bit_value: bool) -> void:
#	# 0 - tile_id
#	# 1 - transform
#	# 2 - autotile_coord.x
#	# 3 - autotile_coord.y
#	var cell_data: PoolIntArray = _transaction_parent.get_cell_data(cell)
#	var actual_tile_id: int = cell_data[0]
#	var bitmask: int = 0 if actual_tile_id != __current_tile_id else \
#		__tile_set.autotile_get_bitmask(__current_tile_id, Vector2(cell_data[2], cell_data[3]))
#	var previous_bitmask: int = bitmask
#	match __tile_set.autotile_get_bitmask_mode(__current_tile_id):
#		TileSet.BITMASK_2X2: # боковые биты не устанавливаются
#			if BIT_TYPES[bit_index] == BIT_TYPE_CORNER:
#				if bit_value:
#					bitmask |= 1 << bit_index
#				else:
#					bitmask &= ~(1 << bit_index)
#		TileSet.BITMASK_3X3_MINIMAL: # снимаются соседние угловые для бокового и устанавливаются все соседи для углового
#			if bit_value:
#				bitmask |= 1 << bit_index | BITS_TO_SET_3X3_MINIMAL[bit_index]
#			else:
#				bitmask &= ~(1 << bit_index | BITS_TO_CLEAR_3X3_MINIMAL[bit_index])
#		TileSet.BITMASK_3X3: # все биты устанавливаются и снимаются индивидуально
#			if bit_value:
#				bitmask |= 1 << bit_index
#			else:
#				bitmask &= ~(1 << bit_index)
#	if bitmask != previous_bitmask:
#		var subtile_coord: Vector2 = __find_subtile_for_bitmask(__current_tile_id, bitmask)
#		if subtile_coord == -Vector2.ONE:
#			bitmask = 0
#			_transaction_parent.set_cell_data(cell, Paper.EMPTY_CELL_DATA)
#		else:
#			_transaction_parent.set_cell_data(cell, Paper.create_cell_data(__current_tile_id, false, false, false, subtile_coord))
#		var bitmask_diff: int = bitmask ^ previous_bitmask
#		for bi in 9:
#			var bit: int = 1 << bi
#			if bitmask_diff & bit:
#				# этот бит изменился
#				for neighbor_index in range(NEIGHBOR_DATA_INDICES[bi * 2], NEIGHBOR_DATA_INDICES[bi * 2] + NEIGHBOR_DATA_INDICES[bi * 2 + 1]):
#					__set_mask_bit(
#						cell + NEIGHBOR_CELL_POSITIONS[neighbor_index],
#						NEIGHBOR_CELL_BIT_INDICES[neighbor_index],
#						bitmask & bit)
#		# update()
#
#func __find_subtile_for_bitmask(tile_id: int, bitmask: int) -> Vector2:
#	if bitmask == 0:
#		return -Vector2.ONE
#	var tile_region_size: Vector2 = __tile_set.tile_get_region(tile_id).size
#	var subtile_spacing: int = __tile_set.autotile_get_spacing(tile_id)
#	var subtile_size: Vector2 = __tile_set.autotile_get_size(tile_id)
#	var subtiles_coords_with_priority: PoolVector2Array
#	var row_count: int = int(tile_region_size.y) / int(subtile_size.y + subtile_spacing)
#	var column_count: int = int(tile_region_size.x) / int(subtile_size.x + subtile_spacing)
#	for y in row_count: for x in column_count:
#		var subtile_coord: Vector2 = Vector2(x, y)
#		if bitmask == __tile_set.autotile_get_bitmask(tile_id, subtile_coord):
#			for priority in __tile_set.autotile_get_subtile_priority(tile_id, subtile_coord):
#				subtiles_coords_with_priority.append(subtile_coord)
#	return -Vector2.ONE if subtiles_coords_with_priority.empty() else \
#		subtiles_coords_with_priority[randi() % subtiles_coords_with_priority.size()]
#
#
#var radius: float = 5
#func forward_canvas_draw_over_viewport(overlay: Control, tile_map: TileMap) -> void:
#	var tile_set = tile_map.tile_set
#	var int_position: Vector2 = _position.floor()
#	var half_offset = tile_map.cell_half_offset
#	for y in range(int_position.y - radius, int_position.y + radius + 1):
#		for x in range(int_position.x - radius, int_position.x + radius + 1):
#			var cell = Vector2(x, y)
#			var transparency: Color = Color(1, 1, 1, 1 - int_position.distance_to(cell) / radius)
#			var tile_id: int = tile_map.get_cellv(cell)
#			if tile_id == TileMap.INVALID_CELL:
#				pass
#			else:
#				match tile_set.tile_get_tile_mode(tile_id):
#					TileSet.SINGLE_TILE:
#						pass
#					TileSet.AUTO_TILE:
#						var bitmask: int = tile_set.autotile_get_bitmask(tile_id, tile_map.get_cell_autotile_coord(x, y))
#						var zones_first_index = 0 if tile_set.autotile_get_bitmask_mode(tile_id) == TileSet.BITMASK_2X2 else 18
#						for b in 9:
#							if bitmask & (1 << b):
#								overlay.draw_rect(
#									Rect2(
#										ZONES[zones_first_index + b * 2] + Common.get_half_offsetted_cell_position(cell, half_offset),
#										ZONES[zones_first_index + b * 2 + 1]),
#									bitmask_color * transparency)
#					TileSet.ATLAS_TILE:
#						pass
#
##IN TILESET SCRIPT
##func _forward_atlas_subtile_selection(atlastile_id: int, tilemap: Object, tile_location: Vector2) -> Vector2:
##	return Vector2.ZERO
##func _forward_subtile_selection(autotile_id: int, bitmask: int, tilemap: Object, tile_location: Vector2) -> Vector2:
##	return Vector2.ZERO
##func _is_tile_bound(drawn_id: int, neighbor_id: int) -> bool:
##	return false
