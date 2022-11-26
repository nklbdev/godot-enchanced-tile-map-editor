extends "_base.gd"

func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Polygon Selection",
		preload("../../icons/selection_tool_polygon.svg"),
		KEY_MASK_SHIFT | KEY_Q)

