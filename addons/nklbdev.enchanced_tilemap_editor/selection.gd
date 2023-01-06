extends "paper.gd"

const Common = preload("common.gd")

const COMBINE_OPERATIONS_DESCRIPTIONS: PoolStringArray = PoolStringArray([
	"Replacement", "Union", "Intersection", "Subtraction"])

var __tile_map_to_select: TileMap
var __selection_map: TileMap
var __selection_operand_map: TileMap
var __settings: Common.Settings
var __image: Image
var __texture: ImageTexture
var __combine_operation_option_button: OptionButton

func get_selection_map() -> TileMap:
	return __selection_map

func get_selection_operand_map() -> TileMap:
	return __selection_operand_map

func _init(settings: Common.Settings) -> void:
	__settings = settings
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
	_adjustments.append(__combine_operation_option_button)
	
	__apply_settings()
	__reset_modifiers()

func __reset_modifiers() -> void:
	__set_auto_operation_type(Common.SelectionCombineOperations.REPLACEMENT)

func __create_combine_operation_option_button() -> OptionButton:
	var button: OptionButton = OptionButton.new()
	var texture: Texture = preload("res://addons/nklbdev.enchanced_tilemap_editor/icons/paint_tool_contour.svg")
	button.add_icon_item(texture, "Auto", 1000)
	for id in COMBINE_OPERATIONS_DESCRIPTIONS.size():
		button.add_icon_item(texture, COMBINE_OPERATIONS_DESCRIPTIONS[id], id)
	return button

func process_input_event_key(event: InputEventKey) -> bool:
	if _is_input_freezed:
		return false
	if event.scancode & Common.ALL_MODIFIER_KEYS > 0:
		__rescan_modifiers()
		return true
	return false

func __rescan_modifiers() -> void:
	var modifiers = Common.get_current_modifiers()
	if modifiers | KEY_SHIFT | KEY_ALT == modifiers:
		__set_auto_operation_type(Common.SelectionCombineOperations.SUBTRACTION)
	elif modifiers | KEY_SHIFT | KEY_CONTROL == modifiers:
		__set_auto_operation_type(Common.SelectionCombineOperations.INTERSECTION)
	elif modifiers | KEY_SHIFT == modifiers:
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
#	if __auto_operation_type == value:
#		return
	__auto_operation_type = value
	__combine_operation_option_button.set_item_icon(0, __combine_operation_option_button.get_item_icon(value + 1))
	__combine_operation_option_button.set_item_text(0, "Auto: %s" % [__combine_operation_option_button.get_item_text(value + 1)])
#	void set_item_tooltip(idx: int, tooltip: String)

func commit_changes() -> void:
	.commit_changes()
	var operation_type = __combine_operation_option_button.get_selected_id()
#	print(operation_type)
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
#	print("commit and rescan")
#	__rescan_modifiers()

#func reset_changes() -> void:
#	.reset_changes()
#	print("reset and rescan")
#	__rescan_modifiers()

func freeze_input() -> void:
	__rescan_modifiers()
	.freeze_input()
func resume_input() -> void:
	.resume_input()
	__rescan_modifiers()
