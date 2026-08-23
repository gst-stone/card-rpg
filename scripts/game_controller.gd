extends Node2D

const MAP := 0
const BATTLE := 1
const SHOP := 2
const EVENT := 3
const REST := 4
const BOSS := 5
const REWARD := 6
const VICTORY := 7
const DEFEAT := 8

var state := MAP
var run: RunData
var message := "Choose your next node."
var map_rows: Array = []
var map_seed := 0
var current_enemy: Dictionary = {}
var enemy_hp := 60
var enemy_max_hp := 60
var enemy_block := 0
var enemy_intent := "Attack"
var energy := 3
var turn := 1
var hand: Array = []
var discard: Array = []
var draw_pile: Array = []
var reward_choices: Array = []
var shop_offers := [{"name":"Fireball","price":60},{"name":"Heavy Blow","price":80},{"name":"Heal","price":40},{"name":"Upgrade","price":90},{"name":"Remove","price":75}]
var event_done := false
var rest_done := false
var boss: Dictionary = {}
var boss_hp := 180
var boss_max_hp := 180
var boss_defeated := false
var status := StatusEffects.new()
var enemy_status := StatusEffects.new()
var deck_mode := ""
var deck_options: Array = []

func _ready() -> void:
	run = SaveManager.load_run()
	run.apply_relics()
	if run.current_node == "victory": state = VICTORY
	elif run.current_node == "defeat": state = DEFEAT
	else:
		map_seed = Time.get_unix_time_from_system()
		map_rows = MapGenerator.generate(run.floor, map_seed)
		state = MAP

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	var key := event.keycode
	if key == KEY_R: new_run(); return
	if state == SHOP and deck_mode != "":
		if key >= KEY_1 and key <= KEY_5: deck_action(key - KEY_1)
		elif key == KEY_B: deck_mode = ""; deck_options.clear(); message = "Back to shop."
		return
	match state:
		MAP: if key >= KEY_1 and key <= KEY_5: select_node_by_key(key - KEY_1)
		BATTLE:
			if key == KEY_1: play_card(0)
			elif key == KEY_2: play_card(1)
			elif key == KEY_3: play_card(2)
			elif key == KEY_E: end_turn()
		REWARD:
			if key == KEY_1: choose_reward(0)
			elif key == KEY_2: choose_reward(1)
			elif key == KEY_3: choose_reward(2)
			elif key == KEY_B: skip_reward()
		SHOP:
			if key >= KEY_1 and key <= KEY_5: buy(key - KEY_1)
			elif key == KEY_B: finish_node()
		EVENT:
			if not event_done and key == KEY_1: event_choice(1)
			elif not event_done and key == KEY_2: event_choice(2)
			elif event_done and key == KEY_B: finish_node()
		REST:
			if not rest_done and key == KEY_1: rest()
			elif key == KEY_B: finish_node()
		BOSS:
			if key == KEY_1: boss_play(0)
			elif key == KEY_2: boss_play(1)
			elif key == KEY_3: boss_play(2)
			elif key == KEY_E: boss_turn()
			elif boss_defeated and key == KEY_B: finish_run()

func new_run() -> void:
	run = RunData.new(); map_seed = Time.get_unix_time_from_system(); map_rows = MapGenerator.generate(run.floor, map_seed); SaveManager.save_run(run); state = MAP; message = "New run started."

func select_node_by_key(index: int) -> void:
	if map_rows.is_empty(): return
	var row := clamp(run.floor - 1, 0, map_rows.size() - 1); var nodes: Array = map_rows[row]
	if nodes.is_empty(): return
	select_node(str(nodes[index % nodes.size()].type))

func select_node(type: String) -> void:
	run.current_node = type; SaveManager.save_run(run)
	match type:
		"battle": start_battle(false)
		"elite": start_battle(true)
		"shop": state = SHOP; message = "1 Fireball 60g | 2 Heavy Blow 80g | 3 Heal 40g | 4 Upgrade 90g | 5 Remove 75g"
		"event": state = EVENT; event_done = false; message = "A mysterious shrine awaits."
		"rest": state = REST; rest_done = false; message = "Take a rest."
		"boss": start_boss()

