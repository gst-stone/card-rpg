extends Node2D

# My Little Shop v0.6 - save/load, daily settlement, feedback and touch-friendly UI.
const SAVE_PATH := "user://shop_save.json"
const PRODUCTS := [
 {"name":"Water","cost":2,"price":4,"unlock":1,"pref":"daily","pop":1.0},
 {"name":"Bread","cost":3,"price":6,"unlock":1,"pref":"daily","pop":0.95},
 {"name":"Apple","cost":4,"price":8,"unlock":1,"pref":"healthy","pop":0.8},
 {"name":"Drink","cost":5,"price":10,"unlock":2,"pref":"snack","pop":0.75},
 {"name":"Noodles","cost":6,"price":12,"unlock":2,"pref":"quick","pop":0.7},
 {"name":"Milk","cost":8,"price":16,"unlock":3,"pref":"healthy","pop":0.6},
 {"name":"Cookie","cost":10,"price":20,"unlock":4,"pref":"snack","pop":0.52},
 {"name":"Hotpot","cost":20,"price":40,"unlock":5,"pref":"quick","pop":0.4}
]
const CUSTOMER_TYPES := [
 {"name":"Worker","icon":"W","pref":"quick","budget":18,"patience":8.0},
 {"name":"Parent","icon":"P","pref":"healthy","budget":22,"patience":9.0},
 {"name":"Student","icon":"S","pref":"snack","budget":14,"patience":7.0},
 {"name":"Neighbor","icon":"N","pref":"daily","budget":12,"patience":8.5}
]
const SUPPLIERS := [
 {"name":"Local","discount":1.0,"label":"stable"},
 {"name":"Wholesale","discount":0.88,"label":"-12%"},
 {"name":"Premium","discount":1.08,"label":"+8%, popularity bonus"}
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
var operating_cost := 0
var day_profit := 0
var demand := 1.0
var price_factor := 1.0
var open := false
var spawn_timer := 0.0
var sale_timer := 0.0
var reputation := 50
var shelf_count := 3
var staff := 0
var supplier := 0
var event_text := "Normal market"
var event_profit_bonus := 1.0
var event_demand_bonus := 1.0
var message := "Choose a supplier, stock goods, then open."
var settlement_visible := false
var last_day_revenue := 0
var last_day_cost := 0
var last_day_profit := 0
var last_day_served := 0
var last_day_lost := 0
var last_day_event := "Normal market"
var feedback: Array[Dictionary] = []
var saved_hint_timer := 0.0

func _ready() -> void:
 randomize()
 load_game()
 queue_redraw()

func _process(delta: float) -> void:
 saved_hint_timer = max(0.0, saved_hint_timer - delta)
 for f in feedback:
  f.life -= delta
  f.pos.y -= delta * 28.0
 feedback = feedback.filter(func(f): return f.life > 0.0)
 if open:
  spawn_timer -= delta
  if spawn_timer <= 0.0:
   spawn_timer = max(0.8, 2.8 - level * 0.15 - staff * 0.25)
   add_customer()
  for c in waiting:
   c.patience -= delta
   var target := Vector2(150.0 + float(c.slot % 5) * 82.0, 160.0 + float(c.slot / 5) * 70.0)
   c.pos = c.pos.move_toward(target, delta * (110.0 + staff * 15.0))
  var before := waiting.size()
  waiting = waiting.filter(func(c): return c.patience > 0.0)
  if before > waiting.size():
   var n := before - waiting.size()
   lost += n
   reputation = max(0, reputation - n)
   add_feedback("-%d patience" % n, Vector2(420,210))
  if sale_timer <= 0.0 and not waiting.is_empty():
   sale_timer = max(0.35, 0.62 - staff * 0.04)
   serve_customer()
  sale_timer -= delta
 queue_redraw()

func add_customer() -> void:
 var max_wait := min(10, 3 + level + staff)
 if waiting.size() >= max_wait:
  lost += 1
  reputation = max(0, reputation - 1)
  message = "Shop is crowded. Customer leaves."
  add_feedback("Customer lost", Vector2(300,180))
  return
 var c: Dictionary = CUSTOMER_TYPES[randi() % CUSTOMER_TYPES.size()].duplicate()
 c.slot = waiting.size()
 c.pos = Vector2(610,430)
 c.patience = float(c.patience) + staff * 0.4
 waiting.append(c)

func find_product(customer: Dictionary) -> int:
 var best := -1
 var best_score := -1.0
 for i in PRODUCTS.size():
  if int(PRODUCTS[i].unlock) > level or stock[i] <= 0:
   continue
  var sell := float(PRODUCTS[i].price) * price_factor
  if sell > float(customer.budget):
   continue
  var score := float(PRODUCTS[i].pop) * demand * event_demand_bonus
  if PRODUCTS[i].pref == customer.pref: score += 3.5
  if price_factor > 1.15: score *= 0.72
  if supplier == 2 and PRODUCTS[i].pref == customer.pref: score *= 1.12
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
  message = "%s could not find a suitable product." % customer.name
  add_feedback("Lost sale", Vector2(300,180))
  return
 var p: Dictionary = PRODUCTS[i]
 var sell := int(round(float(p.price) * price_factor))
 var profit := max(1, int(round((sell - int(p.cost)) * event_profit_bonus)))
 stock[i] -= 1
 gold += sell
 revenue += sell
 served += 1
 xp += profit
 reputation = min(100, reputation + 1)
 message = "%s bought %s. +%dg" % [customer.name, p.name, profit]
 add_feedback("+%dg" % sell, Vector2(540,285))
 check_level()

func check_level() -> void:
 var need := level * 45
 if xp >= need and level < 10:
  xp -= need
  level += 1
  shelf_limit += 4
  shelf_count += 1
  message = "Shop Lv.%d! More shelf space unlocked." % level
  add_feedback("LEVEL UP!", Vector2(350,130))

func stock_total() -> int:
 var total := 0
 for n in stock: total += n
 return total

func restock(i: int, qty: int = 5) -> void:
 if open or settlement_visible or i < 0 or i >= PRODUCTS.size() or int(PRODUCTS[i].unlock) > level: return
 qty = min(qty, shelf_limit - stock_total())
 if qty <= 0:
  message = "Shelves are full."
  return
 var unit := int(round(float(PRODUCTS[i].cost) * float(SUPPLIERS[supplier].discount)))
 var total_cost := unit * qty
 if gold < total_cost:
  message = "Need %dg for this order." % total_cost
  return
 gold -= total_cost
 stock[i] += qty
 message = "%s: bought %d %s for %dg." % [SUPPLIERS[supplier].name,qty,PRODUCTS[i].name,total_cost]
 save_game()

func choose_supplier() -> void:
 if open or settlement_visible:
  message = "Close shop before changing supplier."
  return
 supplier = (supplier + 1) % SUPPLIERS.size()
 message = "Supplier: %s (%s)." % [SUPPLIERS[supplier].name,SUPPLIERS[supplier].label]

func hire_staff() -> void:
 if open or settlement_visible:
  message = "Close shop before hiring."
  return
 var cost := 80 + staff * 60
 if gold < cost:
  message = "Hiring costs %dg." % cost
  return
 gold -= cost
 staff += 1
 message = "Hired staff %d. Daily cost +%dg." % [staff,20 + staff * 5]
 save_game()

func generate_event() -> void:
 event_profit_bonus = 1.0
 event_demand_bonus = 1.0
 match randi() % 5:
  0: event_text = "Rainy day"; event_demand_bonus = 0.92
  1: event_text = "Weekend rush"; event_demand_bonus = 1.18
  2: event_text = "Local festival"; event_demand_bonus = 1.12
  3: event_text = "Supplier sale"; event_profit_bonus = 1.08
  _: event_text = "Normal market"

func toggle_shop() -> void:
 if settlement_visible: return
 open = not open
 if open:
  spawn_timer = 0.3
  message = "SHOP OPEN — %s." % event_text
 else:
  waiting.clear()
  message = "Shop closed. Tap NEXT DAY for settlement."
  save_game()

func next_day() -> void:
 if open:
  message = "Close the shop first."
  return
 if settlement_visible:
  settlement_visible = false
  day += 1
  served = 0
  lost = 0
  revenue = 0
  operating_cost = 0
  demand = randf_range(0.8,1.2)
  price_factor = clamp(price_factor + randf_range(-0.06,0.06),0.75,1.35)
  generate_event()
  message = "Day %d: %s. Ready to stock." % [day,event_text]
  save_game()
  return
 last_day_revenue = revenue
 last_day_cost = 10 + staff * (20 + staff * 5)
 last_day_profit = last_day_revenue - last_day_cost
 last_day_served = served
 last_day_lost = lost
 last_day_event = event_text
 gold -= last_day_cost
 operating_cost = last_day_cost
 settlement_visible = true
 message = "Day %d settled: %d g profit." % [day,last_day_profit]
 save_game()

func change_price(step: float) -> void:
 if open or settlement_visible:
  message = "Close shop before changing prices."
  return
 price_factor = clamp(price_factor + step,0.75,1.35)
 message = "Prices: %d%% of base." % int(price_factor * 100)
 save_game()

func expand() -> void:
 if open or settlement_visible:
  message = "Close shop before expanding."
  return
 var cost := level * 100
 if gold < cost:
  message = "Expansion costs %dg." % cost
  return
 gold -= cost
 shelf_limit += 8
 shelf_count += 1
 message = "Expanded! Shelf capacity %d." % shelf_limit
 save_game()

func add_feedback(text: String, at: Vector2) -> void:
 feedback.append({"text":text,"pos":at,"life":1.15})

func save_game() -> void:
 var data := {"gold":gold,"level":level,"xp":xp,"day":day,"stock":stock,"shelf_limit":shelf_limit,"reputation":reputation,"shelf_count":shelf_count,"staff":staff,"supplier":supplier,"event_text":event_text,"event_profit_bonus":event_profit_bonus,"event_demand_bonus":event_demand_bonus,"demand":demand,"price_factor":price_factor,"served":served,"lost":lost,"revenue":revenue,"operating_cost":operating_cost}
 var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify(data))
  saved_hint_timer = 1.5

