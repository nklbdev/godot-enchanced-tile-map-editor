extends Object

const MODIFIER_KEYS: PoolIntArray = PoolIntArray([
	KEY_CONTROL, KEY_ALT, KEY_SHIFT, KEY_META
])
const ALL_MODIFIER_KEYS: int = KEY_CONTROL | KEY_ALT | KEY_SHIFT | KEY_META

signal modifier_changed(modifier)

var __all_modifiers

var modifiers: int setget __set_modifiers
func __set_modifiers(modifiers: int) -> void:
	modifiers &= ALL_MODIFIER_KEYS
	if modifiers != self.modifiers:
		var changed_modifiers = self.modifiers ^ modifiers
		self.modifiers = modifiers

func input_event_key(event: InputEventKey) -> void:
	pass
