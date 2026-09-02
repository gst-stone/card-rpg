extends Node2D

# Small Shop MVP: stock -> customers -> sales -> upgrade.
const PRODUCTS := [
	{"name":"Water", "icon":"💧", "cost":2, "price":4, "unlock":1},
	{"name":"Bread", "icon":"🍞", "cost":3, "price":6, "unlock":1},
	{"name":"Apple", "icon":"🍎", "cost":4, "price":8, "unlock":1},
	{"name":"Drink", "icon":"🥤", "cost":5, "price":10, "unlock":2},
	{"name":"Noodles", "icon":"🍜", "cost":6, "price":12, "unlock":2},
	{"name":"Milk", "icon":"🥛", "cost":8, "price":16, "unlock":3},
	{"name":"Cookie", "icon":"🍪", "cost":10, "price":20, "unlock":4},
	{"name":"Hotpot", "icon":"🍲", "cost":20, "price":40, "unlock":5}
]

var gold := 100
var shop_level := 1
var experience := 0
var day := 1
var customers := 0
var served_today := 0
var revenue_today := 0
var stock: Array[int] = [8, 8, 8, 0, 0, 0, 0, 0]
var customer_timer := 0.0
var sale_timer := 0.0
var message := "Welcome! Stock your shelves and open the shop."
var opened := false
var selected := -1
var particles: Array[Dictionary] = []

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if opened:
		customer_timer -= delta
		if customer_timer <= 0.0:
			spawn_customer()
			customer_timer = max(1.0, 4.0 - shop_level * 0.35)
		sale_timer -= delta
		if sale_timer <= 0.0 and customers > 0:
			serve_customer()
			sale_timer = 1.1
	for p in particles:
		p.pos += p.vel * delta
		p.life -= delta
	particles = particles.filter(func(p): return p.life > 0.0)
	queue_redraw()

func spawn_customer() -> void:
	if customers < 5 + shop_level:
		customers += 1
		message = "A customer entered the shop."

func serve_customer() -> void:
	if customers <= 0:
		return
	var available: Array[int] = []
	for i in PRODUCTS.size():
		if PRODUCTS[i].unlock <= shop_level and stock[i] > 0:
			available.append(i)
	if available.is_empty():
		message = "Customers are waiting, but your shelves are empty!"
		return
	var index: int = available[randi() % available.size()]
	var product: Dictionary = PRODUCTS[index]
	stock[index] -= 1
	customers -= 1
	served_today += 1
	var profit: int = int(product.price) - int(product.cost)
	gold += int(product.price)
	revenue_today += int(product.price)
	experience += profit
	particles.append({"pos":Vector2(705, 250), "vel":Vector2(0, -35), "life":1.0, "text":"+%dg" % product.price})
	message = "%s sold for %dg! Profit +%dg." % [product.name, product.price, profit]
	check_level_up()

func check_level_up() -> void:
	var need := shop_level * 45
	if experience >= need and shop_level < 10:
		shop_level += 1
		experience = 0
		message = "Shop upgraded to Level %d! New shelves unlocked." % shop_level
		for i in PRODUCTS.size():
			if PRODUCTS[i].unlock == shop_level:
				stock[i] = 3

func open_shop() -> void:
	opened = not opened
	if opened:
		message = "Shop is OPEN. Customers will arrive automatically."
		customer_timer = 0.5
	else:
		message = "Shop closed. Restock or upgrade before opening again."

func next_day() -> void:
	if opened:
		message = "Close the shop before starting a new day."
		return
	day += 1
	customers = 0
	served_today = 0
	revenue_today = 0
	message = "Day %d begins. Keep improving your shop!" % day

func restock(index: int) -> void:
	if index < 0 or index >= PRODUCTS.size() or PRODUCTS[index].unlock > shop_level:
		return
	var product: Dictionary = PRODUCTS[index]
	var qty := 5
	var cost := int(product.cost) * qty
	if gold < cost:
		message = "Not enough gold. Need %dg." % cost
		return
	gold -= cost
	stock[index] += qty
	message = "Bought %d %s for %dg." % [qty, product.name, cost]

func upgrade_shop() -> void:
	if opened:
		message = "Close the shop before upgrading."
		return
	if shop_level >= 10:
		message = "Your shop is already max level."
		return
	var price := shop_level * 100
	if gold < price:
		message = "Shop upgrade costs %dg." % price
		return
	gold -= price
	shop_level += 1
	for i in PRODUCTS.size():
		if PRODUCTS[i].unlock == shop_level:
			stock[i] = 3
	message = "Shop expanded to Level %d!" % shop_level

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := event.position
		if Rect2(700, 125, 190, 52).has_point(p): open_shop(); return
		if Rect2(700, 190, 190, 45).has_point(p): next_day(); return
		if Rect2(700, 440, 190, 52).has_point(p): upgrade_shop(); return
		for i in PRODUCTS.size():
			if Rect2(55 + (i % 4) * 205, 335 + (i / 4) * 85, 190, 70).has_point(p):
				restock(i); return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: open_shop()
			KEY_U: upgrade_shop()
			KEY_N: next_day()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				restock(event.keycode - KEY_1)
			KEY_R:
				get_tree().reload_current_scene()

