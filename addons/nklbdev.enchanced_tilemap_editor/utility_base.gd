extends Object
const Common = preload("res://addons/nklbdev.enchanced_tilemap_editor/common.gd")

var __subutilities: Array = []
var __result_flags: int

func forward_canvas_gui_input(event: InputEvent) -> int:
	__result_flags = __result_flags & Common.EventResultFlag.UPDATE_OVERLAYS
	_forward_canvas_gui_input(event)
	for subutility in __subutilities:
		__result_flags |= subutility.forward_canvas_gui_input(event)
	return __result_flags

func _forward_canvas_gui_input(event: InputEvent) -> void:
	pass

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	__result_flags &= Common.EventResultFlag.EVENT_CONSUMED
	_forward_canvas_draw_over_viewport(overlay)

func forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	__result_flags &= Common.EventResultFlag.EVENT_CONSUMED
	_forward_canvas_force_draw_over_viewport(overlay)

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	pass

func _forward_canvas_force_draw_over_viewport(overlay: Control) -> void:
	pass

func _consume_event() -> void:
	__result_flags |= Common.EventResultFlag.EVENT_CONSUMED

func _update_overlays() -> void:
	__result_flags |= Common.EventResultFlag.UPDATE_OVERLAYS

func add_subutility(utility: Object) -> void:
	if utility and not (utility in __subutilities):
		__subutilities.append(utility)

func remove_subutility(utility: Object) -> void:
	__subutilities.erase(utility)
