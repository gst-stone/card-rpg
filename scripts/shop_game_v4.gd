extends Node2D

# My Little Shop v0.4 - physical store layout, shelves and moving customers.
const PRODUCTS := [
	{"name":"Water","cost":2,"price":4,"unlock":1,"pref":"daily"},
	{"name":"Bread","cost":3,"price":6,"unlock":1,"pref":"daily"},
	{"name":"Apple","cost":4,"price":8,"unlock":1,"pref":"healthy"},
	{"name":"Drink","cost":5,"price":10,"unlock":2,"pref":"snack"},
	{"name":"Noodles","cost":6,"price":12,"unlock":2,"pref":"quick"},
	{"name":"Milk","cost":8,"price":16,"unlock":3,"pref":"healthy"},
	{"name":"Cookie","cost":10,"price":20,"unlock":4,"pref":"snack"},
	{"name":"Hotpot","cost":20,"price":40,"unlock":5,"pref":"quick"}
]
const CUSTOMER_TYPES := [
	{"name":"Worker","icon":"W","pref":"quick","budget":18,"patience":8.0},
	{"name":"Parent","icon":"P","pref":"healthy","budget":22,"patience":9.0},
	{"name":"Student","icon":"S","pref":"snack","budget":14,"patience":7.0},
	{"name":"Neighbor","icon":"N","pref":"daily","budget":12,"patience":8.5}
]

var gold := 100
var level := 1
var xp := 0
var day := 1
var stock: Array[int] = [6,6,6,0,0,0,0,0]
var shelf_limit := 24
var waiting: Array[Dictionary] = []
var served := 0
var lost := 0
var revenue := 0
var demand := 1.0
var price_factor := 1.0
var open := false
var spawn_timer := 0.0
var sale_timer := 0.0
var message := "Stock the shelves, then open the shop."
var reputation := 50
var shelf_count := 3
var customer_seq := 0

func _ready() -> void:
	randomize()
	queue_redraw()

func _process(delta: float) -> void:
	if open:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = max(1.0, 3.0 - level * 0.18)
			add_customer()
		for c in waiting:
			c.patience -= delta
			var target := Vector2(150.0 + float(c.slot % 5) * 78.0, 155.0 + float(c.slot / 5) * 72.0)
			c.pos = c.pos.move_toward(target, delta * 120.0)
		var before := waiting.size()
		waiting = waiting.filter(func(c): return c.patience > 0.0)
		var expired := before - waiting.size()
		if expired > 0:
			lost += expired
			reputation = max(0, reputation - expired)
		if sale_timer <= 0.0 and not waiting.is_empty():
			sale_timer = 0.75
			serve_customer()
		sale_timer -= delta
	queue_redraw()

func add_customer() -> void:
	if waiting.size() >= min(10, 3 + level):
		lost += 1
		reputation = max(0, reputation - 1)
		message = "The shop is full — customer leaves."
		return
	var c: Dictionary = CUSTOMER_TYPES[randi() % CUSTOMER_TYPES.size()].duplicate()
	customer_seq += 1
	c.id = customer_seq
	c.slot = waiting.size()
	c.pos = Vector2(605, 430)
	waiting.append(c)
	message = "%s entered and is browsing %s products." % [c.name, c.pref]

func find_product(customer: Dictionary) -> int:
	var best := -1
	var best_score := -1.0
	for i in PRODUCTS.size():
		if int(PRODUCTS[i].unlock) > level or stock[i] <= 0:
			continue
		var price := float(PRODUCTS[i].price) * price_factor
		if price > float(customer.budget):
			continue
		var score := 1.0
		if PRODUCTS[i].pref == customer.pref:
			score += 4.0
		if PRODUCTS[i].pref == "daily":
			score += 0.8
		score *= demand
		if price_factor > 1.15:
			score *= 0.75
		if score > best_score:
			best_score = score
			best = i
	return best

func serve_customer() -> void:
	var customer: Dictionary = waiting.pop_front()
	var i := find_product(customer)
	if i < 0:
		lost += 1
		reputation = max(0, reputation - 1)
		message = "%s could not find an affordable item." % customer.name
		return
	var p: Dictionary = PRODUCTS[i]
	var sell := int(round(float(p.price) * price_factor))
	var profit := sell - int(p.cost)
	stock[i] -= 1
	gold += sell
	revenue += sell
	served += 1
	xp += max(1, profit)
	reputation = min(100, reputation + 1)
	message = "%s bought %s for %dg. Reputation %d." % [customer.name, p.name, sell, reputation]
	check_level()

