extends "paper.gd"

const Patterns = preload("patterns.gd")

const COMBINE_OPERATIONS_DESCRIPTIONS: PoolStringArray = PoolStringArray([
	"Replacement", "Union", "Intersection", "Subtraction"])

var __tile_map_to_select: TileMap
var __selection_map: TileMap
var __selection_operand_map: TileMap
var __settings: Common.Settings
var __image: Image
var __texture: ImageTexture
var __combine_operation_option_button: OptionButton

signal pattern_copied(pattern)

func get_selection_map() -> TileMap:
	return __selection_map

func get_selection_operand_map() -> TileMap:
	return __selection_operand_map

func _init() -> void:
	__settings = Common.get_static(Common.Statics.SETTINGS)
	__settings.connect("settings_changed", self, "__apply_settings")

	__image = Image.new()
	__image.create(2, 2, false, Image.FORMAT_RGBA8)
	__image.fill(__settings.selection_color)

	__texture = ImageTexture.new()
	__texture.create(2, 2, Image.FORMAT_RGBA8, 0)
	
	__selection_map = TileMap.new()
	__selection_map.cell_size = Vector2.ONE * 2
	__selection_map.scale = Vector2.ONE / 2

	__selection_map.tile_set = TileSet.new()
	__selection_map.tile_set.create_tile(0)
	__selection_map.tile_set.tile_set_texture(0, __texture)
	__selection_map.tile_set.tile_set_region(0, Rect2(Vector2.ZERO, Vector2.ONE * 2))
	__selection_operand_map = __selection_map.duplicate(0)
	
	__combine_operation_option_button = __create_combine_operation_option_button()
	
	__apply_settings()
	__reset_modifiers()

func __reset_modifiers() -> void:
	__set_auto_operation_type(Common.SelectionCombineOperations.REPLACEMENT)

func __create_combine_operation_option_button() -> OptionButton:
	var button: OptionButton = OptionButton.new()
	var texture: Texture = Common.get_icon("paint_tool_contour")
	button.add_icon_item(texture, "Auto", 1000)
	for id in COMBINE_OPERATIONS_DESCRIPTIONS.size():
		button.add_icon_item(texture, COMBINE_OPERATIONS_DESCRIPTIONS[id], id)
	return button

func process_input_event_key(event: InputEventKey) -> bool:
	if _is_input_freezed:
		return false
	if (event.control or event.command) and not event.alt:
#		pass
		if event.scancode == KEY_C or event.scancode == KEY_X:
			var cut: bool = event.scancode == KEY_X
			var used_rect: Rect2 = __selection_map.get_used_rect()
			if used_rect.has_no_area():
				return false

			# hack
			var __pattern_layout_map = __selection_map
			
			var data: PoolIntArray
			var pattern: Patterns.Pattern = Patterns.Pattern.new()
			var pattern_position: Vector2 = __pattern_layout_map.map_to_world(used_rect.position)
			var pattern_cells: Dictionary
			var origin: Vector2 = Vector2.INF
			var end: Vector2 = -Vector2.INF
			for cell in __selection_map.get_used_cells():
				var cell_position = __pattern_layout_map.map_to_world(cell)
				var pattern_cell = __pattern_layout_map.world_to_map(cell_position - pattern_position)
				origin.x = min(origin.x, pattern_cell.x)
				origin.y = min(origin.y, pattern_cell.y)
				end.x = max(end.x, pattern_cell.x)
				end.y = max(end.y, pattern_cell.y)
				pattern_cells[pattern_cell] = Common.get_map_cell_data(__tile_map_to_select, cell)
			pattern.size = end - origin + Vector2.ONE
			for cell in pattern_cells.keys():
				pattern.cells[cell - origin] = pattern_cells[cell]
			var serialized_pattern: String = Patterns.serialize(pattern)
			OS.clipboard = serialized_pattern
			pattern = Patterns.deserialize(serialized_pattern)

			emit_signal("pattern_copied", pattern)
			return true
		elif event.scancode == KEY_V:
			pass
	elif event.scancode == KEY_DELETE and not(event.control or event.alt or event.shift or event.meta):
		var used_rect: Rect2 = __selection_map.get_used_rect()
		if used_rect.has_no_area():
			return false
		var cell: Vector2
		for y in used_rect.size.y: for x in used_rect.size.x:
			cell = used_rect.position + Vector2(x, y)
			if __selection_map.get_cellv(cell) >= 0:
				__tile_map_to_select.set_cellv(cell, TileMap.INVALID_CELL)
		__selection_map.clear()
		return true
	elif event.scancode & Common.ALL_MODIFIER_KEYS > 0:
		__rescan_modifiers()
	return false

