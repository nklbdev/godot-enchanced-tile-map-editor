extends Object
const Common = preload("common.gd")

var __subutilities: Array = []
var _editor: EditorPlugin

func _init(editor: EditorPlugin) -> void:
	_editor = editor

func forward_canvas_gui_input(event: InputEvent) -> void:
	_forward_canvas_gui_input(event)
	for subutility in __subutilities:
		subutility.forward_canvas_gui_input(event)

func _forward_canvas_gui_input(event: InputEvent) -> void:
	pass

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	_forward_canvas_draw_over_viewport(overlay)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	_forward_canvas_force_draw_over_viewport(overlay)

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	pass

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _consume_event() -> void:
	_editor.consume_event()

func _update_overlays() -> void:
	_editor.update_overlays()

func add_subutility(utility: Object) -> void:
	if utility and not (utility in __subutilities):
		__subutilities.append(utility)

func remove_subutility(utility: Object) -> void:
	__subutilities.erase(utility)
