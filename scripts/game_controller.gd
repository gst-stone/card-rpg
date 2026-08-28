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
var hovered_card := -1
var last_played := ""
var last_damage := 0
var feedback_time := 0.0
var enemy_flash := 0.0
var enemy_hit_text := ""
var enemy_hit_time := 0.0
var player_attack_flash := 0.0
var player_bob := 0.0
var projectile_active := false
var projectile_pos := Vector2.ZERO
var projectile_target := Vector2.ZERO
var projectile_kind := ""
var projectile_time := 0.0
var projectile_duration := 0.35

func _ready() -> void:
	run = SaveManager.load_run()
	run.apply_relics()
	if run.current_node == "victory": state = VICTORY
	elif run.current_node == "defeat": state = DEFEAT
	else:
		map_seed = Time.get_unix_time_from_system()
		map_rows = MapGenerator.generate(run.floor, map_seed)
		state = MAP

func _process(delta: float) -> void:
	feedback_time = max(0.0, feedback_time - delta)
	enemy_flash = max(0.0, enemy_flash - delta)
	enemy_hit_time = max(0.0, enemy_hit_time - delta)
	player_attack_flash = max(0.0, player_attack_flash - delta)
	player_bob += delta
	if projectile_active:
		projectile_time += delta
		var t := clamp(projectile_time / projectile_duration, 0.0, 1.0)
		projectile_pos = projectile_pos.lerp(projectile_target, min(1.0, delta * 8.0))
		if t >= 1.0:
			projectile_active = false
	queue_redraw()

func card_rect(index: int, total: int) -> Rect2:
	var width := 150.0
	var height := 190.0
	var gap := 12.0
	var total_width := total * width + max(0, total - 1) * gap
	var start_x := 480.0 - total_width / 2.0
	return Rect2(start_x + index * (width + gap), 285, width, height)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and state == BATTLE:
		hovered_card = -1
		for i in min(5, hand.size()):
			if card_rect(i, min(5, hand.size())).has_point(event.position):
				hovered_card = i
				break
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := event.position
		if state == BOSS:
			for i in min(5, hand.size()):
				if card_rect(i, min(5, hand.size())).has_point(p):
					boss_play(i)
					return
			if Rect2(760, 435, 130, 45).has_point(p):
				boss_turn()
				return
			if boss_defeated and Rect2(390, 430, 180, 50).has_point(p):
				finish_run()
				return
		if state == BATTLE:
			for i in min(5, hand.size()):
				if card_rect(i, min(5, hand.size())).has_point(p):
					play_card(i)
					return
			if Rect2(760, 435, 130, 45).has_point(p):
				end_turn()
				return
		elif state == REWARD:
			for i in reward_choices.size():
				var rect := Rect2(100 + i * 270, 210, 240, 170)
				if rect.has_point(p):
					choose_reward(i)
					return
		elif state == MAP:
			var row := clamp(run.floor - 1, 0, max(0, map_rows.size() - 1))
			var nodes: Array = map_rows[row] if not map_rows.is_empty() else []
			for i in nodes.size():
				var rect := Rect2(85 + i * 170, 220, 145, 80)
				if rect.has_point(p):
					select_node(str(nodes[i].type))
					return
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
			if key >= KEY_1 and key <= KEY_5: play_card(key - KEY_1)
			elif key == KEY_E: end_turn()
		REWARD:
			if key >= KEY_1 and key <= KEY_3: choose_reward(key - KEY_1)
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
			if key >= KEY_1 and key <= KEY_5: boss_play(key - KEY_1)
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
	state = BATTLE; current_enemy = EnemyCatalog.create_enemy(run.floor, elite); enemy_max_hp = int(current_enemy.max_hp); enemy_hp = enemy_max_hp; enemy_block = 0; enemy_intent = str(current_enemy.intent); energy = 3; turn = 1; status = StatusEffects.new(); enemy_status = StatusEffects.new(); hand.clear(); discard.clear(); draw_pile = run.deck.duplicate(); draw_pile.shuffle(); draw_cards(5); message = "%s — Intent: %s" % [current_enemy.name, enemy_intent]