func __rescan_modifiers() -> void:
	var modifiers = Common.get_current_modifiers()
	if modifiers == modifiers | KEY_SHIFT | KEY_ALT:
		__set_auto_operation_type(Common.SelectionCombineOperations.SUBTRACTION)
	elif modifiers == modifiers | KEY_SHIFT | KEY_CONTROL:
		__set_auto_operation_type(Common.SelectionCombineOperations.INTERSECTION)
	elif modifiers == modifiers | KEY_SHIFT:
		__set_auto_operation_type(Common.SelectionCombineOperations.UNION)
	else:
		__set_auto_operation_type(Common.SelectionCombineOperations.REPLACEMENT)
	
func set_up(tile_map: TileMap) -> void:
	assert(__tile_map_to_select == null)
	__tile_map_to_select = tile_map
	__tile_map_to_select.connect("settings_changed", self, "__apply_tile_map_to_select_settings")
	__apply_tile_map_to_select_settings()
	.set_up(__selection_operand_map)


func tear_down() -> void:
	if __tile_map_to_select:
		__tile_map_to_select.disconnect("settings_changed", self, "__apply_tile_map_to_select_settings")
	__tile_map_to_select = null
	__selection_map.clear()
	__selection_operand_map.clear()
	.tear_down()

func __apply_settings() -> void:
	__image.fill(__settings.selection_color)
	__texture.set_data(__image)

func __apply_tile_map_to_select_settings() -> void:
	__selection_map.cell_half_offset = __tile_map_to_select.cell_half_offset
	__selection_operand_map.cell_half_offset = __tile_map_to_select.cell_half_offset

var __auto_operation_type: int setget __set_auto_operation_type
func __set_auto_operation_type(value: int) -> void:
	if value < 0 or value > 4:
		return
	__auto_operation_type = value
	__combine_operation_option_button.set_item_icon(0, __combine_operation_option_button.get_item_icon(value + 1))
	__combine_operation_option_button.set_item_text(0, "Auto: %s" % [__combine_operation_option_button.get_item_text(value + 1)])

func commit_changes() -> void:
	.commit_changes()
	var operation_type = __combine_operation_option_button.get_selected_id()
	if operation_type == 1000:
		operation_type = __auto_operation_type
	match operation_type:
		Common.SelectionCombineOperations.REPLACEMENT:
			__selection_map.clear()
			for cell in __selection_operand_map.get_used_cells():
				__selection_map.set_cellv(cell, 0)
		Common.SelectionCombineOperations.UNION:
			for cell in __selection_operand_map.get_used_cells():
				__selection_map.set_cellv(cell, 0)
		Common.SelectionCombineOperations.INTERSECTION:
			for cell in __selection_map.get_used_cells():
				if __selection_operand_map.get_cellv(cell) == TileMap.INVALID_CELL:
					__selection_map.set_cellv(cell, TileMap.INVALID_CELL)
		Common.SelectionCombineOperations.SUBTRACTION:
			for cell in __selection_operand_map.get_used_cells():
				__selection_map.set_cellv(cell, TileMap.INVALID_CELL)
	__selection_operand_map.clear()

func freeze_input() -> void:
	__rescan_modifiers()
	.freeze_input()
func resume_input() -> void:
	.resume_input()
	__rescan_modifiers()
