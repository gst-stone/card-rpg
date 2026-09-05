extends Node2D

# My Little Shop v1.1 — visual polish pass for the management prototype.
# Keyboard: SPACE open/close, N next day, 1-8 restock, +/- price, U supplier,
# H staff, E expand, D dashboard, M missions, F5 save, F9 load, F10 reset.
const SAVE_PATH := "user://my_little_shop_v1.json"
const VERSION := "1.1.0"
const PRODUCTS := [
 {"name":"Water","cost":2,"price":4,"unlock":1,"pref":"daily","pop":1.0},
 {"name":"Bread","cost":3,"price":6,"unlock":1,"pref":"daily","pop":0.95},
 {"name":"Apple","cost":4,"price":8,"unlock":1,"pref":"healthy","pop":0.80},
 {"name":"Drink","cost":5,"price":10,"unlock":2,"pref":"snack","pop":0.75},
 {"name":"Noodles","cost":6,"price":12,"unlock":2,"pref":"quick","pop":0.70},
 {"name":"Milk","cost":8,"price":16,"unlock":3,"pref":"healthy","pop":0.60},
 {"name":"Cookie","cost":10,"price":20,"unlock":4,"pref":"snack","pop":0.52},
 {"name":"Hotpot","cost":20,"price":40,"unlock":5,"pref":"quick","pop":0.40}
]
const CUSTOMER_TYPES := [
 {"name":"Worker","icon":"W","pref":"quick","budget":18,"patience":8.0},
 {"name":"Parent","icon":"P","pref":"healthy","budget":22,"patience":9.0},
 {"name":"Student","icon":"S","pref":"snack","budget":14,"patience":7.0},
 {"name":"Neighbor","icon":"N","pref":"daily","budget":12,"patience":8.5}
]
const SUPPLIERS := [
 {"name":"Local","discount":1.00,"label":"stable"},
 {"name":"Wholesale","discount":0.88,"label":"-12% cost"},
 {"name":"Premium","discount":1.08,"label":"+12% match"}
]
const EVENTS := ["Normal market","Rainy day","Weekend rush","Local festival","Supplier sale","Heat wave"]
const MISSIONS := [
 {"name":"First Sale","text":"Serve 5 customers","target":5,"reward":50},
 {"name":"Busy Shop","text":"Serve 25 customers","target":25,"reward":100},
 {"name":"Popular Store","text":"Reach 70 reputation","target":70,"reward":150},
 {"name":"Big Day","text":"Make 150g in one day","target":150,"reward":120}
]

var gold := 100
var level := 1
var xp := 0
var day := 1
var stock: Array[int] = [6,6,6,0,0,0,0,0]
var shelf_limit := 24
var shelf_count := 3
var reputation := 50
var staff := 0
var supplier := 0
var price_factor := 1.0
var demand := 1.0
var event_text := "Normal market"
var event_demand_bonus := 1.0
var event_profit_bonus := 1.0
var open := false
var waiting: Array[Dictionary] = []
var spawn_timer := 0.0
var sale_timer := 0.0
var served := 0
var lost := 0
var revenue := 0
var cost_today := 0
var lifetime_revenue := 0
var lifetime_served := 0
var lifetime_days := 0
var best_day_revenue := 0
var settlement_visible := false
var dashboard_visible := false
var missions_visible := false
var tutorial_step := 0
var bankrupt := false
var message := "Welcome! Stock your shelves, then open the shop."
var feedback: Array[Dictionary] = []
var mission_done: Array[bool] = [false,false,false,false]
var toast := ""
var toast_time := 0.0
var visual_time := 0.0
var gold_pulse := 0.0

func _ready() -> void:
 randomize()
 load_game()
 if lifetime_days == 0 and lifetime_served == 0:
  tutorial_step = 1
 queue_redraw()

