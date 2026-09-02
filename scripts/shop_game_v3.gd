extends Node2D

# My Little Shop v0.3
# Customer types now have preferences and budgets; shelves have limited capacity.
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
	{"name":"Worker","icon":"W","pref":"quick","budget":18,"patience":3.0},
	{"name":"Parent","icon":"P","pref":"healthy","budget":22,"patience":4.0},
	{"name":"Student","icon":"S","pref":"snack","budget":14,"patience":2.5},
	{"name":"Neighbor","icon":"N","pref":"daily","budget":12,"patience":3.5}
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
var message := "Restock shelves and open your shop."

func _ready() -> void:
	randomize()
	queue_redraw()

func _process(delta: float) -> void:
	if open:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = max(0.8, 3.0 - level * 0.2)
			add_customer()
		for c in waiting:
			c.patience -= delta
		var before := waiting.size()
		waiting = waiting.filter(func(c): return c.patience > 0)
		lost += before - waiting.size()
		if sale_timer <= 0 and not waiting.is_empty():
			sale_timer = 0.65
			serve_customer()
		sale_timer -= delta
	queue_redraw()

func add_customer() -> void:
	if waiting.size() >= shelf_limit / 3:
		lost += 1
		message = "Too crowded! Customer leaves."
		return
	var c: Dictionary = CUSTOMER_TYPES[randi() % CUSTOMER_TYPES.size()].duplicate()
	c.patience = float(c.patience) * (0.9 + randf() * 0.2)
	waiting.append(c)
	message = "%s arrived — wants %s." % [c.name, c.pref]

func find_product(customer: Dictionary) -> int:
	var best := -1
	var best_score := -1.0
	for i in PRODUCTS.size():
		if PRODUCTS[i].unlock > level or stock[i] <= 0:
			continue
		var price := float(PRODUCTS[i].price) * price_factor
		if price > float(customer.budget):
			continue
		var score := 1.0
		if PRODUCTS[i].pref == customer.pref:
			score += 3.0
		if PRODUCTS[i].pref == "daily":
			score += 0.8
		score *= demand
		if score > best_score:
			best_score = score
			best = i
	return best

func serve_customer() -> void:
	var customer: Dictionary = waiting.pop_front()
	var i := find_product(customer)
	if i < 0:
		lost += 1
		message = "%s found nothing affordable." % customer.name
		return
	var p: Dictionary = PRODUCTS[i]
	var sell := int(round(float(p.price) * price_factor))
	var profit := sell - int(p.cost)
	stock[i] -= 1
	gold += sell
	revenue += sell
	served += 1
	xp += max(1, profit)
	message = "%s bought %s for %dg (+%dg)." % [customer.name, p.name, sell, profit]
	check_level()

func check_level() -> void:
	var need := level * 45
	if xp >= need and level < 10:
		xp -= need
		level += 1
		shelf_limit += 4
		for i in PRODUCTS.size():
			if PRODUCTS[i].unlock == level:
				stock[i] = 3
		message = "Shop Lv.%d! Shelf capacity is now %d." % [level, shelf_limit]

func restock(i: int) -> void:
	if i < 0 or i >= PRODUCTS.size() or PRODUCTS[i].unlock > level:
		return
	if stock_total() >= shelf_limit:
		message = "Shelves are full. Sell some stock first."
		return
	var qty := min(5, shelf_limit - stock_total())
	var cost := int(PRODUCTS[i].cost) * qty
	if gold < cost:
		message = "Need %dg." % cost
		return
	gold -= cost
	stock[i] += qty
	message = "Bought %d %s for %dg." % [qty, PRODUCTS[i].name, cost]

func stock_total() -> int:
	var total := 0
	for n in stock: total += n
	return total

func toggle_shop() -> void:
	open = not open
	if open:
		spawn_timer = 0.3
		message = "SHOP OPEN — watch customers and shelves."
	else:
		waiting.clear()
		message = "Shop closed. Restock and plan tomorrow."

func next_day() -> void:
	if open:
		message = "Close the shop first."
		return
	day += 1
	served = 0
	lost = 0
	revenue = 0
	demand = randf_range(0.8, 1.2)
	price_factor = clamp(price_factor + randf_range(-0.08,0.08),0.75,1.35)
	message = "Day %d: demand %d%%, price %d%%." % [day,int(demand*100),int(price_factor*100)]