func _draw() -> void:
	# Background and shop floor.
	draw_rect(Rect2(0, 0, 960, 540), Color("eef2f5"), true)
	draw_rect(Rect2(0, 0, 960, 78), Color("243447"), true)
	draw_string(ThemeDB.fallback_font, Vector2(35, 48), "MY LITTLE SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffffff"))
	draw_string(ThemeDB.fallback_font, Vector2(355, 45), "DAY %d" % day, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("dbe7f2"))
	draw_string(ThemeDB.fallback_font, Vector2(355, 67), "Level %d   XP %d/%d" % [shop_level, experience, shop_level * 45], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b8cadb"))
	draw_string(ThemeDB.fallback_font, Vector2(735, 45), "%d g" % gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("f4d35e"))

	# Store room.
	draw_rect(Rect2(35, 105, 625, 200), Color("ffffff"), true)
	draw_rect(Rect2(55, 125, 180, 150), Color("dce8d8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(72, 160), "SHELVES", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("49624d"))
	for i in 3:
		draw_rect(Rect2(72, 180 + i * 27, 125, 4), Color("78917a"), true)
	for i in range(min(5, 2 + shop_level)):
		var x := 92.0 + (i % 5) * 22.0
		var y := 170.0 + (i % 3) * 27.0
		draw_circle(Vector2(x, y), 7, Color("7fa36b"))

	# Customer area.
	draw_rect(Rect2(270, 125, 365, 150), Color("f8ead8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(292, 160), "CUSTOMERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("765b42"))
	for i in customers:
		var cx := 310.0 + (i % 5) * 60.0
		var cy := 215.0 + (i / 5) * 45.0
		draw_circle(Vector2(cx, cy - 15), 11, Color("e0a37e"))
		draw_rect(Rect2(cx - 12, cy - 4, 24, 28), Color("6c8db5"), true)
	# Counter.
	draw_rect(Rect2(55, 285, 580, 20), Color("9a7650"), true)

	# Control panel.
	draw_rect(Rect2(680, 105, 245, 360), Color("ffffff"), true)
	draw_string(ThemeDB.fallback_font, Vector2(700, 120), "MANAGEMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("526170"))
	draw_rect(Rect2(700, 125, 190, 52), Color("4f8a62" if not opened else "b85c5c"), true)
	draw_string(ThemeDB.fallback_font, Vector2(735, 158), "CLOSE SHOP" if opened else "OPEN SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
	draw_rect(Rect2(700, 190, 190, 45), Color("657b92"), true)
	draw_string(ThemeDB.fallback_font, Vector2(735, 219), "NEXT DAY [N]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(700, 275), "Today: %d customers" % served_today, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("4d5965"))
	draw_string(ThemeDB.fallback_font, Vector2(700, 300), "Revenue: %d g" % revenue_today, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("4d5965"))
	draw_string(ThemeDB.fallback_font, Vector2(700, 325), "Waiting: %d" % customers, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("4d5965"))
	draw_rect(Rect2(700, 440, 190, 52), Color("d18b45"), true)
	draw_string(ThemeDB.fallback_font, Vector2(720, 472), "UPGRADE %d g [U]" % (shop_level * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

	# Product cards.
	draw_string(ThemeDB.fallback_font, Vector2(55, 326), "RESTOCK — click a product or press 1-8", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("526170"))
	for i in PRODUCTS.size():
		var product: Dictionary = PRODUCTS[i]
		var unlocked := int(product.unlock) <= shop_level
		var x := 55.0 + (i % 4) * 205.0
		var y := 335.0 + (i / 4) * 85.0
		draw_rect(Rect2(x, y, 190, 70), Color("ffffff") if unlocked else Color("d6dadd"), true)
		draw_rect(Rect2(x, y, 5, 70), Color("6d8fb3") if unlocked else Color("9aa0a6"), true)
		draw_string(ThemeDB.fallback_font, Vector2(x + 15, y + 25), "%s %s" % [product.icon, product.name], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("33404c") if unlocked else Color("777d82"))
		if unlocked:
			draw_string(ThemeDB.fallback_font, Vector2(x + 15, y + 48), "Stock %d  |  %dg → %dg" % [stock[i], product.cost, product.price], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("63717e"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(x + 15, y + 45), "Unlock Lv.%d" % product.unlock, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("777d82"))

	# Message bar.
	draw_rect(Rect2(35, 500, 890, 28), Color("273849"), true)
	draw_string(ThemeDB.fallback_font, Vector2(50, 520), message, HORIZONTAL_ALIGNMENT_LEFT, 850, 15, Color("ffffff"))
	for p in particles:
		draw_string(ThemeDB.fallback_font, p.pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c58a2a"))
