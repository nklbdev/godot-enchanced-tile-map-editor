extends "utility_base.gd"

signal shape_layout_changed(shape_layout_flags)

var ShapeLayouts = Common.ShapeLayouts
var __shape_layout_flags = ShapeLayouts.SIMPLE
var __sleeping: bool

func _init(editor: EditorPlugin).(editor) -> void: pass

#var disabled: bool = false setget __set_disabled
#func __set_disabled(value: bool) -> void:
#	if value != disabled:
#		disabled = value
#		if disabled:
#			set_shape_layout_flags(ShapeLayouts.SIMPLE)
#			__sleeping = true

func clear() -> void:
	set_shape_layout_flags(ShapeLayouts.SIMPLE)
	__sleeping = true

func _forward_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if __sleeping:
			if event.pressed:
				if event.echo:
					return
				if event.scancode == KEY_SHIFT or event.scancode == KEY_CONTROL:
					__sleeping = false
			else:
				return
		
		var previous_shape_layout_flags = __shape_layout_flags
		match event.scancode:
			KEY_SHIFT: set_shape_layout_flags(
				(__shape_layout_flags | ShapeLayouts.REGULAR) \
				if event.pressed else \
				(__shape_layout_flags & ShapeLayouts.CENTERED))
			KEY_CONTROL: set_shape_layout_flags(
				(__shape_layout_flags | ShapeLayouts.CENTERED) \
				if event.pressed else \
				(__shape_layout_flags & ShapeLayouts.REGULAR))
				
func get_shape_layout_flags() -> int:
	return __shape_layout_flags

func set_shape_layout_flags(shape_layout_flags: int) -> void:
	if __shape_layout_flags != shape_layout_flags:
		__shape_layout_flags = shape_layout_flags
		_consume_event()
		emit_signal("shape_layout_changed", __shape_layout_flags)
