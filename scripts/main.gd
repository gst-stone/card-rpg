extends Node2D

const MAX_ENERGY := 3
const HAND_SIZE := 3
var run: RunData
var enemy_hp := 60
var enemy_max_hp := 60
var energy := MAX_ENERGY
var turn := 1
var game_over := false
var in_map := false
var message := ""
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []
var card_defs := {"Strike":{"cost":1,"damage":15,"heal":0},"Fireball":{"cost":2,"damage":25,"heal":0},"Guard":{"cost":1,"damage":0,"heal":10},"Heavy Blow":{"cost":3,"damage":40,"heal":0}}

func _ready() -> void:
	run = SaveManager.load_run()
	start_battle()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: new_run()
			KEY_M:
				if not game_over: in_map = true; message = "Map — press B to return."
			KEY_B:
				if in_map: in_map = false; message = "Battle — play 1-3 or press E."
			KEY_1: play_card(0)
			KEY_2: play_card(1)
			KEY_3: play_card(2)
			KEY_E: end_turn()

func new_run() -> void:
	run = RunData.new()
	SaveManager.save_run(run)
	start_battle()

func start_battle() -> void:
	enemy_max_hp = 60 + max(0, run.floor - 1) * 10
	enemy_hp = enemy_max_hp
	energy = MAX_ENERGY; turn = 1; game_over = false; in_map = false
	draw_pile.clear(); discard_pile.clear(); hand.clear()
	for card_name in run.deck: draw_pile.append(card_name)
	draw_pile.shuffle(); draw_cards(HAND_SIZE)
	message = "Battle — %d gold | play 1-3 or press E." % run.gold

func card_data(card_name: String) -> Dictionary:
	return card_defs.get(card_name, {"cost":1,"damage":5,"heal":0})

func draw_cards(amount: int) -> void:
	for _i in amount:
		if draw_pile.is_empty():
			if discard_pile.is_empty(): return
			draw_pile = discard_pile.duplicate(); discard_pile.clear(); draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> void:
	if in_map or game_over or index >= hand.size(): return
	var card_name: String = hand[index]
	var data := card_data(card_name)
	if int(data.cost) > energy: message = "%s needs %d energy." % [card_name, data.cost]; return
	energy -= int(data.cost)
	enemy_hp = max(0, enemy_hp - int(data.damage))
	run.heal(int(data.heal))
	discard_pile.append(hand.pop_at(index))
	message = "%s played." % card_name
	if enemy_hp <= 0: victory()

func victory() -> void:
	var reward := 30 + run.floor * 10
	run.add_gold(reward); run.floor += 1; run.heal(12)
	SaveManager.save_run(run)
	game_over = true
	message = "Victory! +%d gold, +12 HP. Press M or R." % reward

func end_turn() -> void:
	if in_map or game_over: return
	var damage := 5 + (turn - 1) * 2 + max(0, run.floor - 1)
	run.take_damage(damage)
	if run.player_hp <= 0:
		game_over = true; SaveManager.save_run(run); message = "Defeat. Press R to start a new run."; return
	for card in hand: discard_pile.append(card)
	hand.clear(); turn += 1; energy = MAX_ENERGY; draw_cards(HAND_SIZE)
	message = "Enemy hits for %d. Your turn." % damage
	SaveManager.save_run(run)

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("18202a")); draw_rect(Rect2(40,30,880,480), Color("263342"), true)
	draw_string(ThemeDB.fallback_font, Vector2(65,70), "CARD RPG", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(65,100), message, HORIZONTAL_ALIGNMENT_LEFT, 830, 17, Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(700,70), "GOLD %d" % run.gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(700,100), "FLOOR %d" % run.floor, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c5d0dc"))
	if in_map: _draw_map(); return
	draw_circle(Vector2(250,200),55,Color("4d8bd6")); draw_string(ThemeDB.fallback_font,Vector2(205,206),"HERO",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_circle(Vector2(710,200),55,Color("b94a59")); draw_string(ThemeDB.fallback_font,Vector2(665,206),"ENEMY",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	_draw_bar(Vector2(145,275),run.player_hp,run.max_hp,"HP %d / %d" % [run.player_hp,run.max_hp])
	_draw_bar(Vector2(615,275),enemy_hp,enemy_max_hp,"HP %d / %d" % [enemy_hp,enemy_max_hp])
	draw_string(ThemeDB.fallback_font,Vector2(65,330),"TURN %d   ENERGY %d/%d" % [turn,energy,MAX_ENERGY],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f2d27b"))
	for i in hand.size(): _draw_card(i,hand[i])
	draw_string(ThemeDB.fallback_font,Vector2(65,500),"1-3 Card   E End Turn   M Map   R New Run",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("b8c5d2"))

func _draw_map() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(110,200),"ADVENTURE MAP",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(110,245),"Battle → Reward → Shop / Event / Rest → Boss",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font,Vector2(110,285),"Current floor: %d" % run.floor,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(110,350),"B: battle",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b8c5d2"))

func _draw_bar(pos: Vector2,value: int,maximum: int,label: String) -> void:
	draw_rect(Rect2(pos,Vector2(190,18)),Color("111820"),true); draw_rect(Rect2(pos,Vector2(190.0*clamp(float(value)/maximum,0.0,1.0),18)),Color("5fcf7a"),true)
	draw_string(ThemeDB.fallback_font,pos+Vector2(0,40),label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)

func _draw_card(index: int,card_name: String) -> void:
	var data:=card_data(card_name); var rect:=Rect2(55+index*300,365,270,110)
	draw_rect(rect,Color("394b5f"),true); draw_rect(rect,Color("7f95aa"),false,2.0)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,30),"%d  %s"%[index+1,card_name],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,60),"Cost: %d"%data.cost,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2d27b"))
	var effect: String = "Damage %d"%data.damage if int(data.damage)>0 else "Heal %d"%data.heal
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,88),effect,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c5d0dc"))