func start_battle(elite: bool) -> void:
	state = BATTLE; current_enemy = EnemyCatalog.create_enemy(run.floor, elite); enemy_max_hp = int(current_enemy.max_hp); enemy_hp = enemy_max_hp; enemy_block = 0; enemy_intent = str(current_enemy.intent); energy = 3; turn = 1; status = StatusEffects.new(); enemy_status = StatusEffects.new(); hand.clear(); discard.clear(); draw_pile = run.deck.duplicate(); draw_pile.shuffle(); draw_cards(3); message = "%s — Intent: %s" % [current_enemy.name, enemy_intent]

func card_data(name: String) -> Dictionary: return CardCatalog.get_card(name)

func draw_cards(n: int) -> void:
	for _i in n:
		if draw_pile.is_empty(): draw_pile = discard.duplicate(); discard.clear(); draw_pile.shuffle()
		if draw_pile.is_empty(): return
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> void:
	if index < 0 or index >= hand.size(): return
	var name: String = hand[index]; var d := card_data(name)
	if int(d.cost) > energy: message = "Not enough energy."; return
	var effect := CombatEffects.apply_card(d, current_enemy, run, run.relics, energy); energy = int(effect.energy)
	var damage := int(effect.damage)
	if status.weak > 0: damage = int(floor(damage * 0.75))
	if enemy_status.vulnerable > 0: damage = int(ceil(damage * 1.25))
	var blocked := min(enemy_block, damage); enemy_block -= blocked; damage -= blocked
	enemy_hp = max(0, enemy_hp - damage); status.player_block += int(effect.block); run.heal(int(effect.heal)); discard.append(hand.pop_at(index))
	message = "%s deals %d." % [name, damage] if damage > 0 else "%s played." % name
	if enemy_hp <= 0: battle_victory()

func enemy_action() -> void:
	var action := EnemyCatalog.action_for(current_enemy, turn); var damage := int(current_enemy.damage)
	match action:
		"heavy": damage += 10
		"guard": enemy_block += 12
		"weak": status.weak = max(status.weak, 2)
		"vulnerable": status.vulnerable = max(status.vulnerable, 2)
		"poison": status.poison += 3
		"attack": pass
	var remaining := status.absorb(damage); run.take_damage(remaining); enemy_intent = str(EnemyCatalog.action_for(current_enemy, turn + 1)).to_upper(); message = "%s uses %s — %d damage." % [current_enemy.name, str(action).to_upper(), remaining]

func end_turn() -> void:
	if status.poison > 0:
		run.take_damage(status.poison)
		message = "Poison deals %d damage." % status.poison
	if run.player_hp <= 0: lose_run(); return
	enemy_action()
	status.tick()
	if run.player_hp <= 0: lose_run(); return
	for c in hand: discard.append(c)
	hand.clear(); turn += 1; energy = 3; status.start_turn(); draw_cards(3); SaveManager.save_run(run)

func battle_victory() -> void:
	run.add_gold(RelicCatalog.gold_reward(run.relics, RewardGenerator.gold(run.floor, current_enemy.name == "Elite Knight"))); run.heal(12); reward_choices = RewardGenerator.card_choices(run.floor); state = REWARD; message = "Victory! Choose one card."; SaveManager.save_run(run)
func choose_reward(index: int) -> void:
	if index < 0 or index >= reward_choices.size(): return
	run.add_card(str(reward_choices[index])); run.floor += 1; finish_node()
func skip_reward() -> void: run.floor += 1; finish_node()

func buy(index: int) -> void:
	if index < 0 or index >= shop_offers.size(): return
	var offer = shop_offers[index]
	if offer.name == "Upgrade" or offer.name == "Remove": deck_mode = "upgrade" if offer.name == "Upgrade" else "remove"; deck_options = run.deck.duplicate(); message = "Choose card 1-5. B cancel."; return
	if not run.spend_gold(int(offer.price)): message = "Not enough gold."; return
	if offer.name == "Heal": run.heal(25)
	else: run.add_card(offer.name)
	SaveManager.save_run(run); message = "Purchased %s." % offer.name