func card_data(name: String) -> Dictionary: return CardCatalog.get_card(name)

func draw_cards(n: int) -> void:
	for _i in n:
		if draw_pile.is_empty(): draw_pile = discard.duplicate(); discard.clear(); draw_pile.shuffle()
		if draw_pile.is_empty(): return
		hand.append(draw_pile.pop_back())

func play_card(index: int) -> void:
	if index < 0 or index >= hand.size(): return
	var name: String = hand[index]; var d := card_data(name)
	if d.is_empty(): hand.remove_at(index); return
	if int(d.cost) > energy: message = "Not enough energy."; return
	var effect := CombatEffects.apply_card(d, current_enemy, run, run.relics, energy); energy = int(effect.energy)
	var damage := int(effect.damage)
	if status.weak > 0: damage = int(floor(damage * 0.75))
	if enemy_status.vulnerable > 0: damage = int(ceil(damage * 1.25))
	var blocked := min(enemy_block, damage); enemy_block -= blocked; damage -= blocked
	enemy_hp = max(0, enemy_hp - damage)
	last_played = name
	last_damage = damage
	feedback_time = 0.75
	if damage > 0:
		if name == "Fireball" or name == "Fireball+":
			projectile_active = true
			projectile_kind = "fireball"
			projectile_pos = Vector2(700, 285)
			projectile_target = Vector2(285, 305)
			projectile_time = 0.0
			projectile_duration = 0.42
		elif name == "Ice Lance" or name == "Ice Lance+":
			projectile_active = true
			projectile_kind = "ice"
			projectile_pos = Vector2(700, 285)
			projectile_target = Vector2(285, 305)
			projectile_time = 0.0
			projectile_duration = 0.32
		enemy_flash = 0.22
		player_attack_flash = 0.16
		enemy_hit_text = "-%d" % damage
		enemy_hit_time = 0.65
	enemy_status.vulnerable = max(enemy_status.vulnerable, int(effect.get("vulnerable", 0)))
	enemy_status.weak = max(enemy_status.weak, int(effect.get("weak", 0)))
	enemy_status.poison += int(effect.get("poison", 0))
	status.player_block += int(effect.block)
	run.heal(int(effect.heal))
	discard.append(hand.pop_at(index))
	if int(effect.draw) > 0: draw_cards(int(effect.draw))
	message = "%s deals %d." % [name, damage] if damage > 0 else "%s played." % name
	if enemy_hp <= 0: battle_victory()

func enemy_action() -> void:
	if enemy_status.poison > 0:
		enemy_hp = max(0, enemy_hp - enemy_status.poison)
		message = "%s suffers %d poison." % [current_enemy.name, enemy_status.poison]
		if enemy_hp <= 0:
			battle_victory()
			return
	var action := EnemyCatalog.action_for(current_enemy, turn)
	var damage := CombatEffects.enemy_phase_damage(EnemyCatalog.intent_damage(current_enemy, turn), enemy_status)
	match action:
		"guard": enemy_block += 12
		"weak": status.weak = max(status.weak, 2)
		"poison": status.poison += 3
		"attack", "heavy": pass
	var remaining := status.absorb(damage); run.take_damage(remaining); enemy_intent = EnemyCatalog.next_intent(current_enemy, turn + 1)
	enemy_status.tick()
	message = "%s uses %s — %d damage." % [current_enemy.name, str(action).to_upper(), remaining]

func end_turn() -> void:
	if status.poison > 0: run.take_damage(status.poison)
	if run.player_hp <= 0: lose_run(); return
	enemy_action()
	status.tick()
	if run.player_hp <= 0: lose_run(); return
	for c in hand: discard.append(c)
	hand.clear(); status.player_block = 0; turn += 1; energy = 3; status.start_turn(); draw_cards(5); SaveManager.save_run(run)

