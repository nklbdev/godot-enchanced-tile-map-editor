static func serialize(value):
	match typeof(value):
		TYPE_NIL: return null
		TYPE_BOOL: return value
		TYPE_INT: return value
		TYPE_REAL: return value
		TYPE_STRING: return value
		TYPE_VECTOR2: return { x = value.x, y = value.y }
		TYPE_RECT2: return { position = serialize(value.position), size = serialize(value.size) }
		TYPE_VECTOR3: return { x = value.x, y = value.y, z = value.z }
		TYPE_TRANSFORM2D: return { x = serialize(value.x), y = serialize(value.y), origin = serialize(value.origin) }
		TYPE_PLANE: return { normal = serialize(value.normal), d = serialize(value.d) }
		TYPE_QUAT: return { x = value.x, y = value.y, z = value.z, w = value.w }
		TYPE_AABB: return { position = serialize(value.position), size = serialize(value.size) }
		TYPE_BASIS: return { x = serialize(value.x), y = serialize(value.y), z = serialize(value.z) }
		TYPE_TRANSFORM: return { basis = serialize(value.basis), origin = serialize(value.origin) }
		TYPE_COLOR: return { r = value.r, g = value.g, b = value.b, a = value.a }
		TYPE_NODE_PATH: return str(value)
		TYPE_RID:
			assert(false, "Can not serialize RID")
			return 0
		TYPE_OBJECT:
			assert(false, "Can not serialize Object, use serialize_object method instead")
			return 0
		TYPE_DICTIONARY:
			var result: Dictionary = {}
			for key in value as Dictionary:
				result[key] = serialize(value.get(key))
			return result
		TYPE_ARRAY: return __serialize_array(value)
		TYPE_RAW_ARRAY: return __serialize_array(value)
		TYPE_INT_ARRAY: return __serialize_array(value)
		TYPE_REAL_ARRAY: return __serialize_array(value)
		TYPE_STRING_ARRAY: return __serialize_array(value)
		TYPE_VECTOR2_ARRAY: return __serialize_array(value)
		TYPE_VECTOR3_ARRAY: return __serialize_array(value)
		TYPE_COLOR_ARRAY: return __serialize_array(value)

static func serialize_object(object: Object, property_names: PoolStringArray) -> Dictionary:
	var result: Dictionary = {}
	for property_name in property_names:
		if property_name in object:
			result[property_name] = serialize(object.get(property_name))
	return result

static func __serialize_array(array) -> Array:
	var result: Array = []
	for item in array:
		result.push_back(serialize(item))
	return result

static func deserialize(value, type):
	match type:
		TYPE_NIL: return null
		TYPE_BOOL: return value
		TYPE_INT: return value
		TYPE_REAL: return value
		TYPE_STRING: return value
		TYPE_VECTOR2: return Vector2(value.x, value.y)
		TYPE_RECT2: return Rect2(deserialize(value.position, TYPE_VECTOR2), deserialize(value.size, TYPE_VECTOR2))
		TYPE_VECTOR3: return Vector3(value.x, value.y, value.z)
		TYPE_TRANSFORM2D: return Transform2D(deserialize(value.x, TYPE_VECTOR2), deserialize(value.y, TYPE_VECTOR2), deserialize(value.origin, TYPE_VECTOR2))
		TYPE_PLANE: return Plane(deserialize(value.normal, TYPE_VECTOR3), value.d)
		TYPE_QUAT: return Quat(value.x, value.y, value.z, value.w)
		TYPE_AABB: return AABB(deserialize(value.position, TYPE_VECTOR3), deserialize(value.size, TYPE_VECTOR3))
		TYPE_BASIS: return Basis(deserialize(value.x, TYPE_VECTOR3), deserialize(value.y, TYPE_VECTOR3), deserialize(value.z, TYPE_VECTOR3))
		TYPE_TRANSFORM: return Transform(deserialize(value.basis, TYPE_BASIS), deserialize(value.origin, TYPE_VECTOR3))
		TYPE_COLOR: return Color(value.r, value.g, value.b, value.a)
		TYPE_NODE_PATH: return NodePath(value)
		TYPE_RID:
			assert(false, "Can not deserialize RID")
			return 0
		TYPE_OBJECT:
			assert(false, "Can not deserialize Object")
			return 0
		TYPE_DICTIONARY:
			assert(false, "Can not deserialize Dictionary")
			return 0
		TYPE_ARRAY:
			assert(false, "Can not deserialize Array")
			return 0
		TYPE_RAW_ARRAY: return PoolByteArray(deserialize_array_of_type(value, TYPE_INT))
		TYPE_INT_ARRAY: return PoolIntArray(deserialize_array_of_type(value, TYPE_INT))
		TYPE_REAL_ARRAY: return PoolRealArray(deserialize_array_of_type(value, TYPE_REAL))
		TYPE_STRING_ARRAY: return PoolStringArray(deserialize_array_of_type(value, TYPE_STRING))
		TYPE_VECTOR2_ARRAY: return PoolVector2Array(deserialize_array_of_type(value, TYPE_VECTOR2))
		TYPE_VECTOR3_ARRAY: return PoolVector3Array(deserialize_array_of_type(value, TYPE_VECTOR3))
		TYPE_COLOR_ARRAY: return PoolColorArray(deserialize_array_of_type(value, TYPE_COLOR))

static func deserialize_dictionary_by_type_map(dictionary: Dictionary, type_map: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for item_key in dictionary.keys():
		var type = type_map.get(item_key)
		if type != null:
			result[item_key] = deserialize(dictionary[item_key], type)
	return result

static func deserialize_array_of_type(array: Array, type: int) -> Array:
	var result: Array = []
	for item in array:
		result.push_back(deserialize(item, type))
	return result
