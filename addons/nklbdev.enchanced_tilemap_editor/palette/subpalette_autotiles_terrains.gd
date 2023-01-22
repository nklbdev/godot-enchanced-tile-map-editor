extends "_list_subpalette.gd"

const Paper = preload("../paper.gd")

func _init(terrains_paper: Paper).("Terrains", "terrain_autotiling") -> void: pass

func _after_set_up() -> void:
	var tile_set = _tile_map.tile_set
	__read_tileset(tile_set)
	for terrain_name in __terrains_by_name.keys():
		var terrain: Terrain = __terrains_by_name[terrain_name] as Terrain
		var icon: Texture
		var terrain_caption: String
		if terrain.icon_subtile:
			var icon_subtile_tile_id = terrain.icon_subtile.tile_id
			var tile_texture = tile_set.tile_get_texture(icon_subtile_tile_id)
			var tile_region = tile_set.tile_get_region(icon_subtile_tile_id)
			var tile_mode = tile_set.tile_get_tile_mode(icon_subtile_tile_id)
			var subtile_size = tile_region.size \
				if tile_mode == TileSet.SINGLE_TILE else \
				tile_set.autotile_get_size(icon_subtile_tile_id)
			var subtile_spacing = tile_set.autotile_get_spacing(icon_subtile_tile_id)
			icon = AtlasTexture.new()
			icon.atlas = tile_texture
			icon.region = \
				Rect2(tile_region.position + (subtile_size + Vector2.ONE * subtile_spacing) * terrain.icon_subtile.subtile_coord, subtile_size)
			icon.flags = tile_texture.flags
			terrain_caption = terrain.name
		else:
			var transparent_image = Image.new()
			transparent_image.create(1, 1, false, Image.FORMAT_LA8)
			transparent_image.fill(Color.transparent)
			icon = ImageTexture.new()
			icon.create_from_image(transparent_image)
			terrain_caption = "[NONE]"
		_add_item(terrain_caption, icon, terrain)

func _before_tear_down() -> void:
	__terrains.clear()
	__terrains_by_name.clear()
	__subtiles_by_address.clear()
	__terrain_distance.clear()
	__terrain_transitions.clear()





















###########################################
#        IMPLEMENTATION                   #
###########################################

enum {
	MAPPING_TERRAIN_0 = 0,
	MAPPING_TERRAIN_1 = 1,
	MAPPING_TERRAIN_TRANSITION = 2,
}

enum {
	TL = TileSet.BIND_TOPLEFT,
	TC = TileSet.BIND_TOP,
	TR = TileSet.BIND_TOPRIGHT,
	CL = TileSet.BIND_LEFT,
	CC = TileSet.BIND_CENTER,
	CR = TileSet.BIND_RIGHT,
	BL = TileSet.BIND_BOTTOMLEFT,
	BC = TileSet.BIND_BOTTOM,
	BR = TileSet.BIND_BOTTOMRIGHT,
	CORNERS = BR|BL|TR|TL,
	SIDES = BC|CR|CC|CL|TC,
}

const MAPPING_2X2: Dictionary = {
#   2X2 bitmask  0 - terrain_0, 1 - terrain_1, 2 - terrain_transition
			  0: PoolByteArray([0,0,0,  0,0,0,  0,0,0]),
			 TL: PoolByteArray([1,2,0,  2,2,0,  0,0,0]),
		  TR   : PoolByteArray([0,2,1,  0,2,2,  0,0,0]),
		  TR|TL: PoolByteArray([1,1,1,  2,2,2,  0,0,0]),
	   BL      : PoolByteArray([0,0,0,  2,2,0,  1,2,0]),
	   BL|   TL: PoolByteArray([1,2,0,  1,2,0,  1,2,0]),
	   BL|TR   : PoolByteArray([0,2,1,  2,2,2,  1,2,0]),
	   BL|TR|TL: PoolByteArray([1,1,1,  1,2,2,  1,2,0]),
	BR         : PoolByteArray([0,0,0,  0,2,2,  0,2,1]),
	BR|      TL: PoolByteArray([1,2,0,  2,2,2,  0,2,1]),
	BR|   TR   : PoolByteArray([0,2,1,  0,2,1,  0,2,1]),
	BR|   TR|TL: PoolByteArray([1,1,1,  2,2,1,  0,2,1]),
	BR|BL      : PoolByteArray([0,0,0,  2,2,2,  1,1,1]),
	BR|BL|   TL: PoolByteArray([1,2,0,  1,2,2,  1,1,1]),
	BR|BL|TR   : PoolByteArray([0,2,1,  2,2,1,  1,1,1]),
	BR|BL|TR|TL: PoolByteArray([1,1,1,  1,1,1,  1,1,1]),
}

