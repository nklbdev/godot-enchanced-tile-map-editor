extends HBoxContainer

const TreeBuilder = preload("../tree_builder.gd")
const Common      = preload("../common.gd")
const Instrument  = preload("../instruments/_base.gd")

var __button_group: ButtonGroup = ButtonGroup.new()
signal instrument_changed
var __instrument: Instrument
func get_instrument() -> Instrument:
	return __instrument
func __on_instrument_tool_button_toggled(pressed: bool, tool_button: ToolButton, instrument: Instrument) -> void:
	if pressed:
		if instrument != __instrument:
			__instrument = instrument
			emit_signal("instrument_changed")

func create_instrument_button(tooltip: String, scancode_with_modifiers: int, icon_name: String, instrument: Instrument) -> ToolButton:
	var tool_button = ToolButton.new()
	tool_button.focus_mode = Control.FOCUS_NONE
	tool_button.hint_tooltip = tooltip
	tool_button.icon = Common.get_icon(icon_name)
	tool_button.toggle_mode = true
	tool_button.group = __button_group
	tool_button.shortcut_in_tooltip = true
	tool_button.shortcut = Common.create_shortcut(scancode_with_modifiers)
	tool_button.connect("toggled", self, "__on_instrument_tool_button_toggled", [tool_button, instrument])
	return tool_button
