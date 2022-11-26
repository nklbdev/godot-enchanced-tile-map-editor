extends "_base.gd"

func _init(editor: EditorPlugin, button_group: ButtonGroup).(editor) -> void:
	control = _create_button(
		button_group,
		"Continous Selection",
		editor.get_editor_interface().get_base_control().get_icon("ToolSelect", "EditorIcons"),
		KEY_W)