func load_game() -> void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
 if not file: return
 var parsed = JSON.parse_string(file.get_as_text())
 if typeof(parsed) != TYPE_DICTIONARY: return
 gold = int(parsed.get("gold",gold)); level = int(parsed.get("level",level)); xp = int(parsed.get("xp",xp)); day = int(parsed.get("day",day))
 var saved_stock = parsed.get("stock",stock)
 if typeof(saved_stock) == TYPE_ARRAY:
  for i in min(saved_stock.size(),stock.size()): stock[i] = int(saved_stock[i])
 shelf_limit = int(parsed.get("shelf_limit",shelf_limit)); reputation = int(parsed.get("reputation",reputation)); shelf_count = int(parsed.get("shelf_count",shelf_count)); staff = int(parsed.get("staff",staff)); supplier = int(parsed.get("supplier",supplier))
 event_text = str(parsed.get("event_text",event_text)); event_profit_bonus = float(parsed.get("event_profit_bonus",event_profit_bonus)); event_demand_bonus = float(parsed.get("event_demand_bonus",event_demand_bonus)); demand = float(parsed.get("demand",demand)); price_factor = float(parsed.get("price_factor",price_factor)); served = int(parsed.get("served",served)); lost = int(parsed.get("lost",lost)); revenue = int(parsed.get("revenue",revenue)); operating_cost = int(parsed.get("operating_cost",operating_cost))
 message = "Save loaded. Welcome back to Day %d." % day

