extends Node2D

const MAP := 0
const BATTLE := 1
const SHOP := 2
const EVENT := 3
const REST := 4
const BOSS := 5
const VICTORY := 6
const DEFEAT := 7

var state := MAP
var run: RunData
var screen_message := "Choose your next node."
var node_type := "battle"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	run = SaveManager.load_run()
	if run.current_node == "victory": state = VICTORY
	elif run.current_node == "defeat": state = DEFEAT
	else: state = MAP
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			run = RunData.new()
			SaveManager.save_run(run)
			state = MAP
			screen_message = "New run started."
			queue_redraw()
			return
		if state == MAP:
			match event.keycode:
				KEY_1: select_node("battle")
				KEY_2: select_node("shop")
				KEY_3: select_node("event")
				KEY_4: select_node("rest")
				KEY_5: select_node("boss")
			return
		if state == VICTORY or state == DEFEAT:
			return

func select_node(type: String) -> void:
	node_type = type
	run.current_node = type
	SaveManager.save_run(run)
	match type:
		"battle":
			state = BATTLE
			screen_message = "Battle started. Press E to finish a turn."
		"shop":
			state = SHOP
			screen_message = "Shop: 1 Fireball, 2 Heavy Blow, 3 Heal."
		"event":
			state = EVENT
			screen_message = "Shrine: 1 heal, 2 search for gold."
		"rest":
			state = REST
			screen_message = "Rest: press 1 to recover 30 HP."
		"boss":
			state = BOSS
			screen_message = "Guardian Boss!"
	queue_redraw()

func finish_node(success: bool = true) -> void:
	if not success:
		state = DEFEAT
		run.current_node = "defeat"
	else:
		state = MAP
		run.current_node = "map"
	SaveManager.save_run(run)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("111820"), true)
	draw_rect(Rect2(40,30,880,480), Color("263342"), true)
	draw_string(ThemeDB.fallback_font, Vector2(65,75), "CARD RPG", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(65,110), screen_message, HORIZONTAL_ALIGNMENT_LEFT, 820, 18, Color("d8e0e8"))
	match state:
		MAP: _draw_map()
		BATTLE: _draw_panel("BATTLE", "Fight the enemy. 1-3 cards, E ends turn.")
		SHOP: _draw_panel("SHOP", "Buy cards or healing.")
		EVENT: _draw_panel("EVENT", "Make a risky shrine choice.")
		REST: _draw_panel("REST", "Recover before the next battle.")
		BOSS: _draw_panel("BOSS", "Defeat the Guardian to win the run.")
		VICTORY: _draw_panel("VICTORY", "Run complete! Press R for a new run.")
		DEFEAT: _draw_panel("DEFEAT", "Run failed. Press R for a new run.")

func _draw_map() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(110,190), "ADVENTURE MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(110,235), "1 Battle", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110,275), "2 Shop", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110,315), "3 Event", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110,355), "4 Rest", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110,395), "5 Boss", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ff8a8a"))
	draw_string(ThemeDB.fallback_font, Vector2(560,190), "HP: %d/%d" % [run.player_hp,run.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("8ad7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(560,230), "Gold: %d" % run.gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(560,270), "Floor: %d" % run.floor, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(560,310), "Cards: %d" % run.deck.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(65,480), "R New Run", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b8c5d2"))

func _draw_panel(title: String, subtitle: String) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(110,210), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(110,255), subtitle, HORIZONTAL_ALIGNMENT_LEFT, 700, 19, Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(110,330), "HP %d/%d    Gold %d    Floor %d" % [run.player_hp,run.max_hp,run.gold,run.floor], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110,390), "B: return to map    R: new run", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8c5d2"))
