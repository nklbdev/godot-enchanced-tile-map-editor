extends "../tool_group_base.gd"

const RectSelection = preload("rect.gd")
const LassoSelection = preload("lasso.gd")
const PolygonSelection = preload("polygon.gd")
const ContinousSelection = preload("continous.gd")
const SameSelection = preload("same.gd")

func _init(editor: EditorPlugin).(editor) -> void:
	name = "Selection"
	
	var button_group = ButtonGroup.new()
	_add_tool(RectSelection.new(_editor, button_group))
	_add_tool(LassoSelection.new(_editor, button_group))
	_add_tool(PolygonSelection.new(_editor, button_group))
	_add_tool(ContinousSelection.new(_editor, button_group))
	_add_tool(SameSelection.new(_editor, button_group))
