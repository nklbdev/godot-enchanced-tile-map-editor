extends TabContainer

const Common = preload("../common.gd")

const SubpaletteBase = preload("_subpalette.gd")
const PatternPalette = preload("pattern.gd")
const PatternMapPalette = preload("pattern_map.gd")
const AutotilePalette = preload("autotile.gd")
const TerrainPalette = preload("terrain.gd")

var __editor_scale: float

func _init(editor_scale: float) -> void:
	__editor_scale = editor_scale
	anchor_right = 1
	anchor_bottom = 1
	__add_subpalette(PatternPalette.new(), "By Texture", preload("../icons/paint_tool_bucket.svg"), "pattern_selected")
	__add_subpalette(PatternMapPalette.new(), "By Tile", preload("../icons/paint_tool_bucket.svg"), "pattern_selected")
	__add_subpalette(TerrainPalette.new(), "By Terrain", preload("../icons/paint_tool_bucket.svg"), "terrain_selected")


func set_up(tile_map: TileMap) -> void:
	for tab_index in get_tab_count():
		get_tab_control(tab_index).set_up(tile_map)

func tear_down() -> void:
	for tab_index in get_tab_count():
		get_tab_control(tab_index).tear_down()

func __add_subpalette(subpalette: SubpaletteBase, title: String, icon: Texture, propagated_signal_name: String) -> void:
	var tab_index = get_tab_count()
	add_child(subpalette)
	set_tab_title(tab_index, title)
	set_tab_icon(tab_index, Common.resize_texture(icon, __editor_scale / 4))
	subpalette.connect("selected", self, "__on_subpalette_selected", [subpalette, propagated_signal_name])

signal pattern_selected(pattern)
signal autotile_selected(autotile)
signal terrain_selected(terrain)

func __on_subpalette_selected(data, subpalette: SubpaletteBase, propagated_signal_name: String) -> void:
	for tab_index in get_tab_count():
		var tab_subpalette = get_tab_control(tab_index) as SubpaletteBase
		if tab_subpalette != subpalette:
			tab_subpalette.unselect()
	emit_signal(propagated_signal_name, data)
