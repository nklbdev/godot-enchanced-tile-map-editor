#extends "../_base.gd"
#const Attachment = preload("../_base.gd")
#
#var __attachment: Attachment
#
#func _init(attachment: Attachment) -> void:
#	__attachment = attachment
#
#func _on_set_up() -> void:
#	__attachment.set_up(get_paper())
#
#func _on_tear_down() -> void:
#	__attachment.tear_down()
#
#func _on_putted_on() -> void:
#	__attachment.put_on()
#	# поставить свою насадку на эту точку
#	pass
#
#func _on_taken_off() -> void:
#	__attachment.take_off()
#	__attachment.apply()
#
#func _on_moved(from: Vector2) -> void:
#	# провести свою насадку через все точки пути
#	pass
#
#func _on_apply() -> void:
#	pass
#
#func _on_cancel(force: bool) -> void:
#	pass
