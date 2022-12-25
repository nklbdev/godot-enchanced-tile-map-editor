extends Node

func clear() -> void:
	pass
#
#const Common = preload("common.gd")
#const Paper = preload("paper.gd")
#const CombineOperations = Common.SelectionCombineOperations
#
#const __selection_modulate: Color = Color(0, 0.75, 1, 0.5)
#
#var __selection: TileMap
#var __operand: TileMap
#var __operand_transaction_root: Paper.TransactionRoot
#
#func _init() -> void:
#	var tile_set = __create_tile_set()
#	__selection = __create_tile_map(tile_set)
#	add_child(__selection)
#	__operand = __create_tile_map(tile_set)
#	add_child(__operand)
#	__operand_transaction_root = Paper.TransactionRoot.new(__operand)
#	__operand_transaction_root.connect("child_transaction_open", self, "__on_operand_child_transaction_open")
#	__operand_transaction_root.connect("child_transaction_closed", self, "__on_operand_child_transaction_closed")
#
#func clear():
#	__operand_transaction_root.disconnect("child_transaction_open", self, "__on_operand_child_transaction_open")
#	__operand_transaction_root.disconnect("child_transaction_closed", self, "__on_operand_child_transaction_closed")
#	__operand.clear()
#	__selection.clear()
#	__operand_transaction_root = Paper.TransactionRoot.new(__operand)
#	__operand_transaction_root.connect("child_transaction_open", self, "__on_operand_child_transaction_open")
#	__operand_transaction_root.connect("child_transaction_closed", self, "__on_operand_child_transaction_closed")
#
#func __create_tile_map(tile_set: TileSet) -> TileMap:
#	var tile_map = TileMap.new()
#	tile_map.cell_size = Vector2.ONE
#	tile_map.modulate = __selection_modulate
#	return tile_map
#
#func __create_tile_set() -> TileSet:
#	var image = Image.new()
#	image.create(1, 1, false, Image.FORMAT_LA8)
#	image.fill(Color.white)
#
#	var texture = ImageTexture.new()
#	texture.create_from_image(image, 0)
#
#	var tile_set = TileSet.new()
#	tile_set.create_tile(0)
#	tile_set.tile_set_texture(0, texture)
#	tile_set.tile_set_region(0, Rect2(Vector2.ZERO, Vector2.ONE))
#	return tile_set
#
#func __on_operand_child_transaction_open() -> void:
#	pass
#
#var __current_operation_type: int
#func __on_operand_child_transaction_closed(success: bool) -> void:
#	if not success:
#		return
#	match __current_operation_type:
#		CombineOperations.REPLACEMENT:
#			__selection.clear()
#			for cell in __operand.get_used_cells():
#				__selection.set_cellv(cell, 0)
#		CombineOperations.UNION:
#			for cell in __operand.get_used_cells():
#				__selection.set_cellv(cell, 0)
#		CombineOperations.INTERSECTION:
#			for cell in __selection.get_used_cells():
#				if __operand.get_cellv(cell) == TileMap.INVALID_CELL:
#					__selection.set_cellv(cell, TileMap.INVALID_CELL)
#		CombineOperations.SUBTRACTION:
#			for cell in __operand.get_used_cells():
#				__selection.set_cellv(cell, TileMap.INVALID_CELL)
#	__operand.clear()
#	pass
