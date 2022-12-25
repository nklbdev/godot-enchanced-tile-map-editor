extends Object

const Common = preload("common.gd")

var _drawing_settings: Common.DrawingSettings

func _init(drawing_settings: Common.DrawingSettings) -> void:
	_drawing_settings = drawing_settings

func draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	pass