func change_price(step: float) -> void:
	if open:
		message = "Close the shop before changing prices."
		return
	price_factor = clamp(price_factor + step,0.75,1.35)
	message = "Price level: %d%%." % int(price_factor*100)

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
	message = "Expanded! Shelf capacity: %d." % shelf_limit

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := e.position
		if Rect2(700,125,200,50).has_point(p): toggle_shop(); return
		if Rect2(700,190,200,42).has_point(p): next_day(); return
		if Rect2(700,340,95,40).has_point(p): change_price(-0.05); return
		if Rect2(805,340,95,40).has_point(p): change_price(0.05); return
		if Rect2(700,430,200,50).has_point(p): expand(); return
		for i in PRODUCTS.size():
			if Rect2(45+(i%4)*160,335+(i/4)*80,150,65).has_point(p): restock(i); return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE: toggle_shop()
			KEY_N: next_day()
			KEY_U: expand()
			KEY_MINUS: change_price(-0.05)
			KEY_EQUAL,KEY_PLUS: change_price(0.05)
			KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8: restock(e.keycode-KEY_1)

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("eef2f5"),true)
	draw_rect(Rect2(0,0,960,78),Color("243447"),true)
	draw_string(ThemeDB.fallback_font,Vector2(30,48),"MY LITTLE SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(350,42),"DAY %d  Lv.%d" % [day,level],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("dbe7f2"))
	draw_string(ThemeDB.fallback_font,Vector2(350,65),"XP %d/%d   Shelves %d/%d" % [xp,level*45,stock_total(),shelf_limit],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8cadb"))
	draw_string(ThemeDB.fallback_font,Vector2(760,45),"%d g" % gold,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f4d35e"))
	draw_rect(Rect2(30,100,645,205),Color.WHITE,true)
	draw_string(ThemeDB.fallback_font,Vector2(50,130),"CUSTOMERS",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("765b42"))
	for j in waiting.size():
		var c: Dictionary = waiting[j]
		var x := 65.0+(j%6)*95
		var y := 190.0+(j/6)*65
		draw_circle(Vector2(x,y),13,Color("e0a37e"))
		draw_rect(Rect2(x-14,y+12,28,28),Color("6c8db5"),true)
		draw_string(ThemeDB.fallback_font,Vector2(x-8,y+5),c.icon,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffffff"))
	draw_string(ThemeDB.fallback_font,Vector2(50,285),"Demand %d%%   Price %d%%   Served %d   Lost %d" % [int(demand*100),int(price_factor*100),served,lost],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("526170"))
	draw_rect(Rect2(695,100,235,385),Color.WHITE,true)
	draw_string(ThemeDB.fallback_font,Vector2(715,122),"MANAGEMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("526170"))
	draw_rect(Rect2(715,135,195,48),Color("b85c5c") if open else Color("4f8a62"),true)
	draw_string(ThemeDB.fallback_font,Vector2(750,166),"CLOSE SHOP" if open else "OPEN SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
	draw_rect(Rect2(715,195,195,42),Color("657b92"),true)
	draw_string(ThemeDB.fallback_font,Vector2(750,222),"NEXT DAY [N]",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(715,270),"Stock: %d/%d" % [stock_total(),shelf_limit],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("4d5965"))
	draw_string(ThemeDB.fallback_font,Vector2(715,292),"Revenue: %d g" % revenue,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("4d5965"))
	draw_rect(Rect2(715,310,90,40),Color("7c8792"),true)
	draw_string(ThemeDB.fallback_font,Vector2(742,336),"- PRICE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_rect(Rect2(810,310,90,40),Color("7c8792"),true)
	draw_string(ThemeDB.fallback_font,Vector2(837,336),"+ PRICE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_rect(Rect2(715,410,195,50),Color("d18b45"),true)
	draw_string(ThemeDB.fallback_font,Vector2(740,441),"EXPAND %d g [U]" % (level*100),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(45,325),"RESTOCK — click or press 1-8",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("526170"))
	for i in PRODUCTS.size():
		var p: Dictionary = PRODUCTS[i]
		var unlocked := int(p.unlock)<=level
		var x := 45.0+(i%4)*160
		var y := 335.0+(i/4)*80
		draw_rect(Rect2(x,y,150,65),Color.WHITE if unlocked else Color("d6dadd"),true)
		draw_string(ThemeDB.fallback_font,Vector2(x+10,y+23),"%d. %s" % [i+1,p.name],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("33404c") if unlocked else Color("777d82"))
		if unlocked: draw_string(ThemeDB.fallback_font,Vector2(x+10,y+46),"Stock %d | %dg→%dg" % [stock[i],p.cost,int(round(float(p.price)*price_factor))],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("63717e"))
		else: draw_string(ThemeDB.fallback_font,Vector2(x+10,y+43),"Unlock Lv.%d" % p.unlock,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("777d82"))
	draw_rect(Rect2(30,500,900,28),Color("273849"),true)
	draw_string(ThemeDB.fallback_font,Vector2(45,520),message,HORIZONTAL_ALIGNMENT_LEFT,860,14,Color.WHITE)
