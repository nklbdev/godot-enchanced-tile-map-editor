extends HBoxContainer

const TreeBuilder = preload("../tree_builder.gd")
const Common      = preload("../common.gd")
const Instrument  = preload("../instruments/_base.gd")

var __short_cuts: Dictionary

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

func process_input_event_key(event: InputEventKey) -> bool:
	var is_event_handled: bool = false
	if not is_event_handled:
		for short_cut in __short_cuts.keys():
			short_cut = short_cut as ShortCut
			if short_cut.is_shortcut(event):
				var button = __short_cuts[short_cut] as Button
				button.emit_signal("button_down")
				if button.toggle_mode:
					if button.group:
						var other_pressed_button: Button = button.group.get_pressed_button()
						if other_pressed_button and other_pressed_button != button:
							other_pressed_button.emit_signal("toggled", false)
							other_pressed_button.pressed = false
					button.emit_signal("toggled", true)
				button.pressed = true
				button.emit_signal("pressed")
				button.emit_signal("button_up")
				is_event_handled = true
				break
	return is_event_handled

func create_instrument_button(tooltip: String, scancode_with_modifiers: int, icon_name: String, instrument: Instrument) -> ToolButton:
	var tool_button = ToolButton.new()
	tool_button.focus_mode = Control.FOCUS_NONE
	tool_button.hint_tooltip = tooltip
	tool_button.icon = Common.get_icon(icon_name)
	tool_button.toggle_mode = true
	tool_button.group = __button_group
	tool_button.shortcut_in_tooltip = false
	if scancode_with_modifiers > 0:
		var short_cut: ShortCut = Common.create_shortcut(scancode_with_modifiers)
		__short_cuts[short_cut] = tool_button
		var shortcut_hint_position = tooltip.find("\n")
		if shortcut_hint_position < 0:
			shortcut_hint_position = tooltip.length()
		tooltip = tooltip.insert(shortcut_hint_position, " (" + short_cut.get_as_text() + ")")
	tool_button.hint_tooltip = tooltip
	tool_button.connect("toggled", self, "__on_instrument_tool_button_toggled", [tool_button, instrument])
	return tool_button
