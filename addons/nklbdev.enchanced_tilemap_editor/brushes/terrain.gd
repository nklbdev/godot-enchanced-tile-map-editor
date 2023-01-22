#extends "_base.gd"
#
#func _init().() -> void: pass
#
#
#
#
#func _paint_hex_cell(hex_cell: Vector2, paper: Paper) -> void:
#	assert(false)
#
#func _paint_tet_cell(tet_cell: Vector2, paper: Paper) -> void:
#	assert(false)
#
#func _paint_map_cell(map_cell: Vector2, paper: Paper) -> void:
#	assert(false)
#
#func _paint_pat_cell(pat_cell: Vector2, paper: Paper) -> void:
#	assert(false)
#
#
#
#func _get_pat_cell(world_position: Vector2, paper: Paper) -> Vector2:
#	assert(false)
#	return Vector2.ZERO


#func paint(paper: Paper, cell: Vector2) -> void:
#	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
#	# порядкового номера (идентификатора?) рисовательного действия и координат
#	pass


#extends "../_base.gd"
#
#const Instrument = preload("../_base.gd")

#var tile_map: TileMap setget __set_tile_map
#var __tile_set: TileSet
#
#func __set_tile_map(value: TileMap) -> void:
#	print("__set_tile_map: %s" % value)
#	if tile_map == value:
#		return
#	tile_map = value
#	if tile_map:
#		print("__read_tileset")
#		__read_tileset(tile_map.tile_set)
#		__current_terrain_index = -1
#		for key in __terrains_by_name.keys():
#			var terrain = __terrains_by_name.get(__terrains_by_name[key], __terrains[0])
#			if not terrain.name.empty():
#				print(terrain.name)
#				__current_terrain_index = terrain.index
#
#	else:
#		__clear()
#
#func _on_start() -> void:
#	__tile_set = _transaction_parent.get_tile_set()
##	__read_tileset(__tile_set)
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
#	__clear()
#	__tile_set = null
#
#func _on_mode_changed() -> void:
#	pass
#
#func _on_pushed() -> void:
#	if is_active():
#		__paint()
#
#func _on_pulled() -> void:
#	pass
#
#func _on_moved(previous_position: Vector2) -> void:
#	if is_active() and _is_pushed and _position.floor() != previous_position.floor():
#		__paint()
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
#
#
#const square: Rect2 = Rect2(Vector2.ZERO, Vector2.ONE)
#const bitmask_dismatch_color: Color = Color.red * Color(1, 1, 1, 0.5)
#const bitmask_match_color: Color = Color.blue * Color(1, 1, 1, 0.5)
#const grid_color: Color = Color.coral * Color(1, 1, 1, 0.5)
#var __current_terrain_index = 1
##var __dragging_button: int
#
#static func int2bin(val: int) -> String:
#	var result = "0000000000000000"
#	for i in 16:
#		result[15 - i] = "1" if val & 1 << i else "0"
#	return result
#
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
#enum {
#	TL = TileSet.BIND_TOPLEFT,
#	TC = TileSet.BIND_TOP,
#	TR = TileSet.BIND_TOPRIGHT,
#	CL = TileSet.BIND_LEFT,
#	CC = TileSet.BIND_CENTER,
#	CR = TileSet.BIND_RIGHT,
#	BL = TileSet.BIND_BOTTOMLEFT,
#	BC = TileSet.BIND_BOTTOM,
#	BR = TileSet.BIND_BOTTOMRIGHT,
#	CORNERS = BR|BL|TR|TL,
#	SIDES = BC|CR|CC|CL|TC
#}
#
#enum {
#	MAPPING_TERRAIN_0 = 0,
#	MAPPING_TERRAIN_1 = 1,
#	MAPPING_TERRAIN_TRANSITION = 2,
#}
#
#const MAPPING_2X2: Dictionary = {
##   2X2 bitmask  0 - ter0, 1 - ter1, 2 - trans
#			  0: PoolByteArray([0,0,0,  0,0,0,  0,0,0]),
#			 TL: PoolByteArray([1,2,0,  2,2,0,  0,0,0]),
#		  TR   : PoolByteArray([0,2,1,  0,2,2,  0,0,0]),
#		  TR|TL: PoolByteArray([1,1,1,  2,2,2,  0,0,0]),
#	   BL      : PoolByteArray([0,0,0,  2,2,0,  1,2,0]),
#	   BL|   TL: PoolByteArray([1,2,0,  1,2,0,  1,2,0]),
#	   BL|TR   : PoolByteArray([0,2,1,  2,2,2,  1,2,0]),
#	   BL|TR|TL: PoolByteArray([1,1,1,  1,2,2,  1,2,0]),
#	BR         : PoolByteArray([0,0,0,  0,2,2,  0,2,1]),
#	BR|      TL: PoolByteArray([1,2,0,  2,2,2,  0,2,1]),
#	BR|   TR   : PoolByteArray([0,2,1,  0,2,1,  0,2,1]),
#	BR|   TR|TL: PoolByteArray([1,1,1,  2,2,1,  0,2,1]),
#	BR|BL      : PoolByteArray([0,0,0,  2,2,2,  1,1,1]),
#	BR|BL|   TL: PoolByteArray([1,2,0,  1,2,2,  1,1,1]),
#	BR|BL|TR   : PoolByteArray([0,2,1,  2,2,1,  1,1,1]),
#	BR|BL|TR|TL: PoolByteArray([1,1,1,  1,1,1,  1,1,1]),
#}
#
#const MASK_BIT_3X3_INDEX_BY_HEXLET_INDEX: PoolByteArray = PoolByteArray([
#	IND_TOPLEFT,    IND_TOP,    IND_TOP,    IND_TOPRIGHT,
#	IND_LEFT,       IND_CENTER, IND_CENTER, IND_RIGHT,
#	IND_LEFT,       IND_CENTER, IND_CENTER, IND_RIGHT,
#	IND_BOTTOMLEFT, IND_BOTTOM, IND_BOTTOM, IND_BOTTOMRIGHT
#])
#
#const DIRECTIONS: PoolVector2Array = PoolVector2Array([
#
#	Vector2( 0, -1), # TOP           2  1
#	Vector2(-1,  0), # LEFT          8  3
#	Vector2( 1,  0), # RIGHT        32  5
#	Vector2( 0,  1), # BOTTOM      128  7
#
#	Vector2(-1, -1), # TOPLEFT       1  0
#	Vector2( 1, -1), # TOPRIGHT      4  2
#	Vector2(-1,  1), # BOTTOMLEFT   64  6
#	Vector2( 1,  1), # BOTTOMRIGHT 256  8
#])
#
#
#
#const NEIGHBOR_DATA_INDICES: PoolIntArray = PoolIntArray([
#	# start, count
#	1,  3, # TOP           2          10  1
#	5,  3, # LEFT          8        1000  3
#	8,  3, # RIGHT        32      100000  5
#	12, 3, # BOTTOM      128    10000000  7
#
#	0,  1, # TOPLEFT       1           1  0
#	4,  1, # TOPRIGHT      4         100  2
#	11, 1, # BOTTOMLEFT   64     1000000  6
#	15, 1, # BOTTOMRIGHT 256   100000000  8
#])
#
#const NEIGHBOR_CELL_BIT_INDICES: PoolIntArray = PoolIntArray([
#	# index in our cell       index in neighbor cell
#	# DIRECTION TOPLEFT       1
#	IND_TOPLEFT,     IND_BOTTOMRIGHT,  # 0, 1     0
#	# DIRECTION TOP           2
#	IND_TOPLEFT,     IND_BOTTOMLEFT,   # 2, 3     1
#	IND_TOP,         IND_BOTTOM,       # 4, 5     2
#	IND_TOPRIGHT,    IND_BOTTOMRIGHT,  # 6, 7     3
#	# DIRECTION TOPRIGHT      4
#	IND_TOPRIGHT,    IND_BOTTOMLEFT,   # 8, 9     4
#	# DIRECTION LEFT          8
#	IND_TOPLEFT,     IND_TOPRIGHT,     # 10, 11   5
#	IND_LEFT,        IND_RIGHT,        # 12, 13   6
#	IND_BOTTOMLEFT,  IND_BOTTOMRIGHT,  # 14, 15   7
#	# DIRECTION CENTER       16
#	# DIRECTION RIGHT        32
#	IND_TOPRIGHT,    IND_TOPLEFT,      # 16, 17   8
#	IND_RIGHT,       IND_LEFT,         # 18, 19   9
#	IND_BOTTOMRIGHT, IND_BOTTOMLEFT,   # 20, 21   10
#	# DIRECTION BOTTOMLEFT   64
#	IND_BOTTOMLEFT,  IND_TOPRIGHT,     # 22, 23   11
#	# DIRECTION BOTTOM      128
#	IND_BOTTOMLEFT,  IND_TOPLEFT,      # 24, 25   12
#	IND_BOTTOM,      IND_TOP,          # 26, 27   13
#	IND_BOTTOMRIGHT, IND_TOPRIGHT,     # 28, 29   14
#	# DIRECTION BOTTOMRIGHT 256
#	IND_BOTTOMRIGHT, IND_TOPLEFT,      # 30, 31   15
#])
#
#const TERRAIN_EMPTY = TileMap.INVALID_CELL # explicit emptiness
#
#class TerrainBase:
#	var class_hint: String
#	var index: int # in __terrains
#	var subtiles: Array # of SubtileInfo
#	var neighbor_terrain_indices: PoolByteArray # key: Terrain, value: Array<SubtileInfo> ?????
#	func _init(ind: int, clh: String) -> void:
#		index = ind
#		class_hint = clh
#
#class Terrain:
#	extends TerrainBase
#	var name: String # in __terrains_by_name
#	var icon_subtile: SubtileInfo
#	func _to_string() -> String:
#		return "Terrain \"%s\"" % [name]
#	func _init(index: int, nm: String).(index, "Terrain") -> void:
#		name = nm
#	func add_neighbor_terrain_index(neighbor_terrain_index: int) -> void:
##		print("add_neighbor_terrain_index %s to %s" % [neighbor_terrain_index, index])
#		if not neighbor_terrain_indices.has(neighbor_terrain_index):
#			neighbor_terrain_indices.append(neighbor_terrain_index)
#
#class TerrainTransition:
#	extends TerrainBase
#	func _init(index: int, ter0_index: int, ter1_index: int).(index, "TerrainTransition") -> void:
#		neighbor_terrain_indices = create_key(ter0_index, ter1_index)
#
#	static func create_key(terrain_a_index: int, terrain_b_index: int) -> PoolByteArray:
#		var key: PoolByteArray
#		key.resize(2)
#		key.set(0, terrain_a_index)
#		key.set(1, terrain_b_index)
#		key.sort()
#		return key
#
#class SubtileInfo:
#	var tile_id: int
#	var subtile_coord: Vector2
#	var priority: int
#	var bitmask_mode: int # -1 for single tiles
#	var terrainmask: PoolByteArray
#	func _to_string() -> String:
#		return "Sub %s %s %s" % [tile_id, subtile_coord, terrainmask]
#
#var __terrains: Array # of TerrainBase
#var __terrains_by_name: Dictionary # Only Terrain's. It is for user. User cannot draw terrain transitions directly
#var __subtiles_by_address: Dictionary # Vector3(x, y, tile_id) - SubtileInfo
#var __terrain_distance: Dictionary # of PoolByteArray[terrain_with_lower_index, terrain_with_higher_index] and int distance
#var __terrain_transitions: Dictionary # of PoolByteArray[terrain_with_lower_index, terrain_with_higher_index] and TerrainTransition
#var __default_subtile_info: SubtileInfo
#
##func _unhandled_input(event: InputEvent) -> void:
##	if event is InputEventMouseMotion:
##		if __dragging_button:
##			__paint()
##	elif event is InputEventMouseButton:
##		if event.button_index == BUTTON_LEFT or event.button_index == BUTTON_RIGHT:
##			if event.pressed:
##				if event.button_index != __dragging_button:
##					__dragging_button = event.button_index
##					__paint()
##			elif event.button_index == __dragging_button:
##				__dragging_button = 0
##	elif event is InputEventKey:
##		if event.pressed:
##			match event.scancode:
##				KEY_1: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[0]].index
##				KEY_2: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[1]].index
##				KEY_3: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[2]].index
##				KEY_4: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[3]].index
##				KEY_5: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[4]].index
##				KEY_6: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[5]].index
##				KEY_7: __current_terrain_index = __terrains_by_name[__terrains_by_name.keys()[6]].index
#
#func __paint() -> void:
#	var hexlet: Vector2 = ((_position - _position.floor()) * 4).floor()
#	var mask_bit_index: int = MASK_BIT_3X3_INDEX_BY_HEXLET_INDEX[hexlet.y * 4 + hexlet.x]
#	__set_terrain(_position.floor(), __current_terrain_index, mask_bit_index)
#
##func __paint() -> void:
##	var terrain: Terrain = __terrains[__current_terrain_index]
##	var zero: Vector2 = tm.map_to_world(Vector2.ZERO)
##	# hack to skip half-offsetted row or column
##	var right: Vector2 = (tm.map_to_world(Vector2.RIGHT * 2) - zero) / 2
##	var down: Vector2 = (tm.map_to_world(Vector2.DOWN * 2)  - zero) / 2
##
##	var cell_base_transform: Transform2D = Transform2D(right, down, Vector2.ZERO)
##	var cell_base_transform_aff_inv: Transform2D = cell_base_transform.affine_inverse()
##
##	var world_mouse_position: Vector2 = tm.get_local_mouse_position()
##	var mouse_cell: Vector2 = tm.world_to_map(world_mouse_position)
##	var world_mouse_cell_position: Vector2 = tm.map_to_world(mouse_cell)
##	var world_mouse_position_in_cell: Vector2 = world_mouse_position - world_mouse_cell_position
##	var id_mouse_position_in_cell: Vector2 = cell_base_transform_aff_inv * world_mouse_position_in_cell
##	var hexlet = (id_mouse_position_in_cell * 4).floor()
##	var mask_bit_index = MASK_BIT_3X3_INDEX_BY_HEXLET_INDEX[hexlet.y * 4 + hexlet.x]
##	__set_terrain(tm, mouse_cell, terrain.index, mask_bit_index)
#
#
#func __set_one_cell(cell: Vector2, terrainmask: PoolByteArray, fixed_sections: int, visited_cells: Array, affected_cells: Array, fixed_cells: Array) -> bool:
##	print("__set_one_cell %s %s %s" % [cell, terrainmask, int2bin(fixed_sections)])
#	# изменение ячейки. Вынести в отдельную функцию
#	var priority: int
#	var nearest_subtile_infos = __get_hamming_nearest_subtiles(terrainmask, fixed_sections)
##	print("set_one_cell tmask:%s fixed:%s found:%s" % [terrainmask, int2bin(fixed_sections), ("\n" + "\n".join(nearest_subtile_infos)).indent("    ")])
#	for nearest_subtile_info in nearest_subtile_infos:
#		priority += nearest_subtile_info.priority
#	if priority > 0:
#		priority = randi() % priority
#		for nearest_subtile_info in nearest_subtile_infos:
#			priority -= nearest_subtile_info.priority
#			if priority <= 0:
#				_transaction_parent.set_cell_data(cell, Paper.create_cell_data(nearest_subtile_info.tile_id, false, false, false, nearest_subtile_info.subtile_coord))
#				for direction in DIRECTIONS:
#					var neighbor_cell = cell + direction
#					if not neighbor_cell in visited_cells and \
#					   not neighbor_cell in affected_cells and \
#					   not neighbor_cell in fixed_cells:
#						affected_cells.append(neighbor_cell)
#				return true # success
#	# suitable tile not found
#	return false
#
#
#func __set_terrain(cell: Vector2, terrain_index: int, mask_section_index: int) -> void:
#	print("set terrain %s, %s, %s" % [cell, __terrain_index_to_string(terrain_index), int2bin(mask_section_index)])
#	var visited_cells: Array
#	var fixed_cells: Array
#	var affected_cells: Array
#	var cell_data = _transaction_parent.get_cell_data(cell)
#	var subtile_info: SubtileInfo = __get_subtile_info(cell_data[0], Vector2.ZERO if  cell_data[0] == TileMap.INVALID_CELL else Vector2(cell_data[2], cell_data[3])) as SubtileInfo
#	var new_terrainmask: PoolByteArray = subtile_info.terrainmask
#	new_terrainmask.set(mask_section_index, terrain_index)
#	if new_terrainmask == subtile_info.terrainmask:
#		return
#
#	if not __set_one_cell(cell, new_terrainmask, 1 << mask_section_index, visited_cells, affected_cells, fixed_cells):
#		return
#
#	visited_cells.append(cell)
##	affected_cells.clear()
##	affected_cells = next_affected_cells
##	next_affected_cells = Array()
#	var limit = 1024
#	while true:
#		if limit < 0:
#			push_warning("Endless growth of autotiling due to incomplete bitmasks of terrains")
#			return
#		limit -= 1
#		# next_affected_cells должен быть пустым
#		# affected_cells должен содержать ячейки для обработки (или пусто, если алгоритм заканчивает работу)
#		# visited_cells должен накапливать все обработанные ячейки
##		var is_something_changed = false
#
#		# в этом цикле обрабатываемые "затронутые ячейки" переходят в "исправленные ячейки".
#		# если в ячейку не получается поставить тайл, то
#		# - Находящиеся рядом "исправленные ячейки" перевести обратно в "затронутые" (возможно, даже с восстановлением оригинального контента)
#		# - Попробовать поставить тут тайл снова.
#		# - Если не получится и на этот раз, то пометить ячейку как "сломанную" -
#		#     это особый террэйн, который имеет до любого другого террэйна расстояние 0. Дадим ему id == -2
#		#     и запомним до конца работы алгоритма, чтобы потом их все заменить на -1, ибо не должно оставаться на карте -2.
#		# 
#		while not affected_cells.empty():
#			var affected_cell = affected_cells.pop_front()
#			# вычислить изменения битмаски по соседним visited-ячейкам
#			var affected_cell_data = _transaction_parent.get_cell_data(affected_cell)
#			var affected_subtile_info: SubtileInfo = __get_subtile_info(affected_cell_data[0], Vector2.ZERO if  affected_cell_data[0] == TileMap.INVALID_CELL else Vector2(affected_cell_data[2], affected_cell_data[3])) as SubtileInfo
#			var affected_terrainmask: PoolByteArray = affected_subtile_info.terrainmask
#			var fixed_sections: int = 0
#			for direction_index in DIRECTIONS.size():
#				var direction = DIRECTIONS[direction_index]
#				var neighbor_cell = affected_cell + direction
#				if neighbor_cell in visited_cells:
#					# значит, эта ячейка оказывает влияние на нашу ячейку
#					var neighbor_cell_data = _transaction_parent.get_cell_data(neighbor_cell)
#					var neighbor_subtile_info: SubtileInfo = __get_subtile_info(neighbor_cell_data[0], Vector2.ZERO if  neighbor_cell_data[0] == TileMap.INVALID_CELL else Vector2(neighbor_cell_data[2], neighbor_cell_data[3])) as SubtileInfo
#					var first_index = NEIGHBOR_DATA_INDICES[direction_index * 2]
#					var count = NEIGHBOR_DATA_INDICES[direction_index * 2 + 1]
##					print("DIRECTION %s %s, %s %s" % [direction_index, direction, first_index, count])
#					for i in range(first_index * 2, (first_index + count) * 2, 2):
#						var section_index_in_affected_cell = NEIGHBOR_CELL_BIT_INDICES[i]
#						var section_index_in_neighbor_cell = NEIGHBOR_CELL_BIT_INDICES[i + 1]
##						print("%s %s section_index_in_affected_cell: %s section_index_in_neighbor_cell: %s" % [i, i + 1, section_index_in_affected_cell, section_index_in_neighbor_cell])
#						affected_terrainmask.set(section_index_in_affected_cell, neighbor_subtile_info.terrainmask[section_index_in_neighbor_cell])
#						fixed_sections |= 1 << section_index_in_affected_cell
#						# каждая такая секция в visited-ячейке влияет на такую секцию в нашей ячейке, и должна быть заменена и закреплена.
#			if affected_terrainmask == affected_subtile_info.terrainmask:
#				visited_cells.push_back(affected_cell)
#			else:
##				var d = __get_terrainmask_hamming_distance(affected_terrainmask, affected_subtile_info.terrainmask, ~fixed_sections)
##				print("asdfasdfasdf %s %s %s = %s" % [affected_terrainmask, affected_subtile_info.terrainmask, int2bin(~fixed_sections), d])
#				if __get_terrainmask_hamming_distance(affected_subtile_info.terrainmask, affected_terrainmask, ~fixed_sections) < 0:
#					# если ключевые местности этой ячейки недостижимы
#					# то будем считать эту ячейку обработанной
##					print("asdfasdfasdf %s %s %s" % [affected_subtile_info.terrainmask, affected_terrainmask, int2bin(~fixed_sections)])
#					visited_cells.append(affected_cell)
#					pass
#				else:
#					if __set_one_cell(affected_cell, affected_terrainmask, fixed_sections, visited_cells, affected_cells, fixed_cells):
#						visited_cells.append(affected_cell)
#						for direction in DIRECTIONS:
#							var neighbor_cell = affected_cell + direction
#							if not neighbor_cell in visited_cells and \
#							   not neighbor_cell in affected_cells and \
#							   not neighbor_cell in fixed_cells:
#								fixed_cells.append(neighbor_cell)
#					else:
#						# попробовать поставить ячейку игнорируя 
#						visited_cells.push_back(affected_cell)
#		if fixed_cells.empty():
#			return
#		else:
#			affected_cells.append_array(fixed_cells)
#			fixed_cells.clear()
#
#func __terrain_index_to_string(terrain_index) -> String:
#	var terrain_base = __terrains[terrain_index]
#	if terrain_base is Terrain:
#		return str(terrain_base)
#	elif terrain_base is TerrainTransition:
#		return "Transition(%s, %s)" % [
#			__terrain_index_to_string(terrain_base.neighbor_terrain_indices[0]),
#			__terrain_index_to_string(terrain_base.neighbor_terrain_indices[1])]
#	else:
#		return ""
#
#func __clear() -> void:
#	__terrains.clear()
#	__terrains_by_name.clear()
#	__subtiles_by_address.clear()
#	__terrain_distance.clear()
#	__terrain_transitions.clear()
#
#func __read_tileset(tile_set: TileSet) -> void:
#	__clear()
#	__register_terrain("") # emptiness
#	__default_subtile_info = SubtileInfo.new()
#	__default_subtile_info.tile_id = TileMap.INVALID_CELL
#	__default_subtile_info.subtile_coord = Vector2.ZERO
#	__default_subtile_info.priority = 1
#	__default_subtile_info.bitmask_mode = TileSet.BITMASK_2X2
#	__default_subtile_info.terrainmask = PoolByteArray([0,0,0,  0,0,0,  0,0,0])
#	__subtiles_by_address[Vector3(0, 0, -1)] = __default_subtile_info
#	for tile_id in tile_set.get_tiles_ids():
#		# create terrains
#		var tile_mode = tile_set.tile_get_tile_mode(tile_id)
#		var terrain_names: PoolStringArray = __parse_terrain_names(tile_set.tile_get_name(tile_id))
#
#		if tile_mode == TileSet.AUTO_TILE and terrain_names.size() == 2:
#			# на первом месте все-таки должно стоять имя террэйна с маской 0, так как
#			# для синглов и атласов оно тоже на 1 месте, а там маска всегда равна нулю
#			__create_subtiles(tile_set, tile_id,
#				__register_terrain(terrain_names[0]), # can be -1
#				__register_terrain(terrain_names[1])) # can be -1
#		elif tile_mode != TileSet.AUTO_TILE and terrain_names.size() == 1:
#			__create_subtiles(tile_set, tile_id,
#				__register_terrain(terrain_names[0])) # can not be -1
#		else:
#			# такой тайл нас не интересует
#			pass
#	for terrain_a_index in __terrains.size(): for terrain_b_index in range(terrain_a_index, __terrains.size()):
#		__terrain_distance[PoolByteArray([terrain_a_index, terrain_b_index])] = \
#			__get_terrain_hamming_distance(terrain_a_index, terrain_b_index)
#
#
## для использования в инициализации после заполнения TerrainBase.neighbor_terrains
#func __get_terrain_hamming_distance(terrain_a_index: int, terrain_b_index: int) -> int:
##	print("__get_terrain_hamming_distance %s %s" % [__terrain_index_to_string(terrain_a_index), __terrain_index_to_string(terrain_b_index)])
#	var visited_terrain_indices: PoolByteArray
#	var current_terrain_indices: PoolByteArray
#	current_terrain_indices.append(terrain_a_index)
#	var distance: int
#	while true:
#		if current_terrain_indices.empty():
#			break
#		for terrain_index in current_terrain_indices:
#			if terrain_index == terrain_b_index:
##				print("result %s" % distance)
#				return distance
#		visited_terrain_indices.append_array(current_terrain_indices)
#		var next_terrain_indices: PoolByteArray
#		for terrain_index in current_terrain_indices:
#			for neighbor_terrain_index in __terrains[terrain_index].neighbor_terrain_indices:
#				if not visited_terrain_indices.has(neighbor_terrain_index):
#					next_terrain_indices.append(neighbor_terrain_index)
#		current_terrain_indices = next_terrain_indices
#		distance += 1
##	print("result -1")
#	return -1
#
#
## для использования во время редактирования для подбора плиток
## Я мог бы вычислить расстояние Хэмминга между каждой парой тайлов, но нам придется искать расстояния по маске и не для известного тайла.
## То есть запрос будет выглядеть примерно так:
#func __get_hamming_nearest_subtiles(terrainmask: PoolByteArray, fixed_sections: int) -> Array: # of SubtileInfo
#	var min_distance: int = -1
#	var nearest_subtiles: Array
#	for subtile_info in __subtiles_by_address.values():
#		var distance = __get_terrainmask_hamming_distance(terrainmask, subtile_info.terrainmask, fixed_sections)
#		if distance < 0:
#			continue
#		if min_distance < 0 or distance <= min_distance:
#			if min_distance != distance:
#				min_distance = distance
#				nearest_subtiles.clear()
#			nearest_subtiles.append(subtile_info)
#	return nearest_subtiles
#
## Для использования во время редактирования для подбора плиток в методе __get_hamming_nearest_subtiles
## Есть предположение увеличивать цену изменения граничных узлов -
## бокового, например, на 1, а углового - на 2 или 3, так как их изменение ведет к замене соседнего тайла
## А так же возможно увеличивать цену изменения с расстоянием от ближайшего фиксированного узла
#func __get_terrainmask_hamming_distance(terrainmask_a: PoolByteArray, terrainmask_b: PoolByteArray, fixed_sections: int) -> int:
#	var distance = 0
#	var key: PoolByteArray
#	key.resize(2)
#	for i in 9:
#		if terrainmask_a[i] == terrainmask_b[i]:
#			continue
#		# если в фиксированной секции есть различие, то вернуть -1
#		if fixed_sections & 1 << i:
#			return -1
#		key.set(0, terrainmask_a[i])
#		key.set(1, terrainmask_b[i])
#		key.sort()
#		var distance_in_section = __terrain_distance.get(key, -1)
#		# если в данной секции расстояние недостижимо, вернуть -1
#		if distance_in_section < 0:
#			return -1
#		distance += distance_in_section
#	return distance
#
## субтайл определяется идентификатором тайла и координатами субтайла. По этому Vector3 подойдет для ключа
## мне нужно быстро искать субтайл по маске. маска - это 9 террэйнов, среди которых может быть и пустой
#
#func __get_subtile_info(tile_id: int, subtile_coord: Vector2) -> SubtileInfo:
#	return __subtiles_by_address.get(Vector3(subtile_coord.x, subtile_coord.y, tile_id), __default_subtile_info)
#
#func __normalize_name(name: String) -> String:
#	name = name.strip_edges().strip_escapes()
##	while "  " in name:
##		name = name.replace("  ", " ")
#	while true:
#		var double_space_position = name.find("  ")
#		if double_space_position > 0:
#			name.erase(double_space_position, 1)
#		else:
#			break
#	return name
#
#func __parse_terrain_names(tile_name: String) -> PoolStringArray:
#	var terrain_names: PoolStringArray = tile_name.split("&")
#	var names_count = terrain_names.size()
#	if not names_count in range(1, 2 + 1):
#		return PoolStringArray()
#	for name_index in names_count:
#		terrain_names[name_index] = __normalize_name(terrain_names[name_index])
#	return \
#		PoolStringArray() \
#		if names_count == 1 and terrain_names[0].empty() or \
#		names_count == 2 and terrain_names[0] == terrain_names[1] else \
#		terrain_names
#
#func __register_terrain(terrain_name: String) -> int:
#	print("__register_terrain %s" % terrain_name)
#	var terrain = __terrains_by_name.get(terrain_name)
#	if terrain == null:
#		terrain = Terrain.new(__terrains.size(), terrain_name)
#		__terrains.append(terrain)
#		__terrains_by_name[terrain_name] = terrain
#	return terrain.index
#
#func __register_terrain_transition(terrain_a_index: int, terrain_b_index: int) -> int:
#	var key = TerrainTransition.create_key(terrain_a_index, terrain_b_index)
#	var transition = __terrain_transitions.get(key) as TerrainTransition
#	if transition == null:
#		transition = TerrainTransition.new(__terrains.size(), key[0], key[1])
#		__terrains.append(transition)
#		__terrain_transitions[key] = transition
#	return transition.index
#
#
#
#func __create_subtiles(tile_set: TileSet, tile_id: int, terrain0_index: int, terrain1_index: int = -1) -> void:
#	var tile_region_size: Vector2 = tile_set.tile_get_region(tile_id).size
#	var tile_mode: int = tile_set.tile_get_tile_mode(tile_id)
#	# method returns always 0 for single tiles
#	var subtile_spacing: int = tile_set.autotile_get_spacing(tile_id)
#	# method returns always 64X64 for single tiles
#	var subtile_size: Vector2 = tile_region_size if tile_mode == TileSet.SINGLE_TILE else tile_set.autotile_get_size(tile_id)
#	# method returns bitmasks only for auto-tiles (else - 0 i.e. 2X2)
#	var bitmask_mode: int = tile_set.autotile_get_bitmask_mode(tile_id) if tile_mode == TileSet.AUTO_TILE else -1
#	var row_count: int = int(ceil(tile_region_size.y / (subtile_size.y + subtile_spacing)))
#	var column_count: int = int(ceil(tile_region_size.x / (subtile_size.x + subtile_spacing)))
##	print("__create_subtiles: column_count: %s, row_count %s" % [column_count, row_count])
#	for y in row_count: for x in column_count:
#		var subtile_coord: Vector2 = Vector2(x, y)
#		var subtile_info: SubtileInfo = SubtileInfo.new()
#		subtile_info.tile_id = tile_id
#		subtile_info.subtile_coord = subtile_coord
#		subtile_info.priority = 1 if tile_mode == TileSet.SINGLE_TILE else tile_set.autotile_get_subtile_priority(tile_id, subtile_coord)
#		subtile_info.bitmask_mode = bitmask_mode
#		var terrainmask: PoolByteArray
#		terrainmask.resize(9)
#		if tile_mode == TileSet.AUTO_TILE:
#			var bitmask = tile_set.autotile_get_bitmask(tile_id, subtile_coord)
#			if bitmask == 0:
#				continue
#			if bitmask_mode == TileSet.BITMASK_2X2:
#				var mapping: PoolByteArray = MAPPING_2X2[bitmask & CORNERS]
#				var transition_index = __register_terrain_transition(terrain0_index, terrain1_index)
#				__terrains[terrain0_index].add_neighbor_terrain_index(transition_index)
#				__terrains[terrain1_index].add_neighbor_terrain_index(transition_index)
#				for mask_section_index in 9:
#					match mapping[mask_section_index]:
#						MAPPING_TERRAIN_0: terrainmask.set(mask_section_index, terrain0_index)
#						MAPPING_TERRAIN_1: terrainmask.set(mask_section_index, terrain1_index)
#						MAPPING_TERRAIN_TRANSITION: terrainmask.set(mask_section_index, transition_index)
#			else:
#				__terrains[terrain0_index].add_neighbor_terrain_index(terrain1_index)
#				__terrains[terrain1_index].add_neighbor_terrain_index(terrain0_index)
#				for mask_section_index in 9:
#					terrainmask.set(
#						mask_section_index,
#						terrain1_index if bitmask & 1 << mask_section_index else terrain0_index)
#			subtile_info.terrainmask = terrainmask
#			if terrain1_index in terrainmask:
#				__terrains[terrain1_index].subtiles.append(subtile_info)
#	#		print("Created subtile: %s %s" % [subtile_info, int2bin(bitmask)])
#		else:
#			terrainmask.fill(terrain0_index)
#			subtile_info.terrainmask = terrainmask
#		if terrain0_index in terrainmask:
#			__terrains[terrain0_index].subtiles.append(subtile_info)
#		__subtiles_by_address[Vector3(x, y, tile_id)] = subtile_info
#
#
#var radius: float = 5
##func _draw():
#func forward_canvas_draw_over_viewport(overlay: Control, tile_map: TileMap) -> void:
#	var tile_set: TileSet = tile_map.tile_set
#	var int_position: Vector2 = _position.floor()
#	var half_offset: int = tile_map.cell_half_offset
#	var color = bitmask_dismatch_color
#	for y in range(int_position.y - radius, int_position.y + radius + 1):
#		for x in range(int_position.x - radius, int_position.x + radius + 1):
#			var cell = Vector2(x, y)
#			var tile_id = tile_map.get_cellv(int_position)
#			var subtile_info: SubtileInfo = __get_subtile_info(tile_id, tile_map.get_cell_autotile_coord(x, y))
#			var terrainmask: PoolByteArray = subtile_info.terrainmask
#			var cell_offset: Vector2 = Common.get_half_offsetted_cell_position(cell, half_offset)
#			color.a = bitmask_dismatch_color.a * (1 - int_position.distance_to(cell) / radius)
#			if tile_id != TileMap.INVALID_CELL:
#				match tile_map.tile_set.tile_get_tile_mode(tile_id):
#					TileSet.AUTO_TILE:
#						var autotile_coord = tile_map.get_cell_autotile_coord(int_position.x, int_position.y)
#						var bitmask: int = tile_map.tile_set.autotile_get_bitmask(tile_id, autotile_coord)
#						var zones_first_index = 0 if tile_map.tile_set.autotile_get_bitmask_mode(tile_id) == TileSet.BITMASK_2X2 else 18
#						for b in 9:
#							if terrainmask[b] != __current_terrain_index:
#								overlay.draw_rect(
#									Rect2(
#										ZONES[zones_first_index + b * 2] + cell_offset,
#										ZONES[zones_first_index + b * 2 + 1]),
#									color)
#					_:
#						if terrainmask[0] != __current_terrain_index:
#							overlay.draw_rect(Rect2(cell_offset, Vector2.ONE), color)
#			else:
#				if terrainmask[0] != __current_terrain_index:
#					overlay.draw_rect(Rect2(cell_offset, Vector2.ONE), color)

