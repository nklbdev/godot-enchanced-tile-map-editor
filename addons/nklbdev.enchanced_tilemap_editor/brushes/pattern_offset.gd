extends "_base.gd"

func _init(settings: Common.Settings).(settings) -> void:
	pass


func _paint_hex_cell(hex_cell: Vector2, paper: Paper) -> void:
	paper.pattern_offset = __get_map_cell(hex_cell / 4, paper.half_offset_type)

func _paint_tet_cell(tet_cell: Vector2, paper: Paper) -> void:
	paper.pattern_offset = __get_map_cell((tet_cell * 2 - Vector2.ONE) / 4, paper.half_offset_type)

func _paint_map_cell(map_cell: Vector2, paper: Paper) -> void:
	paper.pattern_offset = map_cell

func _paint_pat_cell(pat_cell: Vector2, paper: Paper) -> void:
	paper.pattern_offset = pat_cell


func _get_pat_cell(world_position: Vector2, paper: Paper) -> Vector2:
	return __get_map_cell(world_position, paper.half_offset_type)



func _draw_hex_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	Common.draw_axis_fragment((cell / 4).floor(), overlay, paper.half_offset_type, _settings)

func _draw_tet_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	Common.draw_axis_fragment((cell / 2 - _quarter).floor(), overlay, paper.half_offset_type, _settings)

func _draw_map_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	Common.draw_axis_fragment(cell, overlay, paper.half_offset_type, _settings)

func _draw_pat_cell(cell: Vector2, overlay: Control, paper: Paper) -> void:
	Common.draw_axis_fragment(cell, overlay, paper.half_offset_type, _settings)