func _process(delta: float) -> void:
 visual_time += delta
 toast_time = max(0.0, toast_time - delta)
 gold_pulse = max(0.0, gold_pulse - delta * 2.5)
 for f in feedback:
  f.life -= delta
  f.pos.y -= delta * 25.0
 feedback = feedback.filter(func(f): return f.life > 0.0)
 if open and not settlement_visible and not bankrupt and not dashboard_visible and not missions_visible:
  spawn_timer -= delta
  if spawn_timer <= 0.0:
   spawn_timer = max(0.65, 2.45 - level * 0.12 - staff * 0.20)
   add_customer()
  for c in waiting:
   c.patience -= delta
   var target := Vector2(95.0 + float(c.slot % 5) * 105.0, 165.0 + float(c.slot / 5) * 75.0)
   c.pos = c.pos.move_toward(target, delta * (105.0 + staff * 14.0))
  var before := waiting.size()
  waiting = waiting.filter(func(c): return c.patience > 0.0)
  if before > waiting.size():
   var n := before - waiting.size()
   lost += n
   reputation = max(0, reputation - n)
   add_feedback("-%d lost" % n, Vector2(300,180))
  sale_timer -= delta
  if sale_timer <= 0.0 and not waiting.is_empty():
   sale_timer = max(0.30, 0.60 - staff * 0.035)
   serve_customer()
 queue_redraw()

func add_customer() -> void:
 var limit := min(12, 4 + level + staff)
 if waiting.size() >= limit:
  lost += 1
  reputation = max(0, reputation - 1)
  show_toast("Crowded — customer leaves")
  return
 var c: Dictionary = CUSTOMER_TYPES[randi() % CUSTOMER_TYPES.size()].duplicate()
 c.slot = waiting.size()
 c.pos = Vector2(610,430)
 c.patience = float(c.patience) + staff * 0.45
 waiting.append(c)

func find_product(customer: Dictionary) -> int:
 var best := -1
 var best_score := -1.0
 for i in PRODUCTS.size():
  var p: Dictionary = PRODUCTS[i]
  if int(p.unlock) > level or stock[i] <= 0: continue
  var sell := float(p.price) * price_factor
  if sell > float(customer.budget): continue
  var score := float(p.pop) * demand * event_demand_bonus
  if p.pref == customer.pref: score += 3.5
  if price_factor > 1.15: score *= 0.72
  if supplier == 2 and p.pref == customer.pref: score *= 1.12
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
  add_feedback("Lost sale", Vector2(320,190))
  return
 var p: Dictionary = PRODUCTS[i]
 var sell := int(round(float(p.price) * price_factor))
 var profit := max(1, int(round((sell - int(p.cost)) * event_profit_bonus)))
 stock[i] -= 1
 gold += sell
 revenue += sell
 lifetime_revenue += sell
 served += 1
 lifetime_served += 1
 xp += profit
 reputation = min(100, reputation + 1)
 gold_pulse = 1.0
 add_feedback("+%dg" % sell, Vector2(520,285))
 message = "%s bought %s" % [customer.name, p.name]
 if tutorial_step == 3: tutorial_step = 4
 check_level()
 check_missions()

func check_level() -> void:
 while level < 10 and xp >= level * 45:
  xp -= level * 45
  level += 1
  shelf_limit += 4
  shelf_count += 1
  show_toast("LEVEL %d! +4 shelf capacity" % level)

func stock_total() -> int:
 var n := 0
 for x in stock: n += x
 return n

func restock(i: int, qty := 5) -> void:
 if open or settlement_visible or bankrupt or dashboard_visible or missions_visible or i < 0 or i >= PRODUCTS.size(): return
 if int(PRODUCTS[i].unlock) > level:
  show_toast("Unlocks at level %d" % PRODUCTS[i].unlock)
  return
 qty = min(qty, shelf_limit - stock_total())
 if qty <= 0:
  show_toast("Shelves are full")
  return
 var unit := int(round(float(PRODUCTS[i].cost) * float(SUPPLIERS[supplier].discount)))
 var total := unit * qty
 if gold < total:
  show_toast("Need %dg" % total)
  return
 gold -= total
 stock[i] += qty
 message = "Bought %d %s for %dg" % [qty, PRODUCTS[i].name, total]
 if tutorial_step == 1: tutorial_step = 2
 save_game()

func choose_supplier() -> void:
 if open or settlement_visible or bankrupt: return
 supplier = (supplier + 1) % SUPPLIERS.size()
 message = "Supplier: %s (%s)" % [SUPPLIERS[supplier].name, SUPPLIERS[supplier].label]
 save_game()

