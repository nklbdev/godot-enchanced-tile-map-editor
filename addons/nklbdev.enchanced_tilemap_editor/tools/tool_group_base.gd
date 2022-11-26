extends HBoxContainer
const ToolBase = preload("_base.gd")

var _editor: EditorPlugin
var _tools: Array

func _init(editor: EditorPlugin) -> void:
	_editor = editor

func forward_canvas_gui_input(event: InputEvent) -> void:
	for _tool in _tools:
		_tool.forward_canvas_gui_input(event)

func _add_tool(_tool: ToolBase) -> void:
	_tools.append(_tool)
	add_child(_tool.control)
