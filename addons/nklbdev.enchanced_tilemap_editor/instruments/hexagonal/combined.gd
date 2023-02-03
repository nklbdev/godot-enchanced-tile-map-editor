extends "_base.gd"

const Common = preload("../common.gd")
const Instrument = preload("_base.gd")

var __instruments_by_modifiers: Dictionary
var __default_instrument: Instrument
var __current_instrument: Instrument

func _init(default_instrument: Instrument) -> void:
	__default_instrument = default_instrument
	__current_instrument = default_instrument

func set_instrument(modifiers: int, instrument: Instrument) -> void:
	__instruments_by_modifiers[modifiers] = instrument

func _set_origin(value: Vector2) -> void:
	._set_origin(value)

func _set_position(value: Vector2) -> void:
	._set_position(value)

func push() -> void:
	.push()
	var current_modifiers: int = Common.get_current_modifiers()
	__current_instrument = __default_instrument
	for modifiers in __instruments_by_modifiers.keys():
		if current_modifiers == current_modifiers | modifiers:
			__current_instrument = __instruments_by_modifiers[modifiers]
	__current_instrument.push()

func pull(force: bool = false) -> void:
	.pull(force)
	__current_instrument.pull(force)

func move_to(position: Vector2) -> void:
	.move_to(position)
	__default_instrument.move_to(position)
	for instrument in __instruments_by_modifiers.values():
		if instrument != __default_instrument:
			instrument.move_to(position)

func process_input_event_key(event: InputEventKey) -> bool:
	if __current_instrument.process_input_event_key(event):
		return true
	if __default_instrument != __current_instrument:
		if __default_instrument.process_input_event_key(event):
			return true
	for instrument in __instruments_by_modifiers.values():
		if instrument != __current_instrument and instrument != __default_instrument:
			if instrument.process_input_event_key(event):
				return true
	return false

func paint() -> void:
	__current_instrument.paint()

func draw(overlay: Control) -> void:
	__current_instrument.draw(overlay)

func can_paint_at(map_cell: Vector2) -> bool:
	return __current_instrument.can_paint_at(map_cell)