func deck_action(index: int) -> void:
	if index < 0 or index >= deck_options.size(): return
	var card_name: String = str(deck_options[index]); var price := 90 if deck_mode == "upgrade" else 75
	if not run.spend_gold(price): message = "Not enough gold."; return
	if deck_mode == "upgrade":
		if DeckManager.upgrade_card(run.deck, card_name): message = "%s upgraded!" % card_name
		else: run.add_gold(price); message = "This card cannot be upgraded."
	else:
		if run.deck.size() <= 1: run.add_gold(price); message = "Keep at least one card."
		elif DeckManager.remove_card(run.deck, card_name): message = "%s removed." % card_name
	deck_mode = ""; deck_options.clear(); SaveManager.save_run(run)

func event_choice(option: int) -> void:
	if option == 1: run.heal(20); message = "The shrine heals 20 HP."
	else: run.take_damage(8); run.add_gold(60); message = "You lose 8 HP and gain 60 gold."
	event_done = true; SaveManager.save_run(run)
func rest() -> void:
	if rest_done: return
	run.heal(30); rest_done = true; SaveManager.save_run(run); message = "Restored 30 HP."

func start_boss() -> void:
	state = BOSS; boss = BossCatalog.create_boss(run.floor); boss_hp = int(boss.hp); boss_max_hp = boss_hp; boss_defeated = false; energy = 3; turn = 1; status = StatusEffects.new(); hand = run.deck.duplicate(); hand.shuffle(); hand = hand.slice(0, min(3, hand.size())); message = "%s appears — %s" % [boss.name, str(boss.pattern[0]).to_upper()]
func boss_phase_two() -> bool: return boss_hp <= int(boss_max_hp * 0.5)

func boss_play(index: int) -> void:
	if boss_defeated or index < 0 or index >= hand.size(): return
	var d := card_data(hand[index]); if int(d.cost) > energy: message = "Not enough energy."; return
	var effect := CombatEffects.apply_card(d, boss, run, run.relics, energy); energy = int(effect.energy); var damage := int(effect.damage); if status.weak > 0: damage = int(floor(damage * 0.75)); if boss_phase_two(): damage = int(ceil(damage * 1.1)); boss_hp = max(0, boss_hp - damage); status.player_block += int(effect.block); run.heal(int(effect.heal)); hand.remove_at(index)
	if boss_hp <= 0: boss_defeated = true; run.add_gold(150); run.heal(20); run.add_relic("Guardian Core"); run.current_node = "victory"; SaveManager.save_run(run); message = "%s defeated! Press B." % boss.name

func boss_turn() -> void:
	if boss_defeated: return
	var action: String = str(boss.pattern[(turn - 1) % boss.pattern.size()]); var damage := int(boss.damage)
	if boss_phase_two(): damage += 8
	if action == "heavy": damage += 10
	if action == "weak": status.weak = 2
	if action == "poison": status.poison += 4
	if status.poison > 0: run.take_damage(status.poison)
	if run.player_hp <= 0: lose_run(); return
	var remaining := status.absorb(damage); run.take_damage(remaining); energy = 3; hand = run.deck.duplicate(); hand.shuffle(); hand = hand.slice(0, min(3, hand.size())); turn += 1
	if run.player_hp <= 0: lose_run(); return
	SaveManager.save_run(run); message = "%s uses %s for %d.%s" % [boss.name, action.to_upper(), remaining, " PHASE 2" if boss_phase_two() else ""]
func finish_run() -> void: state = VICTORY; run.current_node = "victory"; SaveManager.save_run(run)
func finish_node() -> void: map_rows = MapGenerator.generate(run.floor, map_seed + run.floor * 97); state = MAP; run.current_node = "map"; SaveManager.save_run(run); message = "Choose your next node."
func lose_run() -> void: state = DEFEAT; run.current_node = "defeat"; SaveManager.save_run(run); message = "Run defeated. Press R."

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("111820"),true); draw_rect(Rect2(40,30,880,480),Color("263342"),true); draw_string(ThemeDB.fallback_font,Vector2(65,75),"CARD RPG",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("f2d27b")); draw_string(ThemeDB.fallback_font,Vector2(65,110),message,HORIZONTAL_ALIGNMENT_LEFT,820,18,Color("d8e0e8"))
	match state:
		MAP: draw_map()
		BATTLE: draw_battle()
		REWARD: draw_reward()
		SHOP: draw_shop()
		EVENT: draw_center("SHRINE","1 Pray +20 HP   2 Search -8 HP +60g\nB Return")
		REST: draw_center("REST","1 Rest +30 HP\nHP: %d/%d\nB Return"%[run.player_hp,run.max_hp])
		BOSS: draw_boss()
		VICTORY: draw_center("VICTORY","Run complete! Press R.")
		DEFEAT: draw_center("DEFEAT","Run failed. Press R.")