func reset_save() -> void:
 if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(SAVE_PATH)
 get_tree().reload_current_scene()

func _input(e: InputEvent) -> void:
 if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
  var p := e.position
  if settlement_visible:
   if Rect2(715,455,195,45).has_point(p): next_day()
   return
  if Rect2(715,125,195,48).has_point(p): toggle_shop(); return
  if Rect2(715,185,195,42).has_point(p): next_day(); return
  if Rect2(715,300,88,40).has_point(p): change_price(-0.05); return
  if Rect2(812,300,88,40).has_point(p): change_price(0.05); return
  if Rect2(715,355,195,40).has_point(p): choose_supplier(); return
  if Rect2(715,405,195,40).has_point(p): hire_staff(); return
  if Rect2(715,450,195,40).has_point(p): expand(); return
  for i in PRODUCTS.size():
   if Rect2(45 + (i % 4) * 160,360 + (i / 4) * 68,150,55).has_point(p): restock(i); return
 if e is InputEventKey and e.pressed and not e.echo:
  match e.keycode:
   KEY_SPACE: toggle_shop()
   KEY_N: next_day()
   KEY_U: expand()
   KEY_S: choose_supplier()
   KEY_H: hire_staff()
   KEY_MINUS: change_price(-0.05)
   KEY_EQUAL,KEY_PLUS: change_price(0.05)
   KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8: restock(e.keycode - KEY_1)
   KEY_F5: save_game()
   KEY_F9: load_game()
   KEY_F10: reset_save()

