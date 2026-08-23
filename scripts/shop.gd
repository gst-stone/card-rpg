extends Node2D

signal closed

var run: RunData
var offers := [
	{"name": "Fireball", "price": 60, "type": "card"},
	{"name": "Heavy Blow", "price": 80, "type": "card"},
	{"name": "Heal 25 HP", "price": 40, "type": "heal"}
]
var message := "Choose an offer: 1, 2 or 3"

func setup(run_data: RunData) -> void:
	run = run_data
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: buy(0)
			KEY_2: buy(1)
			KEY_3: buy(2)
			KEY_B: closed.emit()

func buy(index: int) -> void:
	if run == null or index < 0 or index >= offers.size():
		return
	var offer: Dictionary = offers[index]
	var price: int = offer["price"]
	if not run.spend_gold(price):
		message = "Not enough gold."
		queue_redraw()
		return
	if offer["type"] == "card":
		run.add_card(offer["name"])
		message = "Bought %s for %d gold." % [offer["name"], price]
	else:
		run.heal(25)
		message = "Restored 25 HP for %d gold." % price
	SaveManager.save_run(run)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("151c24"), true)
	draw_string(ThemeDB.fallback_font, Vector2(65, 75), "SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f2d27b"))
	var gold := run.gold if run != null else 0
	var hp := run.player_hp if run != null else 0
	draw_string(ThemeDB.fallback_font, Vector2(65, 110), "Gold: %d    HP: %d" % [gold, hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(65, 145), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("c5d0dc"))
	for i in offers.size():
		var rect := Rect2(75 + i * 285, 210, 255, 170)
		draw_rect(rect, Color("394b5f"), true)
		draw_rect(rect, Color("7f95aa"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, 38), "%d  %s" % [i + 1, offers[i]["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, 78), "%d gold" % offers[i]["price"], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(75, 455), "B: leave shop", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8c5d2"))