const TERRAIN_EMPTY = TileMap.INVALID_CELL # explicit emptiness

class TerrainBase:
	var index: int # in __terrains
	var subtiles: Array # of SubtileInfo
	var neighbor_terrain_indices: PoolByteArray # key: Terrain, value: Array<SubtileInfo> ?????
	func _init(ind: int) -> void:
		index = ind
	func add_subtile(subtile: SubtileInfo) -> void:
		subtiles.append(subtile)

class Terrain:
	extends TerrainBase
	var name: String # in __terrains_by_name
	var icon_subtile: SubtileInfo
	func _to_string() -> String:
		return "Terrain \"%s\"" % [name]
	func _init(index: int, nm: String).(index) -> void:
		name = nm
	func add_neighbor_terrain_index(neighbor_terrain_index: int) -> void:
#		print("add_neighbor_terrain_index %s to %s" % [neighbor_terrain_index, index])
		if not neighbor_terrain_indices.has(neighbor_terrain_index):
			neighbor_terrain_indices.append(neighbor_terrain_index)
	func add_subtile(subtile: SubtileInfo) -> void:
		.add_subtile(subtile)
		if index == 0:
			return
		
		var new_terrainmask_match = subtile.terrainmask.count(index)
		if not icon_subtile:
			print("a terrain \"%s\" set icon subtile: %s with match: %s" % [name, subtile, new_terrainmask_match])
			icon_subtile = subtile
			return
		var icon_terrainmask_match = icon_subtile.terrainmask.count(index)
		print("b terrain \"%s\" icon_terrainmask_match: %s, new_terrainmask_match: %s" % [name, icon_terrainmask_match, new_terrainmask_match])
		if new_terrainmask_match > icon_terrainmask_match:
			print("b terrain \"%s\" set icon subtile: %s with match: %s" % [name, subtile, new_terrainmask_match])
			icon_subtile = subtile
			return
		if new_terrainmask_match == icon_terrainmask_match and \
			subtile.priority > icon_subtile.priority:
			print("c terrain \"%s\" set icon subtile: %s with match: %s" % [name, subtile, new_terrainmask_match])
			icon_subtile = subtile


class TerrainTransition:
	extends TerrainBase
	func _init(index: int, ter0_index: int, ter1_index: int).(index) -> void:
		neighbor_terrain_indices = create_key(ter0_index, ter1_index)

	static func create_key(terrain_a_index: int, terrain_b_index: int) -> PoolByteArray:
		var key: PoolByteArray
		key.resize(2)
		key.set(0, terrain_a_index)
		key.set(1, terrain_b_index)
		key.sort()
		return key

class SubtileInfo:
	var tile_id: int
	var subtile_coord: Vector2
	var priority: int
	var bitmask_mode: int # -1 for single tiles
	var terrainmask: PoolByteArray
	func _to_string() -> String:
		return "Sub %s %s %s" % [tile_id, subtile_coord, terrainmask]

var __terrains: Array # of TerrainBase
var __terrains_by_name: Dictionary # Only Terrain's. It is for user. User cannot draw terrain transitions directly
var __subtiles_by_address: Dictionary # Vector3(x, y, tile_id) - SubtileInfo
var __terrain_distance: Dictionary # of PoolByteArray[terrain_with_lower_index, terrain_with_higher_index] and int distance
var __terrain_transitions: Dictionary # of PoolByteArray[terrain_with_lower_index, terrain_with_higher_index] and TerrainTransition
var __default_subtile_info: SubtileInfo