func check_level() -> void:
	var need := level * 45
	if xp >= need and level < 10:
		xp -= need
		level += 1
		shelf_limit += 4
		shelf_count += 1
		for i in PRODUCTS.size():
			if int(PRODUCTS[i].unlock) == level:
				stock[i] = min(3, shelf_limit - stock_total())
		message = "Shop Lv.%d! New shelf and products unlocked." % level

func restock(i: int) -> void:
	if i < 0 or i >= PRODUCTS.size() or int(PRODUCTS[i].unlock) > level:
		return
	if stock_total() >= shelf_limit:
		message = "All shelves are full."
		return
	var qty := min(5, shelf_limit - stock_total())
	var cost := int(PRODUCTS[i].cost) * qty
	if gold < cost:
		message = "Need %dg to restock." % cost
		return
	gold -= cost
	stock[i] += qty
	message = "Restocked %d %s." % [qty, PRODUCTS[i].name]

func stock_total() -> int:
	var total := 0
	for n in stock:
		total += n
	return total

func toggle_shop() -> void:
	open = not open
	if open:
		spawn_timer = 0.3
		message = "SHOP OPEN — customers are entering."
	else:
		waiting.clear()
		message = "Shop closed. Rearrange prices or restock."

func next_day() -> void:
	if open:
		message = "Close the shop first."
		return
	day += 1
	served = 0
	lost = 0
	revenue = 0
	demand = randf_range(0.8, 1.2)
	price_factor = clamp(price_factor + randf_range(-0.08, 0.08), 0.75, 1.35)
	message = "Day %d: market demand %d%%." % [day, int(demand * 100)]

func change_price(step: float) -> void:
	if open:
		message = "Close the shop before changing prices."
		return
	price_factor = clamp(price_factor + step, 0.75, 1.35)
	message = "Selling prices are now %d%% of base." % int(price_factor * 100)

func expand() -> void:
	if open:
		message = "Close the shop first."
		return
	var cost := level * 100
	if gold < cost:
		message = "Expansion costs %dg." % cost
		return
	gold -= cost
	shelf_limit += 8
	shelf_count += 1
	message = "Expanded store! Shelf capacity %d." % shelf_limit

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := e.position
		if Rect2(715,125,195,48).has_point(p): toggle_shop(); return
		if Rect2(715,185,195,42).has_point(p): next_day(); return
		if Rect2(715,300,88,40).has_point(p): change_price(-0.05); return
		if Rect2(812,300,88,40).has_point(p): change_price(0.05); return
		if Rect2(715,410,195,50).has_point(p): expand(); return
		for i in PRODUCTS.size():
			if Rect2(45 + (i % 4) * 160, 360 + (i / 4) * 68, 150, 55).has_point(p): restock(i); return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE: toggle_shop()
			KEY_N: next_day()
			KEY_U: expand()
			KEY_MINUS: change_price(-0.05)
			KEY_EQUAL, KEY_PLUS: change_price(0.05)
			KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8: restock(e.keycode - KEY_1)
			KEY_R: get_tree().reload_current_scene()

