class_name VisualTheme
extends RefCounted

static func card_color(card_type: String) -> Color:
	match card_type:
		"attack": return Color("c95d55")
		"power": return Color("9a6bc5")
		"status": return Color("6fa86f")
		_: return Color("4f8fbd")

static func panel() -> Color: return Color("202b38")
static func panel_light() -> Color: return Color("2d3c4d")
static func gold() -> Color: return Color("f3c969")
static func text() -> Color: return Color("e7edf3")
