extends HBoxContainer

const __tool_group_classes: Array = [
	preload("tools/selection/_tool_group.gd"),
	preload("tools/paint/_tool_group.gd")
]

var __tool_groups: Array

func _init(editor: EditorPlugin) -> void:
	name = "EnchancedTileMapEditorToolBar"
	var first: bool = true
	for tool_group_class in __tool_group_classes:
		if first: first = false
		else: add_child(VSeparator.new())
		var tool_group = tool_group_class.new(editor)
		__tool_groups.append(tool_group)
		add_child(tool_group)

func forward_canvas_gui_input(event: InputEvent) -> void:
	for tool_group in __tool_groups:
		tool_group.forward_canvas_gui_input(event)