func draw_map() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,180),"FLOOR %d — CHOOSE A NODE"%run.floor,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("f2d27b")); var nodes:=map_rows[min(run.floor-1,map_rows.size()-1)] if not map_rows.is_empty() else []
	for i in nodes.size(): draw_string(ThemeDB.fallback_font,Vector2(110+i*250,260),"%d  %s"%[i+1,str(nodes[i].type).to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(110,390),"HP %d/%d   Gold %d   Deck %d   Relics %d"%[run.player_hp,run.max_hp,run.gold,run.deck.size(),run.relics.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b8c5d2")); draw_string(ThemeDB.fallback_font,Vector2(110,440),"1-5 Choose node   R New Run",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("b8c5d2"))
func draw_battle() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,170),"%s  %d/%d"%[current_enemy.name,enemy_hp,enemy_max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("ff8a8a")); draw_string(ThemeDB.fallback_font,Vector2(100,205),"Intent: %s"%enemy_intent,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffcc80")); draw_string(ThemeDB.fallback_font,Vector2(100,235),"HP %d/%d  Energy %d  Block %d"%[run.player_hp,run.max_hp,energy,status.player_block],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE); draw_string(ThemeDB.fallback_font,Vector2(100,265),"Weak %d  Vulnerable %d  Poison %d"%[status.weak,status.vulnerable,status.poison],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c5d0dc"))
	for i in hand.size(): draw_card(i,hand[i])
	draw_string(ThemeDB.fallback_font,Vector2(100,480),"1-3 Play   E End Turn",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))
func draw_reward() -> void: draw_center("REWARD","1 %s    2 %s    3 %s\nChoose one card, or B to skip."%[reward_choices[0],reward_choices[1],reward_choices[2]])
func draw_shop() -> void:
	if deck_mode != "": draw_center("DECK %s"%deck_mode.to_upper(),"1-5 choose a card\n"+" | ".join(deck_options)+"\nB cancel")
	else: draw_center("SHOP","1 Fireball 60g   2 Heavy Blow 80g   3 Heal 40g\n4 Upgrade 90g   5 Remove 75g\nGold: %d\nB Return"%run.gold)
func draw_card(i:int,name:String) -> void:
	var d:=card_data(name); var r:=Rect2(70+i*280,300,250,115); draw_rect(r,Color("394b5f"),true); draw_string(ThemeDB.fallback_font,r.position+Vector2(15,32),"%d %s"%[i+1,name],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE); draw_string(ThemeDB.fallback_font,r.position+Vector2(15,68),"Cost %d  Dmg %d  Heal %d  Block %d"%[d.cost,d.damage,d.heal,d.block],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f2d27b"))
func draw_boss() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,175),"%s  %d/%d"%[boss.name,boss_hp,boss_max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("ff8a8a")); draw_string(ThemeDB.fallback_font,Vector2(100,210),"Next: %s"%str(boss.pattern[(turn-1)%boss.pattern.size()]).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffcc80")); draw_string(ThemeDB.fallback_font,Vector2(100,240),"HP %d/%d Energy %d Block %d"%[run.player_hp,run.max_hp,energy,status.player_block],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE); draw_string(ThemeDB.fallback_font,Vector2(100,268),"Phase 2: %s  Weak %d Poison %d"%["YES" if boss_phase_two() else "NO",status.weak,status.poison],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c5d0dc"))
	for i in hand.size(): draw_card(i,hand[i])
	draw_string(ThemeDB.fallback_font,Vector2(100,480),"1-3 Play   E Boss Turn   B Victory",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))
func draw_center(title:String,text:String) -> void: draw_string(ThemeDB.fallback_font,Vector2(100,185),title,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("f2d27b")); draw_string(ThemeDB.fallback_font,Vector2(100,250),text,HORIZONTAL_ALIGNMENT_LEFT,750,20,Color.WHITE)
