class_name CharacterArt
extends RefCounted

static func draw_hero(canvas: CanvasItem, center: Vector2, flash: float, bob: float) -> void:
	var c := Color("74c7f5") if flash <= 0.0 else Color.WHITE
	var p := center + Vector2(0, sin(bob * 2.5) * 2.0)
	canvas.draw_circle(p, 42, c)
	canvas.draw_circle(p + Vector2(0, -5), 29, Color("253347"))
	canvas.draw_circle(p + Vector2(-11, -8), 4, Color.WHITE)
	canvas.draw_circle(p + Vector2(11, -8), 4, Color.WHITE)
	canvas.draw_circle(p + Vector2(0, 3), 12, Color("e4b96c"))
	canvas.draw_line(p + Vector2(-18, 16), p + Vector2(18, 16), Color("17202c"), 4.0)
	canvas.draw_string(ThemeDB.fallback_font, p + Vector2(-60, 74), "THE WANDERER", HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color("a9ddff"))

static func draw_enemy(canvas: CanvasItem, center: Vector2, flash: float, elite: bool) -> void:
	var c := Color("b968cf") if elite else Color("e06470")
	if flash > 0.0: c = Color.WHITE
	canvas.draw_circle(center, 52 if elite else 46, c)
	canvas.draw_circle(center + Vector2(-15, -6), 6, Color("1c1820"))
	canvas.draw_circle(center + Vector2(15, -6), 6, Color("1c1820"))
	canvas.draw_arc(center + Vector2(0, 10), 18, 0.15, 2.99, 20, Color("1c1820"), 3.0)
	if elite: canvas.draw_circle(center + Vector2(0, -48), 10, Color("f3c969"))