func draw_shelf(pos: Vector2, product_index: int, slot: int) -> void:
	draw_rect(Rect2(pos.x, pos.y, 150, 62), Color("d9c4a5"), true)
	draw_rect(Rect2(pos.x, pos.y + 56, 150, 7), Color("8d6e4a"), true)
	var p: Dictionary = PRODUCTS[product_index]
	draw_string(ThemeDB.fallback_font, pos + Vector2(10, 22), p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("4b4035"))
	var visible := min(stock[product_index], 5)
	for j in visible:
		draw_circle(pos + Vector2(15 + j * 25, 45), 7, Color("7fa36b"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(112, 22), "%d" % stock[product_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5d5145"))

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("e9edf0"), true)
	draw_rect(Rect2(0,0,960,72), Color("243447"), true)
	draw_string(ThemeDB.fallback_font, Vector2(28,46), "MY LITTLE SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(350,40), "DAY %d  •  Lv.%d" % [day,level], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("dbe7f2"))
	draw_string(ThemeDB.fallback_font, Vector2(350,60), "XP %d/%d  •  Reputation %d" % [xp,level*45,reputation], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b8cadb"))
	draw_string(ThemeDB.fallback_font, Vector2(780,43), "%d g" % gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("f4d35e"))

	# Store floor.
	draw_rect(Rect2(25,90,650,245), Color("f8f4ed"), true)
	draw_rect(Rect2(25,90,650,12), Color("c8a77d"), true)
	draw_string(ThemeDB.fallback_font, Vector2(45,125), "YOUR SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("695747"))
	# Shelves arranged as a real store layout.
	for s in shelf_count:
		var sx := 45.0 + float(s % 2) * 300.0
		var sy := 140.0 + float(s / 2) * 82.0
		draw_rect(Rect2(sx,sy,250,66), Color("e2d2bb"), true)
		draw_rect(Rect2(sx+8,sy+8,234,50), Color("fffaf1"), true)
		var base_index := (s * 2) % PRODUCTS.size()
		draw_string(ThemeDB.fallback_font, Vector2(sx+18,sy+29), PRODUCTS[base_index].name, HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("51463c"))
		draw_string(ThemeDB.fallback_font, Vector2(sx+18,sy+49), "Stock %d" % stock[base_index], HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("7a6a5a"))
		if base_index + 1 < PRODUCTS.size():
			draw_string(ThemeDB.fallback_font, Vector2(sx+125,sy+29), PRODUCTS[base_index+1].name, HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("51463c"))
			draw_string(ThemeDB.fallback_font, Vector2(sx+125,sy+49), "Stock %d" % stock[base_index+1], HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("7a6a5a"))
	# Checkout counter.
	draw_rect(Rect2(520,285,130,35), Color("9a7650"), true)
	draw_string(ThemeDB.fallback_font, Vector2(545,308), "CHECKOUT", HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	# Entrance.
	draw_rect(Rect2(45,310,90,25), Color("7aa6c2"), true)
	draw_string(ThemeDB.fallback_font, Vector2(58,328), "ENTRANCE", HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
	# Customers walking/browsing.
	for c in waiting:
		draw_circle(c.pos, 12, Color("e0a37e"))
		draw_rect(Rect2(c.pos.x-13,c.pos.y+11,26,25), Color("6c8db5"), true)
		draw_string(ThemeDB.fallback_font, c.pos + Vector2(-5,5), c.icon, HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)

	# Management panel.
	draw_rect(Rect2(695,90,235,395), Color.WHITE, true)
	draw_string(ThemeDB.fallback_font, Vector2(715,115), "MANAGEMENT", HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("526170"))
	draw_rect(Rect2(715,125,195,48), Color("b85c5c") if open else Color("4f8a62"), true)
	draw_string(ThemeDB.fallback_font, Vector2(750,156), "CLOSE SHOP" if open else "OPEN SHOP", HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
	draw_rect(Rect2(715,185,195,42), Color("657b92"), true)
	draw_string(ThemeDB.fallback_font, Vector2(750,212), "NEXT DAY [N]", HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(715,255), "Customers %d   Served %d" % [waiting.size(),served], HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("4d5965"))
	draw_string(ThemeDB.fallback_font, Vector2(715,277), "Stock %d/%d" % [stock_total(),shelf_limit], HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("4d5965"))
	draw_string(ThemeDB.fallback_font, Vector2(715,299), "Demand %d%%  Price %d%%" % [int(demand*100),int(price_factor*100)], HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
	draw_rect(Rect2(715,300,88,40), Color("7c8792"), true)
	draw_string(ThemeDB.fallback_font, Vector2(741,326), "- PRICE", HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_rect(Rect2(812,300,88,40), Color("7c8792"), true)
	draw_string(ThemeDB.fallback_font, Vector2(838,326), "+ PRICE", HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(715,375), "Shelves: %d" % shelf_count, HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("4d5965"))
	draw_rect(Rect2(715,410,195,50), Color("d18b45"), true)
	draw_string(ThemeDB.fallback_font, Vector2(740,441), "EXPAND %d g [U]" % (level*100), HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)

	# Restock cards.
	draw_string(ThemeDB.fallback_font, Vector2(45,352), "RESTOCK — click or press 1-8", HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("526170"))
	for i in PRODUCTS.size():
		var p: Dictionary = PRODUCTS[i]
		var unlocked := int(p.unlock) <= level
		var x := 45.0 + float(i % 4) * 160.0
		var y := 360.0 + float(i / 4) * 68.0
		draw_rect(Rect2(x,y,150,55), Color.WHITE if unlocked else Color("d6dadd"), true)
		draw_string(ThemeDB.fallback_font, Vector2(x+9,y+20), "%d. %s" % [i+1,p.name], HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("33404c") if unlocked else Color("777d82"))
		if unlocked:
			draw_string(ThemeDB.fallback_font, Vector2(x+9,y+41), "Stock %d | %dg→%dg" % [stock[i],p.cost,int(round(float(p.price)*price_factor))], HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("63717e"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(x+9,y+39), "Unlock Lv.%d" % p.unlock,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("777d82"))

	draw_rect(Rect2(25,500,905,28), Color("273849"), true)
	draw_string(ThemeDB.fallback_font, Vector2(42,520), message, HORIZONTAL_ALIGNMENT_LEFT,870,14,Color.WHITE)
