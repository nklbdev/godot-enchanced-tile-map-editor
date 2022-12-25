extends Object

var __locked_items: Dictionary = {}

func lock_visibility(canvas_item: CanvasItem, value: bool) -> void:
	if is_instance_valid(canvas_item) and __locked_items.get(canvas_item, not value) != value:
		__locked_items[canvas_item] = value
		canvas_item.visible = value
		canvas_item.connect("visibility_changed", self, "__on_canvas_item_visibility_changed", [canvas_item, value])

func unlock_visibility(canvas_item: CanvasItem) -> void:
	if __locked_items.erase(canvas_item):
		canvas_item.disconnect("visibility_changed", self, "__on_canvas_item_visibility_changed")

func unlock_all() -> void:
	for item in __locked_items.keys():
		unlock_visibility(item)

func __on_canvas_item_visibility_changed(canvas_item: CanvasItem, value: bool) -> void:
	if not canvas_item.visible == value:
		canvas_item.visible = value
