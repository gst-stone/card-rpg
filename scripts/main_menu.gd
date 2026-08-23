extends Node2D

var started := false

func _ready() -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			started = true
			queue_redraw()
			get_tree().change_scene_to_file("res://scenes/game.tscn")
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("10151c"),true)
	draw_rect(Rect2(45,35,870,470),Color("263342"),true)
	draw_string(ThemeDB.fallback_font,Vector2(155,185),"CARD RPG",HORIZONTAL_ALIGNMENT_LEFT,-1,64,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(160,240),"A roguelike deck-building adventure",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font,Vector2(160,330),"ENTER / SPACE    Start Run",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(160,375),"Build your deck • Collect relics • Defeat the Guardian",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b8c5d2"))
	draw_string(ThemeDB.fallback_font,Vector2(160,450),"Prototype build",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("8291a1"))