func hire_staff() -> void:
 if open or settlement_visible or bankrupt: return
 var price := 80 + staff * 60
 if gold < price:
  show_toast("Hiring costs %dg" % price)
  return
 gold -= price
 staff += 1
 message = "Staff %d hired" % staff
 save_game()

func expand_store() -> void:
 if open or settlement_visible or bankrupt: return
 var price := level * 100
 if gold < price:
  show_toast("Expansion costs %dg" % price)
  return
 gold -= price
 shelf_limit += 8
 shelf_count += 1
 message = "Store expanded to %d capacity" % shelf_limit
 save_game()

func change_price(step: float) -> void:
 if open or settlement_visible or bankrupt: return
 price_factor = clamp(price_factor + step, 0.75, 1.35)
 message = "Selling price: %d%%" % int(price_factor * 100.0)
 save_game()

func generate_event() -> void:
 event_demand_bonus = 1.0
 event_profit_bonus = 1.0
 event_text = EVENTS[randi() % EVENTS.size()]
 match event_text:
  "Rainy day": event_demand_bonus = 0.90
  "Weekend rush": event_demand_bonus = 1.20
  "Local festival": event_demand_bonus = 1.12
  "Supplier sale": event_profit_bonus = 1.10
  "Heat wave": event_demand_bonus = 0.96

func toggle_shop() -> void:
 if settlement_visible or bankrupt or dashboard_visible or missions_visible: return
 open = not open
 if open:
  spawn_timer = 0.25
  message = "SHOP OPEN • %s" % event_text
  if tutorial_step == 2: tutorial_step = 3
 else:
  waiting.clear()
  message = "Shop closed — settle the day"
  save_game()

func next_day() -> void:
 if bankrupt: return
 if open:
  show_toast("Close the shop first")
  return
 if not settlement_visible:
  finish_day()
 else:
  settlement_visible = false
  day += 1
  served = 0
  lost = 0
  revenue = 0
  cost_today = 0
  demand = randf_range(0.82, 1.18)
  price_factor = clamp(price_factor + randf_range(-0.05, 0.05), 0.75, 1.35)
  generate_event()
  message = "Day %d • %s" % [day, event_text]
  save_game()

func finish_day() -> void:
 var expense := 10 + staff * (20 + staff * 5)
 cost_today = expense
 gold -= expense
 best_day_revenue = max(best_day_revenue, revenue)
 lifetime_days += 1
 settlement_visible = true
 open = false
 message = "Day %d complete • Profit %dg" % [day, revenue - expense]
 if tutorial_step == 4: tutorial_step = 0
 check_missions()
 if gold < 0:
  bankrupt = true
  gold = 0
  settlement_visible = false
  message = "The shop ran out of cash. Restart and try a leaner strategy."
 save_game()

func check_missions() -> void:
 for i in MISSIONS.size():
  if mission_done[i]: continue
  var target := int(MISSIONS[i].target)
  var done := false
  if i == 0: done = lifetime_served >= target
  elif i == 1: done = lifetime_served >= target
  elif i == 2: done = reputation >= target
  elif i == 3: done = best_day_revenue >= target
  if done:
   mission_done[i] = true
   gold += int(MISSIONS[i].reward)
   gold_pulse = 1.0
   show_toast("Mission complete +%dg" % MISSIONS[i].reward)

func mission_progress(i: int) -> int:
 if i == 0 or i == 1: return lifetime_served
 if i == 2: return reputation
 return best_day_revenue

func show_toast(t: String) -> void:
 toast = t
 toast_time = 2.0
 message = t

func add_feedback(text: String, at: Vector2) -> void:
 feedback.append({"text":text,"pos":at,"life":1.1})

func save_game() -> void:
 var data := {"version":VERSION,"gold":gold,"level":level,"xp":xp,"day":day,"stock":stock,"shelf_limit":shelf_limit,"shelf_count":shelf_count,"reputation":reputation,"staff":staff,"supplier":supplier,"price_factor":price_factor,"demand":demand,"event_text":event_text,"event_demand_bonus":event_demand_bonus,"event_profit_bonus":event_profit_bonus,"served":served,"lost":lost,"revenue":revenue,"cost_today":cost_today,"lifetime_revenue":lifetime_revenue,"lifetime_served":lifetime_served,"lifetime_days":lifetime_days,"best_day_revenue":best_day_revenue,"mission_done":mission_done,"tutorial_step":tutorial_step}
 var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(data))

