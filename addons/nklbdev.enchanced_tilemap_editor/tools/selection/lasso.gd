extends "_base.gd"

func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Lasso Selection",
		preload("../../icons/selection_tool_lasso.svg"),
		KEY_Q)
