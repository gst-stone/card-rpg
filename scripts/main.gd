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
var reward_pending := false
var shop_pending := false
var reward_choices: Array = []
var shop_cards: Array = []
var shop_relic: Dictionary = {}
var message := ""
var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []

func _ready() -> void:
	run = SaveManager.load_run()
	run.apply_relics()
	start_battle()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: new_run()
			KEY_M:
				if not game_over and not reward_pending and not shop_pending: in_map = true; message = "Map — B battle, S shop, R restart."
			KEY_B:
				if in_map: in_map = false; message = "Battle — play 1-3 or press E."
			KEY_S:
				if in_map and not game_over: open_shop()
			KEY_1: play_card(0)
			KEY_2: play_card(1)
			KEY_3: play_card(2)
			KEY_E: end_turn()
			KEY_4: choose_reward(0)
			KEY_5: choose_reward(1)
			KEY_6: choose_reward(2)
			KEY_7: buy_shop_card(0)
			KEY_8: buy_shop_card(1)
			KEY_9: buy_shop_relic()

func new_run() -> void:
	run = RunData.new()
	SaveManager.save_run(run)
	start_battle()

func start_battle() -> void:
	run.apply_relics()
	enemy_max_hp = 60 + max(0, run.floor - 1) * 10
	if run.floor % 5 == 0: enemy_max_hp += 30
	enemy_hp = enemy_max_hp
	energy = MAX_ENERGY; turn = 1; game_over = false; in_map = false; reward_pending = false; shop_pending = false
	draw_pile.clear(); discard_pile.clear(); hand.clear()
	for card_name in run.deck: draw_pile.append(card_name)
	draw_pile.shuffle(); draw_cards(HAND_SIZE)
	message = "BOSS!" if run.floor % 5 == 0 else "Battle — %d gold | play 1-3 or press E." % run.gold

func card_data(card_name: String) -> Dictionary:
	return CardCatalog.get_card(card_name)

func draw_cards(amount: int) -> void:
	for _i in amount:
		if draw_pile.is_empty():
			if discard_pile.is_empty(): return
			draw_pile = discard_pile.duplicate(); discard_pile.clear(); draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> void:
	if in_map or game_over or reward_pending or shop_pending or index >= hand.size(): return
	var card_name: String = hand[index]
	var data := card_data(card_name)
	if data.is_empty(): return
	if int(data.get("cost", 1)) > energy: message = "%s needs %d energy." % [card_name, data.get("cost", 1)]; return
	energy -= int(data.get("cost", 1))
	var damage := int(data.get("damage", 0)) + RelicCatalog.damage_bonus(run.relics)
	enemy_hp = max(0, enemy_hp - damage)
	run.heal(int(data.get("heal", 0)))
	discard_pile.append(hand.pop_at(index))
	message = "%s played." % card_name
	if enemy_hp <= 0: victory()

func victory() -> void:
	var reward := 30 + run.floor * 10
	if run.floor % 5 == 0: reward += 50
	run.add_gold(reward)
	run.heal(12)
	if run.floor % 5 == 0:
		run.add_relic("Guardian Core")
		run.apply_relics()
	run.floor += 1
	SaveManager.save_run(run)
	reward_choices = ["Slash", "Ice Lance", "Blood Pact"]
	reward_pending = true; game_over = true
	message = "Victory! +%d gold. Choose reward 4-6." % reward

func choose_reward(index: int) -> void:
	if not reward_pending or index < 0 or index >= reward_choices.size(): return
	run.add_card(reward_choices[index])
	reward_pending = false; game_over = false
	SaveManager.save_run(run)
	start_battle()

func open_shop() -> void:
	shop_cards = Shop.random_cards()
	shop_relic = Shop.random_relic()
	shop_pending = true
	message = "SHOP — 7/8 buy cards, 9 buy relic, B leave."

func buy_shop_card(index: int) -> void:
	if not shop_pending or index < 0 or index >= shop_cards.size(): return
	var offer: Dictionary = shop_cards[index]
	if run.spend_gold(int(offer.cost)):
		run.add_card(str(offer.name)); shop_pending = false; message = "Bought %s." % offer.name; SaveManager.save_run(run)
	else: message = "Not enough gold for %s." % offer.name

func buy_shop_relic() -> void:
	if not shop_pending or shop_relic.is_empty(): return
	if run.spend_gold(int(shop_relic.cost)):
		run.add_relic(str(shop_relic.name)); run.apply_relics(); shop_pending = false; message = "Bought %s." % shop_relic.name; SaveManager.save_run(run)
	else: message = "Not enough gold for %s." % shop_relic.name

func end_turn() -> void:
	if in_map or game_over or reward_pending or shop_pending: return
	var damage := 5 + (turn - 1) * 2 + max(0, run.floor - 1)
	if run.floor % 5 == 0: damage += 4
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
	if reward_pending: _draw_reward(); return
	if shop_pending: _draw_shop(); return
	if in_map: _draw_map(); return
	draw_circle(Vector2(250,200),55,Color("4d8bd6")); draw_string(ThemeDB.fallback_font,Vector2(205,206),"HERO",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_circle(Vector2(710,200),55,Color("b94a59")); draw_string(ThemeDB.fallback_font,Vector2(665,206),"BOSS" if run.floor % 5 == 0 else "ENEMY",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	_draw_bar(Vector2(145,275),run.player_hp,run.max_hp,"HP %d / %d" % [run.player_hp,run.max_hp])
	_draw_bar(Vector2(615,275),enemy_hp,enemy_max_hp,"HP %d / %d" % [enemy_hp,enemy_max_hp])
	draw_string(ThemeDB.fallback_font,Vector2(65,330),"TURN %d   ENERGY %d/%d" % [turn,energy,MAX_ENERGY],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f2d27b"))
	for i in hand.size(): _draw_card(i,hand[i])
	draw_string(ThemeDB.fallback_font,Vector2(65,500),"1-3 Card   E End Turn   M Map   R New Run",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("b8c5d2"))

func _draw_reward() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,190),"CHOOSE YOUR REWARD",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("f2d27b"))
	for i in reward_choices.size():
		var rect:=Rect2(90+i*270,230,240,150)
		draw_rect(rect,Color("394b5f"),true); draw_rect(rect,Color("7f95aa"),false,2.0)
		var data:=card_data(reward_choices[i])
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,35),"%d  %s"%[i+4,reward_choices[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,70),"Cost %d"%data.cost,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2d27b"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,105),"Damage %d"%data.damage,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c5d0dc"))

func _draw_shop() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,175),"SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("f2d27b"))
	for i in shop_cards.size():
		var rect:=Rect2(80+i*280,220,250,140)
		draw_rect(rect,Color("394b5f"),true); draw_rect(rect,Color("7f95aa"),false,2.0)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,35),"%d  %s"%[i+7,shop_cards[i].name],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,70),"Gold %d"%shop_cards[i].cost,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2d27b"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,105),"Damage %d"%shop_cards[i].damage,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c5d0dc"))
	var r:=Rect2(360,385,240,75)
	draw_rect(r,Color("394b5f"),true); draw_rect(r,Color("7f95aa"),false,2.0)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(15,30),"9  %s"%shop_relic.name,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(15,58),"Gold %d"%shop_relic.cost,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(100,490),"B: leave shop",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))

func _draw_map() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(110,190),"ADVENTURE MAP",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(110,235),"Battle → Reward → Shop → Boss",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font,Vector2(110,275),"Current floor: %d" % run.floor,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(110,320),"S: shop    B: battle",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b8c5d2"))

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
