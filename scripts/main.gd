extends Node2D

var player_pos := Vector2(480, 270)
var player_hp := 100
var enemy_hp := 60
var cards := ["Strike", "Fireball", "Guard"]
var message := "Choose a card with 1 / 2 / 3"

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				use_card(0)
			KEY_2:
				use_card(1)
			KEY_3:
				use_card(2)
			KEY_R:
				reset_battle()

func use_card(index: int) -> void:
	if enemy_hp <= 0:
		message = "Enemy defeated! Press R to restart."
		return

	match index:
		0:
			enemy_hp = max(0, enemy_hp - 15)
			message = "Strike deals 15 damage."
		1:
			enemy_hp = max(0, enemy_hp - 25)
			message = "Fireball deals 25 damage."
		2:
			player_hp = min(100, player_hp + 10)
			message = "Guard restores 10 HP."

	if enemy_hp > 0:
		player_hp = max(0, player_hp - 5)
		message += " Enemy counterattacks for 5 damage."
		if player_hp <= 0:
			message = "You were defeated! Press R to restart."

func reset_battle() -> void:
	player_hp = 100
	enemy_hp = 60
	message = "Choose a card with 1 / 2 / 3"

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 960, 540), Color("18202a"))
	draw_rect(Rect2(40, 35, 880, 470), Color("263342"), true)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(70, 80), "CARD RPG", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(70, 112), message, HORIZONTAL_ALIGNMENT_LEFT, 820, 18, Color("d8e0e8"))

	# Player and enemy
	draw_circle(Vector2(260, 230), 55, Color("4d8bd6"))
	draw_string(ThemeDB.fallback_font, Vector2(215, 236), "HERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_circle(Vector2(700, 230), 55, Color("b94a59"))
	draw_string(ThemeDB.fallback_font, Vector2(655, 236), "ENEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	_draw_bar(Vector2(175, 305), player_hp, "HP %d / 100" % player_hp)
	_draw_bar(Vector2(615, 305), enemy_hp, "HP %d / 60" % enemy_hp)

	# Cards
	for i in cards.size():
		var rect := Rect2(120 + i * 250, 365, 210, 105)
		draw_rect(rect, Color("394b5f"), true)
		draw_rect(rect, Color("7f95aa"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, 34), "%d  %s" % [i + 1, cards[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	var desc := ["15 damage", "25 damage", "+10 HP"][i]
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, 68), desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c5d0dc"))

func _draw_bar(pos: Vector2, value: int, label: String) -> void:
	draw_rect(Rect2(pos, Vector2(170, 18)), Color("111820"), true)
	draw_rect(Rect2(pos, Vector2(170.0 * value / 100.0, 18)), Color("5fcf7a"), true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, 42), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
