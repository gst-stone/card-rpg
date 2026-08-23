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
var message := "Choose your next node."
var enemy_hp := 60
var enemy_max_hp := 60
var energy := 3
var turn := 1
var hand: Array = []
var discard: Array = []
var draw_pile: Array = []
var shop_offers := [{"name":"Fireball","price":60},{"name":"Heavy Blow","price":80},{"name":"Heal","price":40}]
var event_done := false
var rest_done := false
var boss_hp := 180
var boss_max_hp := 180
var boss_defeated := false
var card_defs := {"Strike":{"cost":1,"damage":15,"heal":0},"Fireball":{"cost":2,"damage":25,"heal":0},"Guard":{"cost":1,"damage":0,"heal":10},"Heavy Blow":{"cost":3,"damage":40,"heal":0}}

func _ready() -> void:
	run = SaveManager.load_run()
	match run.current_node:
		"victory": state = VICTORY
		"defeat": state = DEFEAT
		_: state = MAP
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	var key := event.keycode
	if key == KEY_R:
		new_run()
		return
	match state:
		MAP:
			if key == KEY_1: select_node("battle")
			elif key == KEY_2: select_node("shop")
			elif key == KEY_3: select_node("event")
			elif key == KEY_4: select_node("rest")
			elif key == KEY_5: select_node("boss")
		BATTLE:
			if key == KEY_1: play_card(0)
			elif key == KEY_2: play_card(1)
			elif key == KEY_3: play_card(2)
			elif key == KEY_E: end_turn()
			elif key == KEY_B: finish_node(true)
		SHOP:
			if key == KEY_1: buy(0)
			elif key == KEY_2: buy(1)
			elif key == KEY_3: buy(2)
			elif key == KEY_B: finish_node(true)
		EVENT:
			if not event_done and key == KEY_1: event_choice(1)
			elif not event_done and key == KEY_2: event_choice(2)
			elif event_done and key == KEY_B: finish_node(true)
		REST:
			if not rest_done and key == KEY_1: rest()
			elif key == KEY_B: finish_node(true)
		BOSS:
			if key == KEY_1: boss_play(0)
			elif key == KEY_2: boss_play(1)
			elif key == KEY_3: boss_play(2)
			elif key == KEY_E: boss_turn()
			elif boss_defeated and key == KEY_B: finish_run()

func new_run() -> void:
	run = RunData.new()
	SaveManager.save_run(run)
	state = MAP
	message = "New run started."

func select_node(type: String) -> void:
	run.current_node = type
	SaveManager.save_run(run)
	match type:
		"battle": start_battle()
		"shop": state = SHOP; message = "Choose an item."
		"event": state = EVENT; event_done = false; message = "A mysterious shrine awaits."
		"rest": state = REST; rest_done = false; message = "Take a rest."
		"boss": start_boss()

func start_battle() -> void:
	state = BATTLE
	enemy_max_hp = 60 + max(0, run.floor - 1) * 10
	enemy_hp = enemy_max_hp
	energy = 3
	turn = 1
	hand.clear()
	discard.clear()
	draw_pile = run.deck.duplicate()
	draw_pile.shuffle()
	draw_cards(3)
	message = "Battle started."

func card_data(name: String) -> Dictionary:
	return card_defs.get(name, {"cost":1,"damage":5,"heal":0})

func draw_cards(n: int) -> void:
	for _i in n:
		if draw_pile.is_empty():
			draw_pile = discard.duplicate()
			discard.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty(): return
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> void:
	if index >= hand.size(): return
	var name: String = hand[index]
	var d := card_data(name)
	if int(d.cost) > energy:
		message = "Not enough energy."
		return
	energy -= int(d.cost)
	enemy_hp = max(0, enemy_hp - int(d.damage))
	run.heal(int(d.heal))
	discard.append(hand.pop_at(index))
	if enemy_hp <= 0: battle_victory()

func end_turn() -> void:
	if state != BATTLE: return
	var damage := 5 + (turn - 1) * 2 + max(0, run.floor - 1)
	run.take_damage(damage)
	if run.player_hp <= 0:
		lose_run()
		return
	for c in hand: discard.append(c)
	hand.clear()
	turn += 1
	energy = 3
	draw_cards(3)
	SaveManager.save_run(run)
	message = "Enemy hits for %d." % damage

func battle_victory() -> void:
	run.add_gold(30 + run.floor * 10)
	run.heal(12)
	run.floor += 1
	SaveManager.save_run(run)
	state = MAP
	run.current_node = "map"
	message = "Victory! Choose your next node."

func buy(index: int) -> void:
	var offer = shop_offers[index]
	if not run.spend_gold(int(offer.price)):
		message = "Not enough gold."
		return
	if offer.name == "Heal": run.heal(25)
	else: run.add_card(offer.name)
	SaveManager.save_run(run)
	message = "Purchased %s." % offer.name

func event_choice(option: int) -> void:
	if option == 1:
		run.heal(20)
		message = "The shrine heals 20 HP."
	else:
		run.take_damage(8)
		run.add_gold(60)
		message = "You lose 8 HP and gain 60 gold."
	event_done = true
	SaveManager.save_run(run)

