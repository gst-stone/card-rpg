extends Node2D

# My Little Shop v0.2: demand, market price, customer satisfaction and expansion.
const PRODUCTS := [
	{"name":"Water", "icon":"W", "cost":2, "price":4, "unlock":1, "demand":1.00},
	{"name":"Bread", "icon":"B", "cost":3, "price":6, "unlock":1, "demand":0.95},
	{"name":"Apple", "icon":"A", "cost":4, "price":8, "unlock":1, "demand":0.80},
	{"name":"Drink", "icon":"D", "cost":5, "price":10, "unlock":2, "demand":0.75},
	{"name":"Noodles", "icon":"N", "cost":6, "price":12, "unlock":2, "demand":0.70},
	{"name":"Milk", "icon":"M", "cost":8, "price":16, "unlock":3, "demand":0.60},
	{"name":"Cookie", "icon":"C", "cost":10, "price":20, "unlock":4, "demand":0.52},
	{"name":"Hotpot", "icon":"H", "cost":20, "price":40, "unlock":5, "demand":0.40}
]

var gold := 100
var shop_level := 1
var xp := 0
var day := 1
var stock: Array[int] = [8, 8, 8, 0, 0, 0, 0, 0]
var waiting := 0
var served := 0
var revenue := 0
var lost_customers := 0
var capacity_bonus := 0
var market_demand := 1.0
var price_factor := 1.0
var open := false
var customer_timer := 0.0
var sale_timer := 0.0
var message := "Restock, adjust price, then open the shop."
var popups: Array[Dictionary] = []

func _ready() -> void:
	randomize()
	queue_redraw()

func _process(delta: float) -> void:
	if open:
		customer_timer -= delta
		if customer_timer <= 0.0:
			customer_timer = max(0.75, 3.2 - shop_level * 0.22)
			if waiting < capacity():
				waiting += 1
			else:
				lost_customers += 1
				message = "The shop is crowded. A customer left."
		sale_timer -= delta
		if sale_timer <= 0.0 and waiting > 0:
			sale_timer = 0.75
			make_sale()
	for p in popups:
		p.pos += p.vel * delta
		p.life -= delta
	popups = popups.filter(func(p): return p.life > 0.0)
	queue_redraw()

func capacity() -> int:
	return 4 + shop_level + capacity_bonus

func pick_product() -> int:
	var choices: Array[int] = []
	var weights: Array[float] = []
	var total := 0.0
	for i in PRODUCTS.size():
		if PRODUCTS[i].unlock <= shop_level and stock[i] > 0:
			var w: float = float(PRODUCTS[i].demand) * market_demand
			# Higher prices reduce customer willingness to buy.
			w *= clamp(1.45 - price_factor, 0.35, 1.15)
			choices.append(i)
			weights.append(w)
			total += w
	if choices.is_empty():
		return -1
	var roll := randf() * total
	for j in choices.size():
		roll -= weights[j]
		if roll <= 0.0:
			return choices[j]
	return choices.back()

func make_sale() -> void:
	var index := pick_product()
	if index < 0:
		waiting -= 1
		lost_customers += 1
		message = "No suitable stock. Customer left unhappy."
		return
	var product: Dictionary = PRODUCTS[index]
	var sell_price := max(1, int(round(float(product.price) * price_factor)))
	var profit := sell_price - int(product.cost)
	stock[index] -= 1
	waiting -= 1
	served += 1
	revenue += sell_price
	gold += sell_price
	xp += max(1, profit)
	popups.append({"pos":Vector2(700, 255), "vel":Vector2(0,-32), "life":0.9, "text":"+%dg" % sell_price})
	message = "%s sold for %dg. Profit +%dg." % [product.name, sell_price, profit]
	check_level()

func check_level() -> void:
	var need := shop_level * 45
	while xp >= need and shop_level < 10:
		xp -= need
		shop_level += 1
		for i in PRODUCTS.size():
			if PRODUCTS[i].unlock == shop_level:
				stock[i] = 3
			message = "Level %d! New products unlocked." % shop_level
			need = shop_level * 45

