extends TabContainer

const Common = preload("../common.gd")

const SubpaletteBase = preload("_subpalette.gd")
const PatternPalette = preload("pattern.gd")
const AutotilePalette = preload("autotile.gd")
const TerrainPalette = preload("terrain.gd")

var __editor_scale: float

func _init(editor_scale: float) -> void:
	__editor_scale = editor_scale
	anchor_right = 1
	anchor_bottom = 1
	__add_subpalette(PatternPalette.new(), "Patterns", preload("../icons/paint_tool_bucket.svg"))
	__add_subpalette(AutotilePalette.new(), "Autotiles", preload("../icons/paint_tool_bucket.svg"))
	__add_subpalette(TerrainPalette.new(), "Terrains", preload("../icons/paint_tool_bucket.svg"))

func set_tile_set(tile_set: TileSet) -> void:
	for tab_index in get_tab_count():
		get_tab_control(tab_index).set_tile_set(tile_set)

func __add_subpalette(subpalette: SubpaletteBase, title: String, icon: Texture) -> void:
	var tab_index = get_tab_count()
	add_child(subpalette)
	set_tab_title(tab_index, title)
	set_tab_icon(tab_index, Common.resize_texture(icon, __editor_scale / 4))
	subpalette.connect("selected", self, "__on_subpalette_selected", [subpalette])

func __on_subpalette_selected(data, subpalette: SubpaletteBase) -> void:
	for tab_index in get_tab_count():
		var tab_subpalette = get_tab_control(tab_index) as SubpaletteBase
		if tab_subpalette != subpalette:
			tab_subpalette.unselect()
	# emit signal to editor
	print("selected! ", data)