func rest() -> void:
	if rest_done: return
	run.heal(30)
	rest_done = true
	SaveManager.save_run(run)
	message = "Restored 30 HP."

func start_boss() -> void:
	state = BOSS
	boss_hp = 180
	boss_max_hp = 180
	boss_defeated = false
	energy = 3
	hand = run.deck.duplicate()
	hand.shuffle()
	hand = hand.slice(0, min(3, hand.size()))
	message = "The Guardian appears."

func boss_play(index: int) -> void:
	if boss_defeated or index >= hand.size(): return
	var name: String = hand[index]
	var d := card_data(name)
	if int(d.cost) > energy:
		message = "Not enough energy."
		return
	energy -= int(d.cost)
	boss_hp = max(0, boss_hp - int(d.damage))
	run.heal(int(d.heal))
	hand.remove_at(index)
	if boss_hp <= 0:
		boss_defeated = true
		run.add_gold(150)
		run.heal(20)
		run.relics.append("Guardian Core")
		run.current_node = "victory"
		SaveManager.save_run(run)
		message = "Guardian defeated! Press B."

func boss_turn() -> void:
	if boss_defeated: return
	run.take_damage(15)
	energy = 3
	hand = run.deck.duplicate()
	hand.shuffle()
	hand = hand.slice(0, min(3, hand.size()))
	if run.player_hp <= 0:
		lose_run()
		return
	SaveManager.save_run(run)
	message = "Guardian attacks for 15."

func finish_run() -> void:
	state = VICTORY
	run.current_node = "victory"
	SaveManager.save_run(run)

func finish_node(success: bool) -> void:
	if success:
		state = MAP
		run.current_node = "map"
	else:
		lose_run()
	SaveManager.save_run(run)

func lose_run() -> void:
	state = DEFEAT
	run.current_node = "defeat"
	SaveManager.save_run(run)
	message = "Run defeated. Press R."

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("111820"), true)
	draw_rect(Rect2(40,30,880,480), Color("263342"), true)
	draw_string(ThemeDB.fallback_font,Vector2(65,75),"CARD RPG",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(65,110),message,HORIZONTAL_ALIGNMENT_LEFT,820,18,Color("d8e0e8"))
	match state:
		MAP: draw_map()
		BATTLE: draw_battle()
		SHOP: draw_shop()
		EVENT: draw_event()
		REST: draw_rest()
		BOSS: draw_boss()
		VICTORY: draw_center("VICTORY","Run complete! Press R for a new run.")
		DEFEAT: draw_center("DEFEAT","Run failed. Press R for a new run.")

func draw_map() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,185),"ADVENTURE MAP",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("f2d27b"))
	var labels=["1 Battle","2 Shop","3 Event","4 Rest","5 Boss"]
	for i in labels.size():
		draw_string(ThemeDB.fallback_font,Vector2(120,235+i*42),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(570,210),"HP %d/%d"%[run.player_hp,run.max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("8ad7ff"))
	draw_string(ThemeDB.fallback_font,Vector2(570,250),"Gold %d"%run.gold,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(570,290),"Floor %d"%run.floor,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(570,330),"Deck %d"%run.deck.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)

func draw_battle() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,180),"BATTLE",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(600,180),"Enemy %d/%d"%[enemy_hp,enemy_max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ff8a8a"))
	draw_string(ThemeDB.fallback_font,Vector2(100,225),"Your HP %d/%d   Energy %d"%[run.player_hp,run.max_hp,energy],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	for i in hand.size(): draw_card(i,hand[i])
	draw_string(ThemeDB.fallback_font,Vector2(100,480),"1-3 Play Card   E End Turn   B Map",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))

func draw_card(i:int,name:String) -> void:
	var d:=card_data(name)
	var r:=Rect2(70+i*280,300,250,115)
	draw_rect(r,Color("394b5f"),true)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(15,32),"%d %s"%[i+1,name],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(15,68),"Cost %d  Damage %d"%[d.cost,d.damage],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2d27b"))

func draw_shop() -> void:
	draw_center("SHOP","1 Fireball 60g    2 Heavy Blow 80g    3 Heal 40g\nGold: %d\nB Return"%run.gold)

func draw_event() -> void:
	draw_center("SHRINE","1 Pray: +20 HP    2 Search: -8 HP +60g\nB Return")

func draw_rest() -> void:
	draw_center("REST","1 Rest: +30 HP\nHP: %d/%d\nB Return"%[run.player_hp,run.max_hp])

func draw_boss() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,180),"GUARDIAN BOSS  %d/%d"%[boss_hp,boss_max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("ff8a8a"))
	draw_string(ThemeDB.fallback_font,Vector2(100,220),"Your HP %d/%d Energy %d"%[run.player_hp,run.max_hp,energy],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	for i in hand.size(): draw_card(i,hand[i])
	draw_string(ThemeDB.fallback_font,Vector2(100,480),"1-3 Play Card   E Guardian Turn   B after victory",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))

func draw_center(title:String,text:String) -> void:
	draw_string(ThemeDB.fallback_font,Vector2(110,210),title,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(110,270),text,HORIZONTAL_ALIGNMENT_LEFT,730,20,Color("d8e0e8"))