func restock(index: int) -> void:
	if index < 0 or index >= PRODUCTS.size() or PRODUCTS[index].unlock > shop_level:
		return
	var p: Dictionary = PRODUCTS[index]
	var qty := 5
	var cost := int(p.cost) * qty
	if gold < cost:
		message = "Need %dg to restock %s." % [cost, p.name]
		return
	gold -= cost
	stock[index] += qty
	message = "Restocked %d %s for %dg." % [qty, p.name, cost]

func change_price(step: float) -> void:
	if open:
		message = "Close the shop before changing prices."
		return
	price_factor = clamp(price_factor + step, 0.75, 1.35)
	message = "Price level: %d%% of base." % int(price_factor * 100.0)

func open_shop() -> void:
	open = not open
	if open:
		customer_timer = 0.4
		message = "SHOP OPEN — watch demand and stock."
	else:
		waiting = 0
		message = "Shop closed. Review today's sales."

func next_day() -> void:
	if open:
		message = "Close the shop first."
		return
	day += 1
	served = 0
	revenue = 0
	lost_customers = 0
	market_demand = 0.80 + randf() * 0.40
	price_factor = clamp(price_factor + randf_range(-0.08, 0.08), 0.75, 1.35)
	message = "Day %d: demand %d%%, price %d%%." % [day, int(market_demand * 100), int(price_factor * 100)]

