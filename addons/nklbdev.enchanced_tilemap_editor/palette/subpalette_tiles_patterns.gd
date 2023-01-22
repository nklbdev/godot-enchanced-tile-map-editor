extends "_list_subpalette.gd"

var __cache: Dictionary

func _init().("Patterns", "pattern") -> void:
	_item_list.connect("gui_input", self, "__on_item_list_gui_input")

func _after_set_up() -> void:
	pass

func _before_tear_down() -> void:
	pass

func __on_item_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if (event.control or event.command) and not event.alt and event.scancode == KEY_V:
				get_tree().set_input_as_handled()
				var clipboard_content: String = OS.clipboard
				if not clipboard_content:
					return
				for item_index in _item_list.get_item_count():
					if _item_list.get_item_text(item_index) == clipboard_content:
						_item_list.select(item_index)
						return
				_item_list.add_item(clipboard_content)
				_item_list.select(_item_list.get_item_count() - 1)