func load_game() -> void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
 if not f: return
 var d = JSON.parse_string(f.get_as_text())
 if typeof(d) != TYPE_DICTIONARY: return
 gold = int(d.get("gold", gold)); level = int(d.get("level", level)); xp = int(d.get("xp", xp)); day = int(d.get("day", day))
 var s = d.get("stock", stock)
 if typeof(s) == TYPE_ARRAY:
  for i in min(s.size(), stock.size()): stock[i] = max(0, int(s[i]))
 shelf_limit = max(24, int(d.get("shelf_limit", shelf_limit))); shelf_count = max(3, int(d.get("shelf_count", shelf_count)))
 reputation = clamp(int(d.get("reputation", reputation)), 0, 100); staff = max(0, int(d.get("staff", staff))); supplier = clamp(int(d.get("supplier", supplier)), 0, SUPPLIERS.size() - 1)
 price_factor = clamp(float(d.get("price_factor", price_factor)), 0.75, 1.35); demand = float(d.get("demand", demand)); event_text = str(d.get("event_text", event_text)); event_demand_bonus = float(d.get("event_demand_bonus", event_demand_bonus)); event_profit_bonus = float(d.get("event_profit_bonus", event_profit_bonus))
 served = max(0, int(d.get("served", served))); lost = max(0, int(d.get("lost", lost))); revenue = max(0, int(d.get("revenue", revenue))); cost_today = max(0, int(d.get("cost_today", cost_today)))
 lifetime_revenue = max(0, int(d.get("lifetime_revenue", lifetime_revenue))); lifetime_served = max(0, int(d.get("lifetime_served", lifetime_served))); lifetime_days = max(0, int(d.get("lifetime_days", lifetime_days))); best_day_revenue = max(0, int(d.get("best_day_revenue", best_day_revenue)))
 var md = d.get("mission_done", mission_done)
 if typeof(md) == TYPE_ARRAY:
  for i in min(md.size(), mission_done.size()): mission_done[i] = bool(md[i])
 tutorial_step = int(d.get("tutorial_step", tutorial_step))
 message = "Save loaded • Day %d" % day

func reset_save() -> void:
 if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(SAVE_PATH)
 get_tree().reload_current_scene()

func _input(e: InputEvent) -> void:
 if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
  var p := e.position
  if bankrupt:
   if Rect2(705,455,220,55).has_point(p): reset_save()
   return
  if settlement_visible:
   if Rect2(705,455,220,55).has_point(p): next_day()
   return
  if dashboard_visible:
   if Rect2(365,440,220,45).has_point(p): dashboard_visible = false
   return
  if missions_visible:
   if Rect2(365,465,220,45).has_point(p): missions_visible = false
   return
  if Rect2(705,120,220,50).has_point(p): toggle_shop(); return
  if Rect2(705,180,220,42).has_point(p): next_day(); return
  if Rect2(705,230,105,42).has_point(p): dashboard_visible = true; return
  if Rect2(815,230,110,42).has_point(p): missions_visible = true; return
  if Rect2(705,295,100,42).has_point(p): change_price(-0.05); return
  if Rect2(815,295,110,42).has_point(p): change_price(0.05); return
  if Rect2(705,345,220,42).has_point(p): choose_supplier(); return
  if Rect2(705,395,220,42).has_point(p): hire_staff(); return
  if Rect2(705,445,220,42).has_point(p): expand_store(); return
  for i in PRODUCTS.size():
   if Rect2(35+(i%4)*165,380+(i/4)*65,155,55).has_point(p): restock(i); return
 if e is InputEventKey and e.pressed and not e.echo:
  match e.keycode:
   KEY_SPACE: toggle_shop()
   KEY_N: next_day()
   KEY_D: dashboard_visible = not dashboard_visible
   KEY_M: missions_visible = not missions_visible
   KEY_MINUS: change_price(-0.05)
   KEY_EQUAL, KEY_PLUS: change_price(0.05)
   KEY_U: choose_supplier()
   KEY_H: hire_staff()
   KEY_E: expand_store()
   KEY_F5: save_game(); show_toast("Saved")
   KEY_F9: load_game(); show_toast("Loaded")
   KEY_F10: reset_save()
   KEY_1: restock(0)
   KEY_2: restock(1)
   KEY_3: restock(2)
   KEY_4: restock(3)
   KEY_5: restock(4)
   KEY_6: restock(5)
   KEY_7: restock(6)
   KEY_8: restock(7)

