extends Node2D

const MAX_HP := 100
const MAX_ENERGY := 3
const HAND_SIZE := 3

var player_hp := MAX_HP
var enemy_hp := 60
var energy := MAX_ENERGY
var turn := 1
var game_over := false
var in_map := false
var message := "Turn 1 — play a card or press E to end turn"

var deck := [
	{"name": "Strike", "cost": 1, "damage": 15, "heal": 0},
	{"name": "Strike", "cost": 1, "damage": 15, "heal": 0},
	{"name": "Fireball", "cost": 2, "damage": 25, "heal": 0},
	{"name": "Guard", "cost": 1, "damage": 0, "heal": 10},
	{"name": "Heavy Blow", "cost": 3, "damage": 40, "heal": 0}
]
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []

func _ready() -> void:
	randomize()
	reset_battle()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M and not game_over:
			in_map = true
			message = "Adventure map — choose your next node."
			queue_redraw()
			return
		if event.keycode == KEY_B and in_map:
			in_map = false
			message = "Battle — play a card or press E to end turn"
			queue_redraw()
			return
		if event.keycode == KEY_R:
			reset_battle()
			return
		if in_map or game_over:
			return
		match event.keycode:
			KEY_1: play_card(0)
			KEY_2: play_card(1)
			KEY_3: play_card(2)
			KEY_E: end_turn()

func reset_battle() -> void:
	player_hp = MAX_HP
	enemy_hp = 60
	energy = MAX_ENERGY
	turn = 1
	game_over = false
	in_map = false
	discard_pile.clear()
	hand.clear()
	draw_pile = deck.duplicate(true)
	draw_pile.shuffle()
	message = "Turn 1 — play a card or press E to end turn"
	draw_cards(HAND_SIZE)

func draw_cards(amount: int) -> void:
	for _i in range(amount):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> void:
	if index < 0 or index >= hand.size():
		return
	var card: Dictionary = hand[index]
	var cost: int = card["cost"]
	if cost > energy:
		message = "%s costs %d energy." % [card["name"], cost]
		return

	energy -= cost
	enemy_hp = max(0, enemy_hp - int(card["damage"]))
	player_hp = min(MAX_HP, player_hp + int(card["heal"]))
	message = "%s!" % card["name"]
	if card["damage"] > 0:
		message += " Enemy takes %d damage." % card["damage"]
	if card["heal"] > 0:
		message += " You recover %d HP." % card["heal"]

	discard_pile.append(hand.pop_at(index))
	if enemy_hp <= 0:
		game_over = true
		message = "Victory! Press R to play again, or M for the map."

func end_turn() -> void:
	if game_over:
		return
	var enemy_damage := 5 + (turn - 1) * 2
	player_hp = max(0, player_hp - enemy_damage)
	if player_hp <= 0:
		game_over = true
		message = "Defeat! Enemy dealt %d damage. Press R to restart." % enemy_damage
		return
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	turn += 1
	energy = MAX_ENERGY
	draw_cards(HAND_SIZE)
	message = "Turn %d — enemy dealt %d. Your move." % [turn, enemy_damage]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("18202a"))
	draw_rect(Rect2(40, 30, 880, 480), Color("263342"), true)
	draw_string(ThemeDB.fallback_font, Vector2(65, 70), "CARD RPG", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(65, 100), message, HORIZONTAL_ALIGNMENT_LEFT, 830, 17, Color("d8e0e8"))

	if in_map:
		_draw_map_hint()
		return

	draw_circle(Vector2(250, 205), 55, Color("4d8bd6"))
	draw_string(ThemeDB.fallback_font, Vector2(205, 211), "HERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_circle(Vector2(710, 205), 55, Color("b94a59"))
	draw_string(ThemeDB.fallback_font, Vector2(665, 211), "ENEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	_draw_bar(Vector2(155, 280), player_hp, MAX_HP, "HP %d / %d" % [player_hp, MAX_HP])
	_draw_bar(Vector2(615, 280), enemy_hp, 60, "HP %d / 60" % enemy_hp)
	draw_string(ThemeDB.fallback_font, Vector2(65, 335), "TURN %d" % turn, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(185, 335), "ENERGY %d / %d" % [energy, MAX_ENERGY], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(390, 335), "1-3: card   E: end turn   M: map   R: restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b8c5d2"))
	for i in range(hand.size()):
		_draw_card(i, hand[i])

func _draw_map_hint() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(120, 200), "MAP MODE", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(120, 245), "The adventure map is available in scripts/map.gd.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(120, 280), "B: return to battle", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c5d0dc"))

func _draw_bar(pos: Vector2, value: int, maximum: int, label: String) -> void:
	draw_rect(Rect2(pos, Vector2(190, 18)), Color("111820"), true)
	var ratio := clamp(float(value) / float(maximum), 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(190.0 * ratio, 18)), Color("5fcf7a"), true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, 40), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_card(index: int, card: Dictionary) -> void:
	var x := 75.0 + index * 280.0
	var rect := Rect2(x, 365, 250, 115)
	draw_rect(rect, Color("394b5f"), true)
	draw_rect(rect, Color("7f95aa"), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(15, 30), "%d  %s" % [index + 1, card["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(15, 60), "Cost: %d" % card["cost"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f2d27b"))
	var effect := "Damage %d" % card["damage"] if card["damage"] > 0 else "Heal %d" % card["heal"]
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(15, 90), effect, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c5d0dc"))
