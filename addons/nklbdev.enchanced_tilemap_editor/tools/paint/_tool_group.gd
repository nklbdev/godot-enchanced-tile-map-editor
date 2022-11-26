extends "../tool_group_base.gd"

const __tool_classes: Array = [
	preload("brush.gd"),
	preload("line.gd"),
	preload("contour.gd"),
	preload("polygon.gd"),
	preload("rectangle.gd"),
	preload("bucket.gd"),
	preload("eraser.gd")
]

func _init(editor: EditorPlugin).(editor) -> void:
	name = "PaintTools"

	var button_group: ButtonGroup = ButtonGroup.new()
	for tool_class in __tool_classes:
		_add_tool(tool_class.new(editor, button_group))