func battle_victory() -> void:
	run.add_gold(RelicCatalog.gold_reward(run.relics, RewardGenerator.gold(run.floor, current_enemy.name == "Elite Knight"))); run.heal(12); reward_choices = RewardGenerator.card_choices(run.floor); state = REWARD; message = "Victory! Choose one card."
	if current_enemy.name == "Elite Knight":
		var relic := RelicCatalog.random_reward(run.relics, run.floor * 7919 + turn); run.add_relic(relic); message = "Elite defeated! Gained %s. Choose a card." % relic
	SaveManager.save_run(run)
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
	state = BOSS; boss = BossCatalog.create_boss(run.floor); boss_hp = int(boss.hp); boss_max_hp = boss_hp; boss_defeated = false; energy = 3; turn = 1; status = StatusEffects.new(); hand = run.deck.duplicate(); hand.shuffle(); hand = hand.slice(0, min(5, hand.size())); message = "%s appears — %s" % [boss.name, str(boss.pattern[0]).to_upper()]
func boss_phase_two() -> bool: return boss_hp <= int(boss_max_hp * 0.5)

func boss_play(index: int) -> void:
	if boss_defeated or index < 0 or index >= hand.size(): return
	var d := card_data(hand[index]); if d.is_empty(): hand.remove_at(index); return
	if int(d.cost) > energy: message = "Not enough energy."; return
	var effect := CombatEffects.apply_card(d, boss, run, run.relics, energy); energy = int(effect.energy); var damage := int(effect.damage); if status.weak > 0: damage = int(floor(damage * 0.75)); if boss_phase_two(): damage = int(ceil(damage * 1.1)); boss_hp = max(0, boss_hp - damage); status.player_block += int(effect.block); run.heal(int(effect.heal)); hand.remove_at(index)
	if boss_hp <= 0: boss_defeated = true; run.add_gold(150); run.heal(20); run.add_relic("Guardian Core"); run.current_node = "victory"; SaveManager.save_run(run); message = "%s defeated! Press B." % boss.name

func boss_turn() -> void:
	if boss_defeated: return
	var action: String = BossCatalog.action_for(boss, turn, boss_hp); var damage := BossCatalog.action_damage(boss, action, boss_hp)
	if action == "weak": status.weak = 2
	if action == "poison": status.poison += 4
	if status.poison > 0: run.take_damage(status.poison)
	if run.player_hp <= 0: lose_run(); return
	var remaining := status.absorb(damage); run.take_damage(remaining); status.player_block = 0; energy = 3; hand = run.deck.duplicate(); hand.shuffle(); hand = hand.slice(0, min(5, hand.size())); turn += 1
	if run.player_hp <= 0: lose_run(); return
	SaveManager.save_run(run); message = "%s uses %s for %d.%s" % [boss.name, action.to_upper(), remaining, " PHASE 2" if boss_phase_two() else ""]
