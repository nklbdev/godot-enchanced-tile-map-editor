extends "_subpalette.gd"

func _init(title: String, icon_name: String).(title, icon_name) -> void:
	var tb = TreeBuilder.tree(self)
	tb.node(self).with_children([
		tb.node(_item_list) \
			.with_props({
				anchor_right = 1, anchor_bottom = 1,
				size_flags_vertical = Control.SIZE_EXPAND_FILL,
				select_mode = ItemList.SELECT_SINGLE,
				max_columns = 0,
				same_column_width = true,
				icon_mode = ItemList.ICON_MODE_TOP,
				icon_scale = 0.5,
				fixed_icon_size = Vector2.ONE * 256,
				rect_min_size = Vector2.RIGHT * 128 }),
		]).build()

func _on_item_list_item_selected(index: int, metadata) -> void:
	emit_signal("selected", metadata)
