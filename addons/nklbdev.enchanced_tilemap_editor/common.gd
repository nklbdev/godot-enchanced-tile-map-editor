extends Object

enum ActionType {
	NONE = -1,
	PAINT = 0,
	ERASE = 1
}

enum PaintMode {
	BRUSH = 0,
	LINE = 1,
	RECT = 2
}

enum DrawingShape {
	POINT,
	LINE,
	RECT
}

enum DrawingType {
	PASTE,
	ERASE,
	CLONE
}

enum SelectionType {
	RECT,
	LASSO,
	POLYGON,
	CONTINOUS,
	SAME
}

enum PatternFillType {
	FREE,
	TILED, # need origin point
}

enum TilePatternToolType {
	SELECTION = 0,
	DRAWING = 1,
	FILLING = 3,
}

enum TransformType {
	CLEAR_TRANSFORM = -1
	ROTATE_CLOCKWISE = 0,
	ROTATE_COUNTERCLOCKWISE = 1,
	FLIP_HORIZONTALLY = 2,
	FLIP_VERTICALLY = 3,
	TRANSPOSE
}

enum SelectionActionType {
	CUT = 0,
	COPY = 1,
	DELETE = 2
}

enum SelectionCombineOperationType {
	REPLACEMENT = 0,
	UNION = 1,
	INTERSECTION = 2,
	FORWARD_SUBTRACTION = 3,
	BACKWARD_SUBTRACTION = 4
}

enum ShapeLayoutFlag { # FLAGS
	SIMPLE = 0,
	REGULAR = 1,
	CENTERED = 2,
}

enum EventResultFlag { # FLAGS
	NONE = 0
	EVENT_CONSUMED = 1,
	UPDATE_OVERLAYS = 2
}

class SelectionSettings:
	const BORDER_COLOR: Color = Color(1, 0, 0, 1)
	const FILL_COLOR: Color = Color(1, 0, 0, 0.5)
	const BORDER_WIDTH: float = 2.0