func finish_run() -> void: state = VICTORY; run.current_node = "victory"; SaveManager.save_run(run)
func finish_node() -> void: map_rows = MapGenerator.generate(run.floor, map_seed + run.floor * 97); state = MAP; run.current_node = "map"; SaveManager.save_run(run); message = "Choose your next node."
func lose_run() -> void: state = DEFEAT; run.current_node = "defeat"; SaveManager.save_run(run); message = "Run defeated. Press R."

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("0c1118"),true)
	# layered background and frame
	draw_circle(Vector2(120,120),180,Color("172433"),true)
	draw_circle(Vector2(850,90),150,Color("201b32"),true)
	draw_rect(Rect2(32,24,896,492),Color("141e29"),true)
	draw_rect(Rect2(40,30,880,480),VisualTheme.panel(),true)
	draw_rect(Rect2(40,30,880,480),Color("6c7f94"),false,2.0)
	draw_string(ThemeDB.fallback_font,Vector2(65,75),"CARD RPG",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("f2d27b")); draw_string(ThemeDB.fallback_font,Vector2(65,110),message,HORIZONTAL_ALIGNMENT_LEFT,820,18,Color("d8e0e8"))
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
	draw_string(ThemeDB.fallback_font, Vector2(100, 165), "FLOOR %d — CHOOSE A NODE" % run.floor, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("f2d27b"))
	var nodes := map_rows[min(run.floor - 1, map_rows.size() - 1)] if not map_rows.is_empty() else []
	for i in nodes.size():
		var rect := Rect2(85 + i * 170, 220, 145, 80)
		draw_rect(rect, Color("35495e"), true)
		draw_rect(rect, Color("7f95aa"), false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 32), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 129, 16, Color("f2d27b"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 62), str(nodes[i].type).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 129, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(110, 390), "HP %d/%d   Gold %d   Deck %d   Relics %d" % [run.player_hp, run.max_hp, run.gold, run.deck.size(), run.relics.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8c5d2"))
	draw_string(ThemeDB.fallback_font, Vector2(110, 440), "Click a node to continue. Keyboard 1-5 also works.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b8c5d2"))

