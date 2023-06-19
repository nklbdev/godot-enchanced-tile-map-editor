extends Object

var __weak_refs: Array
var __values: Array

func push(key: Object, value) -> void:
	var is_element_replaced: bool = false
	var idx: int = __weak_refs.size() - 1
	while idx >= 0:
		var ref = __weak_refs[idx].get_ref()
		if ref == null:
			__weak_refs.pop_at(idx)
			__values.pop_at(idx)
		elif key == ref:
			__values[idx] = value
			is_element_replaced = true
		idx -= 1
	if not is_element_replaced:
		__weak_refs.push_back(weakref(key))
		__values.push_back(value)

func pop(key: Object):
	var value_to_return = null
	var idx: int = __weak_refs.size() - 1
	while idx >= 0:
		var ref = __weak_refs[idx].get_ref()
		if ref == null:
			__weak_refs.pop_at(idx)
			__values.pop_at(idx)
		elif key == ref:
			value_to_return = __values[idx]
			__weak_refs.pop_at(idx)
			__values.pop_at(idx)
		idx -= 1
	return value_to_return

func peek(key: Object):
	var value_to_return = null
	var idx: int = __weak_refs.size() - 1
	while idx >= 0:
		var ref = __weak_refs[idx].get_ref()
		if ref == null:
			__weak_refs.pop_at(idx)
			__values.pop_at(idx)
		elif key == ref:
			value_to_return = __values[idx]
		idx -= 1
	return value_to_return

func clear() -> void:
	__weak_refs.clear()
	__values.clear()
