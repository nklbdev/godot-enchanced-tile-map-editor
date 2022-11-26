extends Object

var __hanged_items: Dictionary = {}

func hang_visibility(canvas_item: CanvasItem, value: bool) -> void:
	if is_instance_valid(canvas_item) and __hanged_items.get(canvas_item, not value) != value:
		__hanged_items[canvas_item] = value
		canvas_item.visible = value
		canvas_item.connect("visibility_changed", self, "__on_canvas_item_visibility_changed", [canvas_item, value])

func release_visibility(canvas_item: CanvasItem) -> void:
	if __hanged_items.erase(canvas_item):
		canvas_item.disconnect("visibility_changed", self, "__on_canvas_item_visibility_changed")

func __on_canvas_item_visibility_changed(canvas_item: CanvasItem, value: bool) -> void:
	if not canvas_item.visible == value:
		canvas_item.visible = value
