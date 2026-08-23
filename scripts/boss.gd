extends Node2D

signal finished(result: String)
var run: RunData
var hp := 180
var max_hp := 180
var energy := 3
var hand: Array = []
var message := "The Guardian blocks your path."
var defeated := false
var defs := {"Strike":{"cost":1,"damage":15,"heal":0},"Fireball":{"cost":2,"damage":25,"heal":0},"Guard":{"cost":1,"damage":0,"heal":10},"Heavy Blow":{"cost":3,"damage":40,"heal":0}}

func setup(run_data: RunData) -> void:
	run = run_data
	hand = run.deck.duplicate()
	hand.shuffle()
	hand = hand.slice(0, min(3, hand.size()))
	queue_redraw()

func _input(event: InputEvent) -> void:
	if defeated: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: play(0)
			KEY_2: play(1)
			KEY_3: play(2)
			KEY_E: enemy_turn()

func play(index: int) -> void:
	if index >= hand.size(): return
	var name: String = hand[index]
	var d: Dictionary = defs.get(name, defs["Strike"])
	if int(d.cost) > energy:
		message = "Not enough energy."
		queue_redraw(); return
	energy -= int(d.cost)
	hp = max(0, hp - int(d.damage))
	run.heal(int(d.heal))
	hand.remove_at(index)
	message = "%s hits the Guardian." % name
	if hp <= 0:
		victory()
	queue_redraw()

func enemy_turn() -> void:
	if defeated: return
	run.take_damage(15)
	energy = 3
	if run.player_hp <= 0:
		message = "The Guardian defeats you."
		SaveManager.save_run(run)
		finished.emit("defeat")
		return
	hand = run.deck.duplicate()
	hand.shuffle()
	hand = hand.slice(0, min(3, hand.size()))
	message = "Guardian attacks for 15. Your turn."
	queue_redraw()

func victory() -> void:
	defeated = true
	run.add_gold(150)
	run.heal(20)
	run.relics.append("Guardian Core")
	run.floor += 1
	SaveManager.save_run(run)
	message = "BOSS DEFEATED! +150 gold, +20 HP, Guardian Core."

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("24171b"), true)
	draw_string(ThemeDB.fallback_font, Vector2(60,70), "THE GUARDIAN", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(60,110), message, HORIZONTAL_ALIGNMENT_LEFT, 820, 18, Color("d8e0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(650,70), "HP %d / %d" % [hp,max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ff8a8a"))
	draw_string(ThemeDB.fallback_font, Vector2(650,100), "YOUR HP %d" % run.player_hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("8ad7ff"))
	draw_circle(Vector2(480,210),80,Color("7d3944"))
	draw_string(ThemeDB.fallback_font,Vector2(430,218),"BOSS",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
	for i in hand.size():
		var d: Dictionary = defs.get(hand[i], defs["Strike"])
		var rect := Rect2(65 + i*285,350,255,115)
		draw_rect(rect,Color("394b5f"),true)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,32),"%d  %s"%[i+1,hand[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(15,65),"Cost %d   Damage %d"%[d.cost,d.damage],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f2d27b"))
	draw_string(ThemeDB.fallback_font,Vector2(65,500),"1-3 Card   E: enemy turn",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8c5d2"))
