extends "res://addons/nklbdev.enchanced_tilemap_editor/utility_base.gd"

signal shape_layout_changed(shape_layout_flags)

var __shape_layout_flags = Common.ShapeLayoutFlag.SIMPLE
var __sleeping: bool

var disabled: bool = false setget __set_disabled
func __set_disabled(value: bool) -> void:
	if value != disabled:
		disabled = value
		if disabled:
			__sleeping = true

#func __scan() -> void:
#	var shape_layout_flags = Common.ShapeLayoutFlag.SIMPLE
#	if Input.is_key_pressed(KEY_SHIFT):
#		shape_layout_flags |= Common.ShapeLayoutFlag.REGULAR
#	if Input.is_key_pressed(KEY_CONTROL):
#		shape_layout_flags |= Common.ShapeLayoutFlag.CENTERED
#	set_shape_layout_flags(shape_layout_flags)

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
		
		match event.scancode:
			KEY_SHIFT: __shape_layout_flags = \
				(__shape_layout_flags | Common.ShapeLayoutFlag.REGULAR) \
				if event.pressed else \
				(__shape_layout_flags & Common.ShapeLayoutFlag.CENTERED)
			KEY_CONTROL: __shape_layout_flags = \
				(__shape_layout_flags | Common.ShapeLayoutFlag.CENTERED) \
				if event.pressed else \
				(__shape_layout_flags & Common.ShapeLayoutFlag.REGULAR)
				
#		elif event.scan
#			if event.pressed and event.scancode
#			# игнорировать все отпускания до первого нажатия
#			pass
#		if not disabled and event is InputEventKey and not event.echo:
#			__scan()

func get_shape_layout_flags() -> int:
	return __shape_layout_flags

func set_shape_layout_flags(shape_layout_flags: int) -> void:
	if __shape_layout_flags != shape_layout_flags:
		__shape_layout_flags = shape_layout_flags
		_consume_event()
		emit_signal("shape_layout_changed", __shape_layout_flags)
