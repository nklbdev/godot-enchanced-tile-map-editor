extends "../tool_group_base.gd"

const __tool_classes: Array = [
	preload("rectangle.gd"),
	preload("lasso.gd"),
	preload("polygon.gd"),
	preload("continous.gd"),
	preload("same.gd")
]

func _init(editor: EditorPlugin).(editor) -> void:
	name = "SelectionTools"

	var button_group = ButtonGroup.new()
	for tool_class in __tool_classes:
		_add_tool(tool_class.new(_editor, button_group))