func __read_tileset(tile_set: TileSet) -> void:
	__register_terrain("") # emptiness
	__default_subtile_info = SubtileInfo.new()
	__default_subtile_info.tile_id = TileMap.INVALID_CELL
	__default_subtile_info.subtile_coord = Vector2.ZERO
	__default_subtile_info.priority = 1
	__default_subtile_info.bitmask_mode = TileSet.BITMASK_2X2
	__default_subtile_info.terrainmask = PoolByteArray([0,0,0,  0,0,0,  0,0,0])
	__subtiles_by_address[Vector3(0, 0, -1)] = __default_subtile_info
	for tile_id in tile_set.get_tiles_ids():
		# create terrains
		var tile_mode = tile_set.tile_get_tile_mode(tile_id)
		var terrain_names: PoolStringArray = __parse_terrain_names(tile_set.tile_get_name(tile_id))

		if tile_mode == TileSet.AUTO_TILE and terrain_names.size() == 2:
			# на первом месте все-таки должно стоять имя террэйна с маской 0, так как
			# для синглов и атласов оно тоже на 1 месте, а там маска всегда равна нулю
			__create_subtiles(tile_set, tile_id,
				__register_terrain(terrain_names[0]), # can be -1
				__register_terrain(terrain_names[1])) # can be -1
		elif tile_mode != TileSet.AUTO_TILE and terrain_names.size() == 1:
			__create_subtiles(tile_set, tile_id,
				__register_terrain(terrain_names[0])) # can not be -1
		else:
			# not interesting tile
			pass
	for terrain_a_index in __terrains.size(): for terrain_b_index in range(terrain_a_index, __terrains.size()):
		__terrain_distance[PoolByteArray([terrain_a_index, terrain_b_index])] = \
			__get_terrain_hamming_distance(terrain_a_index, terrain_b_index)
	

# For use in initialization after filling TerrainBase.neighbor_terrains
func __get_terrain_hamming_distance(terrain_a_index: int, terrain_b_index: int) -> int:
	var visited_terrain_indices: PoolByteArray
	var current_terrain_indices: PoolByteArray
	current_terrain_indices.append(terrain_a_index)
	var distance: int
	while true:
		if current_terrain_indices.empty():
			break
		for terrain_index in current_terrain_indices:
			if terrain_index == terrain_b_index:
				return distance
		visited_terrain_indices.append_array(current_terrain_indices)
		var next_terrain_indices: PoolByteArray
		for terrain_index in current_terrain_indices:
			for neighbor_terrain_index in __terrains[terrain_index].neighbor_terrain_indices:
				if not visited_terrain_indices.has(neighbor_terrain_index):
					next_terrain_indices.append(neighbor_terrain_index)
		current_terrain_indices = next_terrain_indices
		distance += 1
	return -1

func __get_subtile_info(tile_id: int, subtile_coord: Vector2) -> SubtileInfo:
	return __subtiles_by_address.get(Vector3(subtile_coord.x, subtile_coord.y, tile_id), __default_subtile_info)

func __normalize_name(name: String) -> String:
	name = name.strip_edges().strip_escapes()
	while "  " in name:
		name = name.replace("  ", " ")
	return name

func __parse_terrain_names(tile_name: String) -> PoolStringArray:
	var terrain_names: PoolStringArray = tile_name.split("&")
	var names_count = terrain_names.size()
	if not names_count in range(1, 2 + 1):
		return PoolStringArray()
	for name_index in names_count:
		terrain_names[name_index] = __normalize_name(terrain_names[name_index])
	return \
		PoolStringArray() \
		if names_count == 1 and terrain_names[0].empty() or \
		names_count == 2 and terrain_names[0] == terrain_names[1] else \
		terrain_names

