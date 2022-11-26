extends HBoxContainer

const SelectionToolGroup = preload("tools/selection/_tool_group.gd")
const PaintToolGroup = preload("tools/paint/_tool_group.gd")

var __tool_groups: Array

func _init(editor: EditorPlugin) -> void:
	__tool_groups = [
		SelectionToolGroup.new(editor),
		PaintToolGroup.new(editor)
	]
	for tool_group in __tool_groups:
		add_child(tool_group)
	pass

func forward_canvas_gui_input(event: InputEvent) -> void:
	for tool_group in __tool_groups:
		tool_group.forward_canvas_gui_input(event)