func panel(rect: Rect2, title: String) -> void:
 draw_rect(rect, Color("18202a"), true)
 draw_rect(rect, Color("526273"), false, 2.0)
 draw_string(ThemeDB.fallback_font, rect.position + Vector2(16,26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2f5f7"))

func button(rect: Rect2, text: String, active := false) -> void:
 var lift := 3.0 if active else 0.0
 draw_rect(Rect2(rect.position+Vector2(0,lift),rect.size), Color("365b4b") if active else Color("263442"), true)
 draw_rect(Rect2(rect.position+Vector2(0,lift),rect.size), Color("7890a5"), false, 1.0)
 draw_string(ThemeDB.fallback_font, rect.get_center()+Vector2(0,6+lift), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x-12, 15, Color("ffffff"))

func draw_product_icon(center: Vector2, index: int, scale := 1.0) -> void:
 var s := 18.0 * scale
 match index:
  0:
   draw_rect(Rect2(center+Vector2(-s*0.35,-s),Vector2(s*0.7,s*1.65)),Color("7db7d7"),true)
   draw_circle(center+Vector2(0,-s),s*0.35,Color("d7edf8"))
  1:
   draw_circle(center, s*0.85, Color("c9965b"))
   draw_line(center+Vector2(-s*0.5,0),center+Vector2(s*0.5,0),Color("8b623c"),2.0)
  2:
   draw_circle(center,s*0.85,Color("c95e58"))
   draw_circle(center+Vector2(5,-8)*scale,s*0.28,Color("5d9b5f"))
  3:
   draw_rect(Rect2(center+Vector2(-s*0.65,-s),Vector2(s*1.3,s*1.9)),Color("5e9ac1"),true)
   draw_rect(Rect2(center+Vector2(-s*0.45,-s*0.75),Vector2(s*0.9,s*0.25)),Color("e4f0f5"),true)
  4:
   draw_rect(Rect2(center+Vector2(-s*0.9,-s*0.35),Vector2(s*1.8,s*0.9)),Color("d2a05c"),true)
   draw_line(center+Vector2(-s*0.55,-s*0.15),center+Vector2(s*0.55,-s*0.15),Color("8b633c"),2.0)
  5:
   draw_circle(center,s*0.9,Color("f0e0b4"))
   draw_arc(center,s*0.65,0,TAU,24,Color("c9aa72"),2.0)
  6:
   draw_circle(center,s*0.8,Color("d8a15e"))
   draw_circle(center+Vector2(-5,-4)*scale,s*0.12,Color("8d633b"))
   draw_circle(center+Vector2(5,4)*scale,s*0.12,Color("8d633b"))
  7:
   draw_circle(center,s*0.95,Color("b56c5c"))
   draw_arc(center,s*0.55,0,TAU,20,Color("e8c08b"),3.0)

func draw_customer(c: Dictionary) -> void:
 var pos: Vector2 = c.pos
 var pulse := sin(visual_time*3.0+float(c.slot))*1.2
 var body_color := Color("4e789f")
 var head_color := Color("d9a27e")
 match str(c.icon):
  "P": body_color = Color("8a607e"); head_color = Color("e0aa87")
  "S": body_color = Color("6d8b62"); head_color = Color("d39b76")
  "N": body_color = Color("8b7555"); head_color = Color("dda982")
 draw_circle(pos+Vector2(0,pulse),20,Color("111922"))
 draw_circle(pos+Vector2(0,-5+pulse),11,head_color)
 draw_rect(Rect2(pos+Vector2(-12,7+pulse),Vector2(24,18)),body_color,true)
 draw_circle(pos+Vector2(-4,-7+pulse),1.5,Color("26313a"))
 draw_circle(pos+Vector2(4,-7+pulse),1.5,Color("26313a"))
 draw_string(ThemeDB.fallback_font,pos+Vector2(-25,40),str(c.name),HORIZONTAL_ALIGNMENT_CENTER,50,11,Color("c6d2db"))
 var patience := clamp(float(c.patience)/10.0,0.0,1.0)
 draw_rect(Rect2(pos+Vector2(-18,46),Vector2(36,4)),Color("303b45"),true)
 draw_rect(Rect2(pos+Vector2(-18,46),Vector2(36*patience,4)),Color("8bcf9a") if patience>0.35 else Color("d98a7e"),true)

func _draw() -> void:
 draw_rect(Rect2(0,0,960,540), Color("0d131a"), true)
 draw_rect(Rect2(0,0,960,72), Color("17222d"), true)
 draw_string(ThemeDB.fallback_font, Vector2(28,34), "MY LITTLE SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("ffffff"))
 draw_string(ThemeDB.fallback_font, Vector2(28,58), "Day %d  •  Level %d" % [day,level], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("aebdca"))
 var event_box := Rect2(205,18,230,36)
 draw_rect(event_box,Color("223442"),true)
 draw_string(ThemeDB.fallback_font,event_box.get_center()+Vector2(0,5),event_text,HORIZONTAL_ALIGNMENT_CENTER,210,13,Color("d8e5ec"))
 draw_string(ThemeDB.fallback_font, Vector2(690,32), "%dg" % gold, HORIZONTAL_ALIGNMENT_RIGHT, 235, 24+gold_pulse*3.0, Color("f5d77a"))
 draw_string(ThemeDB.fallback_font, Vector2(690,55), "Rep %d   XP %d/%d" % [reputation,xp,level*45], HORIZONTAL_ALIGNMENT_RIGHT, 235, 14, Color("b9c7d2"))
 draw_rect(Rect2(690,63,235,4),Color("293743"),true)
 draw_rect(Rect2(690,63,235*float(reputation)/100.0,4),Color("79b891"),true)
 panel(Rect2(25,90,650,255), "SHOP FLOOR")
 draw_string(ThemeDB.fallback_font, Vector2(42,120), "Queue: %d/%d    Served: %d    Lost: %d" % [waiting.size(),min(12,4+level+staff),served,lost], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d6e0e7"))
 draw_rect(Rect2(42,135,615,185),Color("121b23"),true)
 for x in range(60,650,45): draw_line(Vector2(x,135),Vector2(x,320),Color("1a2731"),1.0)
 for y in range(150,321,35): draw_line(Vector2(42,y),Vector2(657,y),Color("1a2731"),1.0)
 for s in shelf_count:
  var sx := 55.0 + float(s%2)*300.0
  var sy := 145.0 + float(s/2)*52.0
  draw_rect(Rect2(sx,sy,275,42),Color("344b43"),true)
  draw_rect(Rect2(sx+5,sy+5,265,32),Color("1d2929"),true)
  var a := (s*2)%PRODUCTS.size()
  draw_product_icon(Vector2(sx+24,sy+21),a,0.55)
  draw_string(ThemeDB.fallback_font,Vector2(sx+42,sy+26),PRODUCTS[a].name+" ×"+str(stock[a]),HORIZONTAL_ALIGNMENT_LEFT,90,11,Color("dbe8e0"))
  if a+1<PRODUCTS.size():
   draw_product_icon(Vector2(sx+153,sy+21),a+1,0.55)
   draw_string(ThemeDB.fallback_font,Vector2(sx+171,sy+26),PRODUCTS[a+1].name+" ×"+str(stock[a+1]),HORIZONTAL_ALIGNMENT_LEFT,90,11,Color("dbe8e0"))
 draw_rect(Rect2(520,288,130,30),Color("9a7650"),true)
 draw_string(ThemeDB.fallback_font,Vector2(540,309),"CHECKOUT",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
 draw_rect(Rect2(45,302,86,18),Color("537e96"),true)
 draw_string(ThemeDB.fallback_font,Vector2(54,315),"ENTRANCE",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color.WHITE)
 for c in waiting: draw_customer(c)
 draw_string(ThemeDB.fallback_font,Vector2(45,335),message,HORIZONTAL_ALIGNMENT_LEFT,620,13,Color("9fb1bf"))
 panel(Rect2(690,90,245,425), "MANAGEMENT")
 button(Rect2(705,120,220,50), "CLOSE SHOP" if open else "OPEN SHOP", open)
 button(Rect2(705,180,220,42), "FINISH / NEXT DAY")
 button(Rect2(705,230,105,42), "DASHBOARD")
 button(Rect2(815,230,110,42), "MISSIONS")
 draw_string(ThemeDB.fallback_font,Vector2(705,288),"Price %d%%" % int(price_factor*100.0),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("526170"))
 button(Rect2(705,295,100,42), "PRICE -5%")
 button(Rect2(815,295,110,42), "PRICE +5%")
 button(Rect2(705,345,220,42), "SUPPLIER: %s" % SUPPLIERS[supplier].name)
 button(Rect2(705,395,220,42), "HIRE STAFF (%dg)" % (80+staff*60))
 button(Rect2(705,445,220,42), "EXPAND (%dg)" % (level*100))
 draw_string(ThemeDB.fallback_font,Vector2(705,505),"Stock %d/%d   Staff %d" % [stock_total(),shelf_limit,staff],HORIZONTAL_ALIGNMENT_LEFT,220,13,Color("aebdca"))
 panel(Rect2(25,350,650,185), "STOCK • click to buy 5")
 for i in PRODUCTS.size():
  var p: Dictionary = PRODUCTS[i]
  var r := Rect2(35+(i%4)*165,380+(i/4)*65,155,55)
  var unlocked := int(p.unlock) <= level
  draw_rect(r,Color("263b31") if unlocked else Color("20272e"),true)
  draw_rect(r,Color("5f7869") if unlocked else Color("3c4650"),false,1.0)
  if unlocked:
   draw_product_icon(r.position+Vector2(18,18),i,0.45)
   draw_string(ThemeDB.fallback_font,r.position+Vector2(36,20),p.name,HORIZONTAL_ALIGNMENT_LEFT,105,13,Color("ffffff"))
   var unit := int(round(float(p.cost)*float(SUPPLIERS[supplier].discount)))
   draw_string(ThemeDB.fallback_font,r.position+Vector2(9,42),"%dg → %dg   ×%d" % [unit,int(round(float(p.price)*price_factor)),stock[i]],HORIZONTAL_ALIGNMENT_LEFT,145,11,Color("b9c7d2"))
  else:
   draw_product_icon(r.position+Vector2(18,18),i,0.45)
   draw_string(ThemeDB.fallback_font,r.position+Vector2(36,20),p.name,HORIZONTAL_ALIGNMENT_LEFT,105,13,Color("74808a"))
   draw_string(ThemeDB.fallback_font,r.position+Vector2(9,42),"LOCK LV.%d" % p.unlock,HORIZONTAL_ALIGNMENT_LEFT,145,11,Color("7d8993"))
 for f in feedback:
  draw_string(ThemeDB.fallback_font,f.pos,f.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f5d77a"))
 if toast_time > 0.0:
  draw_rect(Rect2(250,75,460,38),Color("263442"),true)
  draw_rect(Rect2(250,75,460,38),Color("7890a5"),false,1.0)
  draw_string(ThemeDB.fallback_font,Vector2(265,100),toast,HORIZONTAL_ALIGNMENT_CENTER,430,15,Color("ffffff"))
 if tutorial_step > 0 and not dashboard_visible and not missions_visible and not settlement_visible:
  draw_rect(Rect2(110,210,500,120),Color("101820"),true)
  draw_rect(Rect2(110,210,500,120),Color("8aa0b2"),false,2.0)
  var t := ""
  match tutorial_step:
   1: t = "1/4  FIRST STOCK\nClick a product below to buy stock."
   2: t = "2/4  SET YOUR PRICE\nUse PRICE -5% / +5%, then OPEN SHOP."
   3: t = "3/4  WATCH CUSTOMERS\nCustomers buy automatically. Keep shelves stocked."
   4: t = "4/4  FINISH THE DAY\nClose the shop and press FINISH / NEXT DAY."
  draw_multiline_string(ThemeDB.fallback_font,Vector2(135,245),t,HORIZONTAL_ALIGNMENT_LEFT,450,17,23,Color("ffffff"))
 if settlement_visible:
  panel(Rect2(170,95,620,400),"DAY %d SETTLEMENT" % day)
  var profit := revenue-cost_today
  draw_string(ThemeDB.fallback_font,Vector2(210,170),"Revenue",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b9c7d2"))
  draw_string(ThemeDB.fallback_font,Vector2(560,170),"%dg" % revenue,HORIZONTAL_ALIGNMENT_RIGHT,160,22,Color("f5d77a"))
  draw_string(ThemeDB.fallback_font,Vector2(210,210),"Operating cost",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b9c7d2"))
  draw_string(ThemeDB.fallback_font,Vector2(560,210),"-%dg" % cost_today,HORIZONTAL_ALIGNMENT_RIGHT,160,22,Color("e8a5a5"))
  draw_string(ThemeDB.fallback_font,Vector2(210,255),"Day profit",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffffff"))
  draw_string(ThemeDB.fallback_font,Vector2(560,255),"%dg" % profit,HORIZONTAL_ALIGNMENT_RIGHT,160,24,Color("9fe0a8") if profit >= 0 else Color("e8a5a5"))
  draw_string(ThemeDB.fallback_font,Vector2(210,295),"Served %d   Lost %d   Reputation %d" % [served,lost,reputation],HORIZONTAL_ALIGNMENT_LEFT,400,15,Color("b9c7d2"))
  button(Rect2(705,455,220,55),"START NEXT DAY")
 if dashboard_visible:
  panel(Rect2(155,95,650,390),"BUSINESS DASHBOARD")
  var rows := ["Lifetime revenue: %dg" % lifetime_revenue,"Customers served: %d" % lifetime_served,"Days completed: %d" % lifetime_days,"Best day revenue: %dg" % best_day_revenue,"Current reputation: %d/100" % reputation,"Store capacity: %d" % shelf_limit,"Current demand: %d%%" % int(demand*100.0),"Price level: %d%%" % int(price_factor*100.0)]
  for i in rows.size():
   draw_string(ThemeDB.fallback_font,Vector2(200,150+i*34),rows[i],HORIZONTAL_ALIGNMENT_LEFT,520,17,Color("d6e0e7"))
  button(Rect2(365,440,220,45),"CLOSE DASHBOARD")
 if missions_visible:
  panel(Rect2(135,80,690,435),"MISSIONS & REWARDS")
  for i in MISSIONS.size():
   var m: Dictionary = MISSIONS[i]
   var y := 140+i*75
   var progress := min(mission_progress(i),int(m.target))
   draw_string(ThemeDB.fallback_font,Vector2(175,y),("✓ " if mission_done[i] else "○ ")+str(m.name),HORIZONTAL_ALIGNMENT_LEFT,210,18,Color("9fe0a8") if mission_done[i] else Color("ffffff"))
   draw_string(ThemeDB.fallback_font,Vector2(395,y),"%d/%d" % [progress,m.target],HORIZONTAL_ALIGNMENT_LEFT,100,16,Color("d6e0e7"))
   draw_string(ThemeDB.fallback_font,Vector2(175,y+27),"%s   Reward %dg" % [m.text,m.reward],HORIZONTAL_ALIGNMENT_LEFT,500,13,Color("aebdca"))
  button(Rect2(365,465,220,45),"CLOSE MISSIONS")
 if bankrupt:
  panel(Rect2(180,120,600,300),"SHOP CLOSED")
  draw_string(ThemeDB.fallback_font,Vector2(225,205),"You ran out of cash.",HORIZONTAL_ALIGNMENT_LEFT,510,28,Color("e8a5a5"))
  draw_multiline_string(ThemeDB.fallback_font,Vector2(225,245),"Try lower prices, wholesale supplies, and avoid\nexpanding or hiring before the shop is profitable.",HORIZONTAL_ALIGNMENT_LEFT,510,16,24,Color("c6d2db"))
  button(Rect2(705,455,220,55),"RESTART GAME")
