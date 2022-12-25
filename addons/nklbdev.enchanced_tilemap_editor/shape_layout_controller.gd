#extends Object
#
#const Common = preload("common.gd")
#const ShapeLayouts = Common.ShapeLayouts
#
#const __button_action_map: Dictionary = {
#	KEY_SHIFT: ShapeLayouts.REGULAR,
#	KEY_CONTROL: ShapeLayouts.CENTERED
#}
#
#var __shape_layout_flags = ShapeLayouts.SIMPLE
#
#signal shape_layout_changed(shape_layout_flags)
#
#func clear() -> void:
#	if __shape_layout_flags != ShapeLayouts.SIMPLE:
#		__shape_layout_flags == ShapeLayouts.SIMPLE
#		emit_signal("shape_layout_changed", __shape_layout_flags)
#
#func forward_canvas_gui_input(event: InputEvent) -> bool:
#	if event is InputEventKey and not event.echo:
#		var previous_shape_layout_flags = __shape_layout_flags
#		var arg = __button_action_map.get(event.scancode, ShapeLayouts.SIMPLE)
#		if event.pressed: __shape_layout_flags |= arg
#		else: __shape_layout_flags &= ~arg
#		if __shape_layout_flags != previous_shape_layout_flags:
#			emit_signal("shape_layout_changed", __shape_layout_flags)
#			return true
#	return false
#
#func get_shape_layout_flags() -> int:
#	return __shape_layout_flags
