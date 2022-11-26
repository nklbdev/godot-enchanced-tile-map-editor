extends "../../utility_base.gd"

func perform() -> void:
	pass

func _create_button(tooltip: String, icon: Texture, scancode_with_modifiers: int = 0) -> ToolButton:
	var tool_button = Common.create_blank_button(tooltip, icon, scancode_with_modifiers)
	tool_button.connect("pressed", self, "perform")
	return tool_button