func __register_terrain(terrain_name: String) -> int:
	print("__register_terrain %s" % terrain_name)
	var terrain = __terrains_by_name.get(terrain_name)
	if terrain == null:
		terrain = Terrain.new(__terrains.size(), terrain_name)
		__terrains.append(terrain)
		__terrains_by_name[terrain_name] = terrain
	return terrain.index

func __register_terrain_transition(terrain_a_index: int, terrain_b_index: int) -> int:
	var key = TerrainTransition.create_key(terrain_a_index, terrain_b_index)
	var transition = __terrain_transitions.get(key) as TerrainTransition
	if transition == null:
		transition = TerrainTransition.new(__terrains.size(), key[0], key[1])
		__terrains.append(transition)
		__terrain_transitions[key] = transition
	return transition.index



func __create_subtiles(tile_set: TileSet, tile_id: int, terrain0_index: int, terrain1_index: int = -1) -> void:
	var tile_region_size: Vector2 = tile_set.tile_get_region(tile_id).size
	var tile_mode: int = tile_set.tile_get_tile_mode(tile_id)
	# method returns always 0 for single tiles
	var subtile_spacing: int = tile_set.autotile_get_spacing(tile_id)
	# method returns always 64X64 for single tiles
	var subtile_size: Vector2 = tile_region_size if tile_mode == TileSet.SINGLE_TILE else tile_set.autotile_get_size(tile_id)
	# method returns bitmasks only for auto-tiles (else - 0 i.e. 2X2)
	var bitmask_mode: int = tile_set.autotile_get_bitmask_mode(tile_id) if tile_mode == TileSet.AUTO_TILE else -1
	var row_count: int = int(ceil(tile_region_size.y / (subtile_size.y + subtile_spacing)))
	var column_count: int = int(ceil(tile_region_size.x / (subtile_size.x + subtile_spacing)))
	for y in row_count: for x in column_count:
		var subtile_coord: Vector2 = Vector2(x, y)
		var subtile_info: SubtileInfo = SubtileInfo.new()
		subtile_info.tile_id = tile_id
		subtile_info.subtile_coord = subtile_coord
		subtile_info.priority = 1 if tile_mode == TileSet.SINGLE_TILE else tile_set.autotile_get_subtile_priority(tile_id, subtile_coord)
		subtile_info.bitmask_mode = bitmask_mode
		var terrainmask: PoolByteArray
		terrainmask.resize(9)
		if tile_mode == TileSet.AUTO_TILE:
			var bitmask = tile_set.autotile_get_bitmask(tile_id, subtile_coord)
			if bitmask == 0:
				continue
			if bitmask_mode == TileSet.BITMASK_2X2:
				var mapping: PoolByteArray = MAPPING_2X2[bitmask & CORNERS]
				var transition_index = __register_terrain_transition(terrain0_index, terrain1_index)
				__terrains[terrain0_index].add_neighbor_terrain_index(transition_index)
				__terrains[terrain1_index].add_neighbor_terrain_index(transition_index)
				for mask_section_index in 9:
					match mapping[mask_section_index]:
						MAPPING_TERRAIN_0: terrainmask.set(mask_section_index, terrain0_index)
						MAPPING_TERRAIN_1: terrainmask.set(mask_section_index, terrain1_index)
						MAPPING_TERRAIN_TRANSITION: terrainmask.set(mask_section_index, transition_index)
			else:
				__terrains[terrain0_index].add_neighbor_terrain_index(terrain1_index)
				__terrains[terrain1_index].add_neighbor_terrain_index(terrain0_index)
				for mask_section_index in 9:
					terrainmask.set(
						mask_section_index,
						terrain1_index if bitmask & 1 << mask_section_index else terrain0_index)
			subtile_info.terrainmask = terrainmask
			if terrain1_index in terrainmask:
				__terrains[terrain1_index].add_subtile(subtile_info)
		else:
			terrainmask.fill(terrain0_index)
			subtile_info.terrainmask = terrainmask
		if terrain0_index in terrainmask:
			__terrains[terrain0_index].add_subtile(subtile_info)
		__subtiles_by_address[Vector3(x, y, tile_id)] = subtile_info
