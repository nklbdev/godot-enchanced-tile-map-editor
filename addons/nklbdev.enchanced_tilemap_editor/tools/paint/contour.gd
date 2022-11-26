extends "_base.gd"

func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Continous Selection",
		preload("../../icons/paint_tool_contour.svg"),
		KEY_D)