func expand_shop() -> void:
	if open:
		message = "Close the shop before expanding."
		return
	if shop_level >= 10:
		message = "Maximum shop level reached."
		return
	var cost := shop_level * 100
	if gold < cost:
		message = "Expansion costs %dg." % cost
		return
	gold -= cost
	capacity_bonus += 2
	shop_level += 1
	for i in PRODUCTS.size():
		if PRODUCTS[i].unlock == shop_level:
			stock[i] = 3
	message = "Expanded! Shop Lv.%d, capacity %d." % [shop_level, capacity()]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := event.position
		if Rect2(700,125,190,52).has_point(p): open_shop(); return
		if Rect2(700,190,190,45).has_point(p): next_day(); return
		if Rect2(700,345,90,42).has_point(p): change_price(-0.05); return
		if Rect2(800,345,90,42).has_point(p): change_price(0.05); return
		if Rect2(700,440,190,52).has_point(p): expand_shop(); return
		for i in PRODUCTS.size():
			if Rect2(55 + (i % 4) * 205,335 + (i / 4) * 85,190,70).has_point(p):
				restock(i); return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: open_shop()
			KEY_N: next_day()
			KEY_U: expand_shop()
			KEY_MINUS: change_price(-0.05)
			KEY_EQUAL, KEY_PLUS: change_price(0.05)
			KEY_R: get_tree().reload_current_scene()
			KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8: restock(event.keycode - KEY_1)

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("eef2f5"),true)
	draw_rect(Rect2(0,0,960,78),Color("243447"),true)
	draw_string(ThemeDB.fallback_font,Vector2(35,48),"MY LITTLE SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(355,45),"DAY %d" % day,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("dbe7f2"))
	draw_string(ThemeDB.fallback_font,Vector2(355,67),"Lv.%d  XP %d/%d" % [shop_level,xp,shop_level*45],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b8cadb"))
	draw_string(ThemeDB.fallback_font,Vector2(735,45),"%d g" % gold,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f4d35e"))

	draw_rect(Rect2(35,105,625,200),Color.WHITE,true)
	draw_rect(Rect2(55,125,180,150),Color("dce8d8"),true)
	draw_string(ThemeDB.fallback_font,Vector2(72,160),"SHELVES",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("49624d"))
	for i in 3: draw_rect(Rect2(72,180+i*27,125,4),Color("78917a"),true)
	for i in range(min(8,2+shop_level)):
		draw_circle(Vector2(92.0+(i%5)*22,170.0+(i%3)*27),7,Color("7fa36b"))

	draw_rect(Rect2(270,125,365,150),Color("f8ead8"),true)
	draw_string(ThemeDB.fallback_font,Vector2(292,160),"CUSTOMERS",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("765b42"))
	for i in waiting:
		var cx := 310.0+(i%5)*60.0
		var cy := 215.0+(i/5)*45.0
		draw_circle(Vector2(cx,cy-15),11,Color("e0a37e"))
		draw_rect(Rect2(cx-12,cy-4,24,28),Color("6c8db5"),true)
	draw_rect(Rect2(55,285,580,20),Color("9a7650"),true)

	draw_rect(Rect2(680,105,245,360),Color.WHITE,true)
	draw_string(ThemeDB.fallback_font,Vector2(700,120),"MANAGEMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("526170"))
	draw_rect(Rect2(700,125,190,52),Color("b85c5c") if open else Color("4f8a62"),true)
	draw_string(ThemeDB.fallback_font,Vector2(735,158),"CLOSE SHOP" if open else "OPEN SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color.WHITE)
	draw_rect(Rect2(700,190,190,45),Color("657b92"),true)
	draw_string(ThemeDB.fallback_font,Vector2(735,219),"NEXT DAY [N]",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(700,275),"Served: %d" % served,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("4d5965"))
	draw_string(ThemeDB.fallback_font,Vector2(700,298),"Revenue: %d g" % revenue,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("4d5965"))
	draw_string(ThemeDB.fallback_font,Vector2(700,321),"Lost: %d" % lost_customers,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("4d5965"))
	draw_string(ThemeDB.fallback_font,Vector2(700,342),"Demand %d%%  Price %d%%" % [int(market_demand*100),int(price_factor*100)],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
	draw_rect(Rect2(700,345,90,42),Color("7c8792"),true)
	draw_string(ThemeDB.fallback_font,Vector2(727,373),"- PRICE",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	draw_rect(Rect2(800,345,90,42),Color("7c8792"),true)
	draw_string(ThemeDB.fallback_font,Vector2(827,373),"+ PRICE",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
	draw_rect(Rect2(700,440,190,52),Color("d18b45"),true)
	draw_string(ThemeDB.fallback_font,Vector2(720,472),"EXPAND %d g [U]" % (shop_level*100),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)

	draw_string(ThemeDB.fallback_font,Vector2(55,326),"RESTOCK — click or press 1-8",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("526170"))
	for i in PRODUCTS.size():
		var p: Dictionary = PRODUCTS[i]
		var unlocked := int(p.unlock)<=shop_level
		var x := 55.0+(i%4)*205.0
		var y := 335.0+(i/4)*85.0
		draw_rect(Rect2(x,y,190,70),Color.WHITE if unlocked else Color("d6dadd"),true)
		draw_rect(Rect2(x,y,5,70),Color("6d8fb3") if unlocked else Color("9aa0a6"),true)
		draw_string(ThemeDB.fallback_font,Vector2(x+15,y+25),"[%s] %s" % [p.icon,p.name],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("33404c") if unlocked else Color("777d82"))
		if unlocked:
			var sell := int(round(float(p.price)*price_factor))
			draw_string(ThemeDB.fallback_font,Vector2(x+15,y+48),"Stock %d | %dg → %dg" % [stock[i],p.cost,sell],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("63717e"))
		else: draw_string(ThemeDB.fallback_font,Vector2(x+15,y+45),"Unlock Lv.%d" % p.unlock,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("777d82"))

	draw_rect(Rect2(35,500,890,28),Color("273849"),true)
	draw_string(ThemeDB.fallback_font,Vector2(50,520),message,HORIZONTAL_ALIGNMENT_LEFT,850,15,Color.WHITE)
	for p in popups: draw_string(ThemeDB.fallback_font,p.pos,p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("c58a2a"))
