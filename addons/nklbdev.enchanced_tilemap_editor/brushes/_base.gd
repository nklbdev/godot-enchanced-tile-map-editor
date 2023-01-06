extends Object

const Common = preload("../common.gd")
const Paper = preload("../paper.gd")

enum {
	CELL_TYPE_HEX = 0,
	CELL_TYPE_TET = 1,
	CELL_TYPE_MAP = 2,
	CELL_TYPE_PAT = 3,
}

var __cell_type_option_button: OptionButton
var _adjustments: Array
func get_adjustments() -> Array: # of Control
	return _adjustments

var _settings: Common.Settings

var cell_type: int setget __set_cell_type
func __set_cell_type(value: int) -> void:
	if value == cell_type:
		return
	cell_type = value
	# Do something

func _init(settings: Common.Settings) -> void:
	__cell_type_option_button = __create_cell_type_option_button()
	_adjustments.append(__cell_type_option_button)
	_settings = settings


func process_input_event_key(event: InputEventKey) -> bool:
#	print("brush is indifferent")
	return false




func paint(cell: Vector2, paper: Paper) -> void:
	# или можно поиграться с генерацией случайных чисел - перед каждой точкой ставить соответствующий сид, состоящий из
	# порядкового номера (идентификатора?) рисовательного действия и координат
	match cell_type:
		CELL_TYPE_HEX: _paint_hex_cell(cell, paper)
		CELL_TYPE_TET: _paint_tet_cell(cell, paper)
		CELL_TYPE_MAP: _paint_map_cell(cell, paper)
		CELL_TYPE_PAT: _paint_pat_cell(cell, paper)
		_: assert(false)

const _quarter: Vector2 = Vector2.ONE / 4
const _half: Vector2 = Vector2.ONE / 2
func draw(cell: Vector2, overlay: Control, paper: Paper) -> void:
	match cell_type:
		CELL_TYPE_HEX: _draw_hex_cell(cell, overlay, paper)
		CELL_TYPE_TET: _draw_tet_cell(cell, overlay, paper)
		CELL_TYPE_MAP: _draw_map_cell(cell, overlay, paper)
		CELL_TYPE_PAT: _draw_pat_cell(cell, overlay, paper)
		_: assert(false)

func get_cell(world_position: Vector2, paper: Paper) -> Vector2:
	match cell_type:
		CELL_TYPE_HEX: return __get_hex_cell(world_position)
		CELL_TYPE_TET: return __get_tet_cell(world_position)
		CELL_TYPE_MAP: return __get_map_cell(world_position, paper.half_offset_type)
		CELL_TYPE_PAT: return _get_pat_cell(world_position, paper)
	assert(false)
	return Vector2.ZERO

func __get_hex_cell(world_position: Vector2) -> Vector2:
	return (world_position * 4).floor()

func __get_tet_cell(world_position: Vector2) -> Vector2:
	return (world_position * 2 + _quarter).floor()

func __get_map_cell(world_position: Vector2, half_offset_type: int) -> Vector2:
	return (world_position - Common.get_half_offset(world_position.floor(), half_offset_type)).floor()



func _paint_hex_cell(hex_cell: Vector2, paper: Paper) -> void:
	assert(false)

func _paint_tet_cell(tet_cell: Vector2, paper: Paper) -> void:
	assert(false)

func _paint_map_cell(map_cell: Vector2, paper: Paper) -> void:
	assert(false)

func _paint_pat_cell(pat_cell: Vector2, paper: Paper) -> void:
	assert(false)



func _get_pat_cell(world_position: Vector2, paper: Paper) -> Vector2:
	assert(false)
	return Vector2.ZERO







func _draw_hex_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	overlay.draw_rect(Rect2(cell / 4, _quarter), _settings.drawn_cells_color)

func _draw_tet_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	overlay.draw_rect(Rect2(cell / 2 - _quarter, _half), _settings.drawn_cells_color)

func _draw_map_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	overlay.draw_rect(Rect2(cell + Common.get_half_offset(cell, paper.half_offset_type), Vector2.ONE), _settings.drawn_cells_color)

func _draw_pat_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	assert(false)




func __create_cell_type_option_button() -> OptionButton:
	var ob = OptionButton.new()
	ob.flat = true
	ob.clip_text = true
	ob.add_icon_item(preload("../icons/png/cell_type_hex.png"), "Hexademic")
	ob.set_item_metadata(0, 0)
	ob.add_icon_item(preload("../icons/png/cell_type_tet.png"), "Tetrademic")
	ob.set_item_metadata(1, 1)
	ob.add_icon_item(preload("../icons/png/cell_type_map.png"), "Map")
	ob.set_item_metadata(2, 2)
	ob.add_icon_item(preload("../icons/png/cell_type_map.png"), "Pattern")
	ob.set_item_metadata(3, 3)
	ob.connect("item_selected", self, "__on_cell_type_option_button_selected")
	return ob

func __on_cell_type_option_button_selected(item_index: int) -> void:
	cell_type = __cell_type_option_button.get_item_metadata(item_index)
