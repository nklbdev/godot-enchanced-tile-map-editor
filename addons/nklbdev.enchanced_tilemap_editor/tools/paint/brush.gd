extends "_base.gd"
func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Brush",
		preload("../../icons/paint_tool_brush.svg"),
		KEY_B)
