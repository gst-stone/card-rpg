extends Node2D

# My Little Shop v0.5 - suppliers, popularity, events, staff and operating costs.
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

func _ready() -> void:
 randomize()
 queue_redraw()

func _process(delta: float) -> void:
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
   lost += before - waiting.size()
   reputation = max(0, reputation - (before - waiting.size()))
  if sale_timer <= 0.0 and not waiting.is_empty():
   sale_timer = 0.62
   serve_customer()
  sale_timer -= delta
 queue_redraw()

func add_customer() -> void:
 var max_wait := min(10, 3 + level + staff)
 if waiting.size() >= max_wait:
  lost += 1
  reputation = max(0, reputation - 1)
  message = "Shop is crowded. Customer leaves."
  return
 var c: Dictionary = CUSTOMER_TYPES[randi() % CUSTOMER_TYPES.size()].duplicate()
 c.slot = waiting.size()
 c.pos = Vector2(610, 430)
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
  if PRODUCTS[i].pref == customer.pref:
   score += 3.5
  if price_factor > 1.15:
   score *= 0.72
  if supplier == 2 and PRODUCTS[i].pref == customer.pref:
   score *= 1.12
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
 message = "%s bought %s. Profit +%dg." % [customer.name, p.name, profit]
 check_level()

func check_level() -> void:
 var need := level * 45
 if xp >= need and level < 10:
  xp -= need
  level += 1
  shelf_limit += 4
  shelf_count += 1
  message = "Shop Lv.%d! More shelf space unlocked." % level

func stock_total() -> int:
 var total := 0
 for n in stock:
  total += n
 return total

func restock(i: int, qty: int = 5) -> void:
 if open or i < 0 or i >= PRODUCTS.size() or int(PRODUCTS[i].unlock) > level:
  return
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
 message = "%s supplier: bought %d %s for %dg." % [SUPPLIERS[supplier].name,qty,PRODUCTS[i].name,total_cost]

func choose_supplier() -> void:
 if open:
  message = "Close shop before changing supplier."
  return
 supplier = (supplier + 1) % SUPPLIERS.size()
 message = "Supplier: %s (%s)." % [SUPPLIERS[supplier].name,SUPPLIERS[supplier].label]

func hire_staff() -> void:
 if open:
  message = "Close shop before hiring."
  return
 var cost := 80 + staff * 60
 if gold < cost:
  message = "Hiring costs %dg." % cost
  return
 gold -= cost
 staff += 1
 message = "Hired staff member %d. Daily cost +%dg." % [staff,20 + staff * 5]

func generate_event() -> void:
 event_profit_bonus = 1.0
 event_demand_bonus = 1.0
 var r := randi() % 5
 match r:
  0:
   event_text = "Rainy day"
   event_demand_bonus = 0.92
  1:
   event_text = "Weekend rush"
   event_demand_bonus = 1.18
  2:
   event_text = "Local festival"
   event_demand_bonus = 1.12
  3:
   event_text = "Supplier sale"
   event_profit_bonus = 1.08
  _:
   event_text = "Normal market"

func toggle_shop() -> void:
 open = not open
 if open:
  spawn_timer = 0.3
  message = "SHOP OPEN — %s." % event_text
 else:
  waiting.clear()
  message = "Shop closed. Review today's profit."

func next_day() -> void:
 if open:
  message = "Close the shop first."
  return
 var daily_staff_cost := staff * (20 + staff * 5)
 operating_cost = 10 + daily_staff_cost
 gold -= operating_cost
 generate_event()
 day += 1
 served = 0
 lost = 0
 revenue = 0
 demand = randf_range(0.8,1.2)
 price_factor = clamp(price_factor + randf_range(-0.06,0.06),0.75,1.35)
 message = "Day %d: %s. Operating cost %dg." % [day,event_text,operating_cost]

func change_price(step: float) -> void:
 if open:
  message = "Close shop before changing prices."
  return
 price_factor = clamp(price_factor + step,0.75,1.35)
 message = "Prices: %d%% of base." % int(price_factor * 100)

func expand() -> void:
 if open:
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

func _input(e: InputEvent) -> void:
 if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
  var p := e.position
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
   KEY_R: get_tree().reload_current_scene()

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
  draw_circle(c.pos,12,Color("e0a37e"))
  draw_rect(Rect2(c.pos.x-13,c.pos.y+11,26,25),Color("6c8db5"),true)
  draw_string(ThemeDB.fallback_font,c.pos+Vector2(-5,5),c.icon,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
 draw_rect(Rect2(695,90,235,395),Color.WHITE,true)
 draw_string(ThemeDB.fallback_font,Vector2(715,115),"MANAGEMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("526170"))
 draw_rect(Rect2(715,125,195,48),Color("b85c5c") if open else Color("4f8a62"),true)
 draw_string(ThemeDB.fallback_font,Vector2(750,156),"CLOSE SHOP" if open else "OPEN SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
 draw_rect(Rect2(715,185,195,42),Color("657b92"),true)
 draw_string(ThemeDB.fallback_font,Vector2(750,212),"NEXT DAY [N]",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(715,255),"Stock %d/%d" % [stock_total(),shelf_limit],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("4d5965"))
 draw_string(ThemeDB.fallback_font,Vector2(715,276),"Revenue %d g • Cost %d g" % [revenue,operating_cost],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
 draw_string(ThemeDB.fallback_font,Vector2(715,294),"Event: %s" % event_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
 draw_rect(Rect2(715,300,88,40),Color("7c8792"),true)
 draw_string(ThemeDB.fallback_font,Vector2(742,326),"- PRICE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
 draw_rect(Rect2(812,300,88,40),Color("7c8792"),true)
 draw_string(ThemeDB.fallback_font,Vector2(839,326),"+ PRICE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
 draw_rect(Rect2(715,355,195,40),Color("8b6fa8"),true)
 draw_string(ThemeDB.fallback_font,Vector2(738,381),"SUPPLIER [S]",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
 draw_rect(Rect2(715,405,195,40),Color("5e9271"),true)
 draw_string(ThemeDB.fallback_font,Vector2(740,431),"HIRE STAFF [H]",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
 draw_rect(Rect2(715,450,195,40),Color("d18b45"),true)
 draw_string(ThemeDB.fallback_font,Vector2(742,476),"EXPAND [U] %dg" % (level*100),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(45,347),"RESTOCK • supplier: %s" % SUPPLIERS[supplier].name,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("526170"))
 for i in PRODUCTS.size():
  var p: Dictionary = PRODUCTS[i]
  var unlocked := int(p.unlock)<=level
  var x := 45.0+(i%4)*160
  var y := 360.0+(i/4)*68
  draw_rect(Rect2(x,y,150,55),Color.WHITE if unlocked else Color("d6dadd"),true)
  draw_string(ThemeDB.fallback_font,Vector2(x+10,y+21),"%d. %s" % [i+1,p.name],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("33404c") if unlocked else Color("777d82"))
  if unlocked:
   var unit := int(round(float(p.cost)*float(SUPPLIERS[supplier].discount)))
   draw_string(ThemeDB.fallback_font,Vector2(x+10,y+42),"Stock %d • buy %dg" % [stock[i],unit],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("63717e"))
  else:
   draw_string(ThemeDB.fallback_font,Vector2(x+10,y+40),"Unlock Lv.%d" % p.unlock,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("777d82"))
 draw_rect(Rect2(30,500,900,28),Color("273849"),true)
 draw_string(ThemeDB.fallback_font,Vector2(45,520),message,HORIZONTAL_ALIGNMENT_LEFT,860,14,Color.WHITE)