func draw_battle() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(100, 165), "%s" % current_enemy.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("ff8a8a"))
	draw_string(ThemeDB.fallback_font, Vector2(100, 195), "HP %d/%d    Block %d" % [enemy_hp, enemy_max_hp, enemy_block], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(100, 225), "Intent: %s   VULN %d   WEAK %d   POISON %d" % [enemy_intent, enemy_status.vulnerable, enemy_status.weak, enemy_status.poison], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f0c674"))
	draw_string(ThemeDB.fallback_font, Vector2(650, 165), "HERO HP %d/%d" % [run.player_hp, run.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("8fd3ff"))
	draw_string(ThemeDB.fallback_font, Vector2(650, 195), "Energy %d/3   Block %d" % [energy, status.player_block], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2d27b"))

	# Character art layer (procedural now, replaceable by Sprite2D assets later)
	var enemy_center := Vector2(250, 305)
	CharacterArt.draw_enemy(self, enemy_center, enemy_flash, current_enemy.name == "Elite Knight")

	var hero_center := Vector2(760, 305)
	CharacterArt.draw_hero(self, hero_center, player_attack_flash, player_bob)
	if player_attack_flash > 0.0:
		draw_line(hero_center + Vector2(-30, -35), hero_center + Vector2(70, -65), Color("f2d27b"), 5.0)
	draw_string(ThemeDB.fallback_font, hero_center + Vector2(-60, 72), "HERO", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color("8fd3ff"))

	if projectile_active:
		if projectile_kind == "fireball":
			draw_circle(projectile_pos, 15, Color("ff7a45"))
			draw_circle(projectile_pos, 8, Color("ffe08a"))
			draw_circle(projectile_pos + Vector2(-18, 8), 7, Color(1.0, 0.28, 0.08, 0.55))
		elif projectile_kind == "ice":
			var points := PackedVector2Array([
				projectile_pos + Vector2(18, 0),
				projectile_pos + Vector2(-12, -10),
				projectile_pos + Vector2(-12, 10)
			])
			draw_colored_polygon(points, Color("8fd3ff"))
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color.WHITE, 2.0)

	if enemy_hit_time > 0.0:
		var hit_alpha := clamp(enemy_hit_time / 0.65, 0.0, 1.0)
		var hit_y := enemy_center.y - 55.0 - (1.0 - hit_alpha) * 30.0
		draw_string(ThemeDB.fallback_font, Vector2(enemy_center.x - 40, hit_y), enemy_hit_text, HORIZONTAL_ALIGNMENT_CENTER, 80, 28, Color(1.0, 0.85, 0.3, hit_alpha))

	# Enemy HP bar
	var enemy_bar := Rect2(100, 370, 300, 18)
	draw_rect(enemy_bar, Color("3a2024"), true)
	var enemy_ratio := float(enemy_hp) / float(max(1, enemy_max_hp))
	draw_rect(Rect2(enemy_bar.position, Vector2(enemy_bar.size.x * enemy_ratio, enemy_bar.size.y)), Color("d95763") if enemy_flash <= 0.0 else Color.WHITE, true)
	draw_rect(enemy_bar, Color("f0c674"), false, 2.0)

	# Player HP bar
	var hero_bar := Rect2(650, 370, 220, 16)
	draw_rect(hero_bar, Color("20303b"), true)
	var hero_ratio := float(run.player_hp) / float(max(1, run.max_hp))
	draw_rect(Rect2(hero_bar.position, Vector2(hero_bar.size.x * hero_ratio, hero_bar.size.y)), Color("57a8d9"), true)
	draw_rect(hero_bar, Color("8fd3ff"), false, 2.0)

	if feedback_time > 0.0 and last_played != "":
		var alpha := clamp(feedback_time / 0.75, 0.0, 1.0)
		var y := 245.0 - (1.0 - alpha) * 30.0
		var text := "%s" % last_played
		if last_damage > 0: text += "  -%d" % last_damage
		draw_string(ThemeDB.fallback_font, Vector2(390, y), text, HORIZONTAL_ALIGNMENT_CENTER, 180, 22, Color(1.0, 0.9, 0.45, alpha))

	for i in min(5, hand.size()):
		var d := card_data(hand[i])
		var rect := card_rect(i, min(5, hand.size()))
		if i == hovered_card:
			rect.position.y -= 14.0
		var affordable := int(d.cost) <= energy
		var card_type := str(d.get("type", "attack"))
		var type_color := Color("c75b5b") if card_type == "attack" else Color("5b8fc7")
		if card_type == "power": type_color = Color("a06bc7")
		if card_type == "status": type_color = Color("6fa86f")
		var fill := type_color.darkened(0.55) if affordable else Color("292d35")
		draw_rect(rect, fill, true)
		draw_rect(rect, type_color if affordable else Color("68717d"), false, 3.0)
		var icon := "⚔" if card_type == "attack" else "✦"
		if card_type == "power": icon = "★"
		if card_type == "status": icon = "☠"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 26), icon + " " + card_type.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, type_color.lightened(0.25))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 52), str(hand[i]), HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 24), 18, Color.WHITE)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 78), "COST %d" % int(d.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2d27b"))
		draw_multiline_string(ThemeDB.fallback_font, rect.position + Vector2(12, 104), str(d.description), HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 24), 14, 4, Color("d8e0e8"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 174), "CLICK TO PLAY", HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 24), 12, Color("8fd3ff"))

	var end_rect := Rect2(760, 435, 130, 45)
	draw_rect(end_rect, Color("6b4f2b"), true)
	draw_rect(end_rect, Color("f2d27b"), false, 2.0)
	draw_string(ThemeDB.fallback_font, end_rect.position + Vector2(8, 29), "END TURN", HORIZONTAL_ALIGNMENT_CENTER, 114, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(100, 500), "Click a card to play. Keyboard 1-5 and E still work.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b8c5d2"))

