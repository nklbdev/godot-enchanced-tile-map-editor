extends "_base.gd"

func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Bucket",
		preload("../../icons/paint_tool_bucket.svg"),
		KEY_G)