func button(rect: Rect2, text: String, size := 16, active := true) -> void:
 draw_rect(rect,Color("4f8a62") if active else Color("9aa3aa"),true)
 draw_string(ThemeDB.fallback_font,rect.position+Vector2(12,rect.size.y*0.67),text,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-24,size,Color.WHITE)

func _draw() -> void:
 draw_rect(Rect2(0,0,960,540),Color("e9edf0"),true)
 draw_rect(Rect2(0,0,960,72),Color("243447"),true)
 draw_string(ThemeDB.fallback_font,Vector2(28,46),"MY LITTLE SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(350,40),"DAY %d • Lv.%d" % [day,level],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("dbe7f2"))
 draw_string(ThemeDB.fallback_font,Vector2(350,60),"XP %d/%d • Rep %d • Staff %d" % [xp,level*45,reputation,staff],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b8cadb"))
 draw_string(ThemeDB.fallback_font,Vector2(780,43),"%d g" % gold,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("f4d35e"))
 draw_rect(Rect2(25,90,650,245),Color("f8f4ed"),true)
 draw_rect(Rect2(25,90,650,12),Color("c8a77d"),true)
 draw_string(ThemeDB.fallback_font,Vector2(45,125),"YOUR SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("695747"))
 for s in shelf_count:
  var sx := 45.0 + float(s % 2) * 300.0
  var sy := 140.0 + float(s / 2) * 78.0
  draw_rect(Rect2(sx,sy,250,62),Color("e2d2bb"),true)
  draw_rect(Rect2(sx+8,sy+8,234,46),Color("fffaf1"),true)
  var a := (s*2)%PRODUCTS.size()
  draw_string(ThemeDB.fallback_font,Vector2(sx+18,sy+28),PRODUCTS[a].name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("51463c"))
  draw_string(ThemeDB.fallback_font,Vector2(sx+18,sy+48),"%d" % stock[a],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("7a6a5a"))
  if a+1 < PRODUCTS.size():
   draw_string(ThemeDB.fallback_font,Vector2(sx+125,sy+28),PRODUCTS[a+1].name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("51463c"))
   draw_string(ThemeDB.fallback_font,Vector2(sx+125,sy+48),"%d" % stock[a+1],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("7a6a5a"))
 draw_rect(Rect2(520,285,130,35),Color("9a7650"),true)
 draw_string(ThemeDB.fallback_font,Vector2(545,308),"CHECKOUT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
 draw_rect(Rect2(45,310,90,25),Color("7aa6c2"),true)
 draw_string(ThemeDB.fallback_font,Vector2(58,328),"ENTRANCE",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
 for c in waiting:
  draw_circle(c.pos,12,Color("e0a37e")); draw_rect(Rect2(c.pos.x-13,c.pos.y+11,26,25),Color("6c8db5"),true)
  draw_string(ThemeDB.fallback_font,c.pos+Vector2(-5,5),c.icon,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
 draw_rect(Rect2(695,90,235,395),Color.WHITE,true)
 draw_string(ThemeDB.fallback_font,Vector2(715,115),"MANAGEMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("526170"))
 button(Rect2(715,125,195,48),"CLOSE SHOP" if open else "OPEN SHOP",19,open)
 button(Rect2(715,185,195,42),"DAY SETTLEMENT [N]",15)
 draw_string(ThemeDB.fallback_font,Vector2(715,255),"Stock %d/%d" % [stock_total(),shelf_limit],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("4d5965"))
 draw_string(ThemeDB.fallback_font,Vector2(715,276),"Revenue %d g • Cost %d g" % [revenue,operating_cost],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
 button(Rect2(715,300,88,40),"-5%",15); button(Rect2(812,300,88,40),"+5%",15)
 draw_string(ThemeDB.fallback_font,Vector2(715,350),"Price %d%%" % int(price_factor*100),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
 button(Rect2(715,355,195,40),"SUPPLIER: %s" % SUPPLIERS[supplier].name,13)
 button(Rect2(715,405,195,40),"HIRE STAFF [H]",13)
 button(Rect2(715,450,195,40),"EXPAND [U]",13)
 for i in PRODUCTS.size():
  var unlocked := int(PRODUCTS[i].unlock) <= level
  var r := Rect2(45 + (i % 4) * 160,360 + (i / 4) * 68,150,55)
  draw_rect(r,Color("d4dde3") if unlocked else Color("b5bbc0"),true)
  draw_string(ThemeDB.fallback_font,r.position+Vector2(10,21),PRODUCTS[i].name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("34404a"))
  draw_string(ThemeDB.fallback_font,r.position+Vector2(10,42),"Stock %d • Buy x5" % stock[i],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("56636e"))
 draw_rect(Rect2(25,510,650,25),Color("273746"),true)
 draw_string(ThemeDB.fallback_font,Vector2(38,528),message,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
 if saved_hint_timer > 0.0: draw_string(ThemeDB.fallback_font,Vector2(610,528),"SAVED",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b8e0c2"))
 for f in feedback:
  draw_string(ThemeDB.fallback_font,f.pos,f.text,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("2d6b42"))
 if settlement_visible: draw_settlement()

func draw_settlement() -> void:
 draw_rect(Rect2(90,75,780,410),Color("1e2a35"),true)
 draw_rect(Rect2(110,95,740,370),Color("f8f4ed"),true)
 draw_string(ThemeDB.fallback_font,Vector2(145,135),"DAY %d SETTLEMENT" % day,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("243447"))
 draw_string(ThemeDB.fallback_font,Vector2(145,165),last_day_event,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("756657"))
 draw_string(ThemeDB.fallback_font,Vector2(150,215),"Revenue",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("4d5965")); draw_string(ThemeDB.fallback_font,Vector2(550,215),"%d g" % last_day_revenue,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("2d6b42"))
 draw_string(ThemeDB.fallback_font,Vector2(150,250),"Operating cost",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("4d5965")); draw_string(ThemeDB.fallback_font,Vector2(550,250),"-%d g" % last_day_cost,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("9a4d4d"))
 draw_string(ThemeDB.fallback_font,Vector2(150,290),"Profit",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("243447")); draw_string(ThemeDB.fallback_font,Vector2(550,290),"%d g" % last_day_profit,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("243447"))
 draw_string(ThemeDB.fallback_font,Vector2(150,330),"Customers served / lost",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("4d5965")); draw_string(ThemeDB.fallback_font,Vector2(550,330),"%d / %d" % [last_day_served,last_day_lost],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("4d5965"))
 draw_string(ThemeDB.fallback_font,Vector2(150,365),"Cash",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("4d5965")); draw_string(ThemeDB.fallback_font,Vector2(550,365),"%d g" % gold,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("243447"))
 button(Rect2(630,410,190,45),"CONTINUE DAY %d" % (day+1),14)
