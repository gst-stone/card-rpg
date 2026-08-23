extends Node2D

signal finished(result: String)
var run: RunData
var message := "An old shrine stands before you."
var done := false

func setup(run_data: RunData) -> void:
	run = run_data
	queue_redraw()

func _input(event: InputEvent) -> void:
	if done: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: choose(1)
			KEY_2: choose(2)
			KEY_B: finished.emit("map")

func choose(option: int) -> void:
	if option == 1:
		run.heal(20)
		message = "The shrine restores 20 HP."
	else:
		run.take_damage(8)
		run.add_gold(60)
		message = "You take 8 damage, but find 60 gold."
	done = true
	SaveManager.save_run(run)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("171d28"), true)
	draw_string(ThemeDB.fallback_font, Vector2(70,80), "MYSTERIOUS SHRINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(70,130), message, HORIZONTAL_ALIGNMENT_LEFT, 800, 20, Color("d8e0e8"))
	if not done:
		draw_string(ThemeDB.fallback_font, Vector2(110,250), "1  Pray — restore 20 HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(110,310), "2  Search — lose 8 HP, gain 60 gold", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(110,300), "B  Return to map", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("c5d0dc"))
