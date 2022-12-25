extends "_drawable.gd"

const Paper = preload("paper.gd")

var _paper: Paper

func _init(drawing_settings: Common.DrawingSettings).(drawing_settings) -> void:
	pass

func is_ready() -> bool:
	return _paper != null

func set_up(paper: Paper) -> void:
	assert(_paper == null, "can not set up twice")
	_paper = paper
	_after_set_up()

func tear_down() -> void:
	assert(_paper != null, "can not tear down twice")
	_before_tear_down()
	_paper = null

func draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	if _paper != null:
		_on_draw(overlay, tile_map, force)

func _after_set_up() -> void:
	pass

func _before_tear_down() -> void:
	pass

func _on_draw(overlay: Control, tile_map: TileMap, force: bool = false) -> void:
	pass
