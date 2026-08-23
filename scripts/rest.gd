extends Node2D

signal finished(result: String)
var run: RunData
var used := false

func setup(run_data: RunData) -> void:
	run = run_data
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				if not used:
					run.heal(30)
					used = true
					SaveManager.save_run(run)
					queue_redraw()
			KEY_B: finished.emit("map")

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("17251c"), true)
	draw_string(ThemeDB.fallback_font, Vector2(70,80), "REST SITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(70,140), "HP: %d / %d" % [run.player_hp, run.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	if used:
		draw_string(ThemeDB.fallback_font, Vector2(110,260), "You feel refreshed. +30 HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("5fcf7a"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(110,260), "1  Rest — recover 30 HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110,340), "B  Return to map", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("c5d0dc"))