func draw_reward() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(100,180),"CHOOSE A CARD",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("f2d27b")); for i in reward_choices.size(): var d:=card_data(reward_choices[i]); draw_string(ThemeDB.fallback_font,Vector2(100,240+i*70),"%d  %s — Cost %d — %s"%[i+1,reward_choices[i],int(d.cost),str(d.description)],HORIZONTAL_ALIGNMENT_LEFT,750,18,Color.WHITE); draw_string(ThemeDB.fallback_font,Vector2(100,460),"B Skip",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))
func draw_shop() -> void: draw_center("SHOP","1 Fireball 60g   2 Heavy Blow 80g   3 Heal 40g\n4 Upgrade 90g   5 Remove 75g\nGold: %d   B Leave"%run.gold)
func draw_center(title: String, body: String) -> void: draw_string(ThemeDB.fallback_font,Vector2(100,200),title,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("f2d27b")); draw_multiline_string(ThemeDB.fallback_font,Vector2(100,260),body,HORIZONTAL_ALIGNMENT_LEFT,760,20,8,Color.WHITE)
func draw_boss() -> void:
	var phase := 2 if boss_phase_two() else 1
	draw_string(ThemeDB.fallback_font, Vector2(100, 160), "BOSS — %s" % boss.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("e98b9a"))
	draw_string(ThemeDB.fallback_font, Vector2(100, 195), "PHASE %d    HP %d/%d" % [phase, boss_hp, boss_max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(650, 165), "HERO HP %d/%d" % [run.player_hp, run.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("8fd3ff"))
	draw_string(ThemeDB.fallback_font, Vector2(650, 195), "Energy %d/3   Block %d" % [energy, status.player_block], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2d27b"))
	var boss_center := Vector2(250, 305)
	draw_circle(boss_center, 58, Color("8f3d58") if phase == 1 else Color("c04a4a"))
	draw_circle(boss_center + Vector2(-18,-8), 7, Color("17131a"))
	draw_circle(boss_center + Vector2(18,-8), 7, Color("17131a"))
	draw_arc(boss_center + Vector2(0,12), 24, 0.1, 3.04, 24, Color("17131a"), 4.0)
	draw_string(ThemeDB.fallback_font, boss_center + Vector2(-70, 88), "BOSS", HORIZONTAL_ALIGNMENT_CENTER, 140, 16, Color("ffb4c0"))
	var boss_bar := Rect2(100, 385, 300, 20)
	draw_rect(boss_bar, Color("351b25"), true)
	var ratio := float(boss_hp) / float(max(1, boss_max_hp))
	draw_rect(Rect2(boss_bar.position, Vector2(boss_bar.size.x * ratio, boss_bar.size.y)), Color("d95763"), true)
	draw_rect(boss_bar, Color("f0c674"), false, 2.0)
	if boss_defeated:
		var victory_rect := Rect2(390, 430, 180, 50)
		draw_rect(victory_rect, Color("4b6f4b"), true)
		draw_rect(victory_rect, Color("a9d18e"), false, 2.0)
		draw_string(ThemeDB.fallback_font, victory_rect.position + Vector2(8,32), "FINISH RUN", HORIZONTAL_ALIGNMENT_CENTER, 164, 17, Color.WHITE)
		return
	for i in min(5, hand.size()):
		var d := card_data(hand[i])
		var rect := card_rect(i, min(5, hand.size()))
		var affordable := int(d.cost) <= energy
		var card_type := str(d.get("type", "attack"))
		var type_color := Color("c75b5b") if card_type == "attack" else Color("5b8fc7")
		if card_type == "power": type_color = Color("a06bc7")
		if card_type == "status": type_color = Color("6fa86f")
		draw_rect(rect, type_color.darkened(0.55) if affordable else Color("292d35"), true)
		draw_rect(rect, type_color if affordable else Color("68717d"), false, 3.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 30), str(hand[i]), HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 24), 18, Color.WHITE)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 58), "COST %d" % int(d.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2d27b"))
		draw_multiline_string(ThemeDB.fallback_font, rect.position + Vector2(12, 88), str(d.description), HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 24), 14, 4, Color("d8e0e8"))
	var end_rect := Rect2(760, 435, 130, 45)
	draw_rect(end_rect, Color("6b4f2b"), true)
	draw_rect(end_rect, Color("f2d27b"), false, 2.0)
	draw_string(ThemeDB.fallback_font, end_rect.position + Vector2(8,29), "BOSS TURN", HORIZONTAL_ALIGNMENT_CENTER, 114, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(100, 500), "Click cards to attack. Click BOSS TURN to continue.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b8c5d2"))
