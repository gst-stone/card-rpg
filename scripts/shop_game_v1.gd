extends Node2D

# My Little Shop v1.0 - complete playable management prototype.
const SAVE_PATH := "user://my_little_shop_v1.json"
const VERSION := "1.0"
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
 {"name":"Premium","discount":1.08,"label":"+8% preference"}
]
const EVENTS := ["Normal market","Rainy day","Weekend rush","Local festival","Supplier sale","Heat wave"]
const MISSIONS := [
 {"name":"First Sale","text":"Serve 5 customers","target":5,"reward":50},
 {"name":"Busy Shop","text":"Serve 25 customers","target":25,"reward":100},
 {"name":"Popular Store","text":"Reach 70 reputation","target":70,"reward":150},
 {"name":"Big Day","text":"Make 150g revenue in one day","target":150,"reward":120}
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
var message := "Stock your shelves, then open the shop."
var feedback: Array[Dictionary] = []
var mission_done: Array[bool] = [false,false,false,false]
var toast := ""
var toast_time := 0.0

func _ready() -> void:
 randomize()
 load_game()
 queue_redraw()

func _process(delta: float) -> void:
 toast_time = max(0.0, toast_time - delta)
 for f in feedback:
  f.life -= delta
  f.pos.y -= delta * 26.0
 feedback = feedback.filter(func(f): return f.life > 0.0)
 if open and not settlement_visible:
  spawn_timer -= delta
  if spawn_timer <= 0.0:
   spawn_timer = max(0.65, 2.5 - level * 0.12 - staff * 0.22)
   add_customer()
  for c in waiting:
   c.patience -= delta
   var target := Vector2(150.0 + float(c.slot % 5) * 82.0, 155.0 + float(c.slot / 5) * 72.0)
   c.pos = c.pos.move_toward(target, delta * (110.0 + staff * 14.0))
  var before := waiting.size()
  waiting = waiting.filter(func(c): return c.patience > 0.0)
  if before > waiting.size():
   var n := before - waiting.size()
   lost += n
   reputation = max(0, reputation - n)
   add_feedback("-%d lost" % n, Vector2(300,180))
  sale_timer -= delta
  if sale_timer <= 0.0 and not waiting.is_empty():
   sale_timer = max(0.32, 0.62 - staff * 0.035)
   serve_customer()
 queue_redraw()

func add_customer() -> void:
 var limit := min(12, 4 + level + staff)
 if waiting.size() >= limit:
  lost += 1
  reputation = max(0, reputation - 1)
  show_toast("Crowded! Customer leaves.")
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
 add_feedback("+%dg" % sell, Vector2(535,285))
 message = "%s bought %s" % [customer.name,p.name]
 check_level()
 check_missions()

func check_level() -> void:
 while level < 10 and xp >= level * 45:
  xp -= level * 45
  level += 1
  shelf_limit += 4
  shelf_count += 1
  show_toast("LEVEL %d! New shelf space." % level)

func stock_total() -> int:
 var n := 0
 for x in stock: n += x
 return n

func restock(i: int, qty := 5) -> void:
 if open or settlement_visible or i < 0 or i >= PRODUCTS.size(): return
 if int(PRODUCTS[i].unlock) > level:
  show_toast("Unlocks at level %d." % PRODUCTS[i].unlock)
  return
 qty = min(qty, shelf_limit - stock_total())
 if qty <= 0:
  show_toast("Shelves are full.")
  return
 var unit := int(round(float(PRODUCTS[i].cost) * float(SUPPLIERS[supplier].discount)))
 var total := unit * qty
 if gold < total:
  show_toast("Need %dg." % total)
  return
 gold -= total
 stock[i] += qty
 message = "Bought %d %s for %dg." % [qty,PRODUCTS[i].name,total]
 save_game()

func choose_supplier() -> void:
 if open or settlement_visible: return
 supplier = (supplier + 1) % SUPPLIERS.size()
 message = "Supplier: %s (%s)" % [SUPPLIERS[supplier].name,SUPPLIERS[supplier].label]

func hire_staff() -> void:
 if open or settlement_visible: return
 var price := 80 + staff * 60
 if gold < price:
  show_toast("Hiring costs %dg." % price)
  return
 gold -= price
 staff += 1
 message = "Staff %d hired." % staff
 save_game()

func expand_store() -> void:
 if open or settlement_visible: return
 var price := level * 100
 if gold < price:
  show_toast("Expansion costs %dg." % price)
  return
 gold -= price
 shelf_limit += 8
 shelf_count += 1
 message = "Store expanded to %d capacity." % shelf_limit
 save_game()

func change_price(step: float) -> void:
 if open or settlement_visible: return
 price_factor = clamp(price_factor + step,0.75,1.35)
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
 if settlement_visible: return
 open = not open
 if open:
  spawn_timer = 0.25
  message = "SHOP OPEN • %s" % event_text
 else:
  waiting.clear()
  message = "Shop closed. Settle the day."
  save_game()

func next_day() -> void:
 if open: show_toast("Close the shop first."); return
 if not settlement_visible:
  finish_day()
 else:
  settlement_visible = false
  day += 1
  served = 0
  lost = 0
  revenue = 0
  cost_today = 0
  demand = randf_range(0.82,1.18)
  price_factor = clamp(price_factor + randf_range(-0.05,0.05),0.75,1.35)
  generate_event()
  message = "Day %d • %s" % [day,event_text]
  save_game()

func finish_day() -> void:
 var expense := 10 + staff * (20 + staff * 5)
 cost_today = expense
 gold -= expense
 best_day_revenue = max(best_day_revenue,revenue)
 lifetime_days += 1
 settlement_visible = true
 message = "Day %d complete. Profit %dg." % [day,revenue-expense]
 check_missions()
 save_game()

func check_missions() -> void:
 var values := [lifetime_served,reputation,best_day_revenue]
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
   show_toast("Mission complete +%dg" % MISSIONS[i].reward)

func show_toast(t: String) -> void:
 toast = t
 toast_time = 2.0
 message = t

func add_feedback(text: String, at: Vector2) -> void:
 feedback.append({"text":text,"pos":at,"life":1.1})

func save_game() -> void:
 var data := {"version":VERSION,"gold":gold,"level":level,"xp":xp,"day":day,"stock":stock,"shelf_limit":shelf_limit,"shelf_count":shelf_count,"reputation":reputation,"staff":staff,"supplier":supplier,"price_factor":price_factor,"demand":demand,"event_text":event_text,"event_demand_bonus":event_demand_bonus,"event_profit_bonus":event_profit_bonus,"served":served,"lost":lost,"revenue":revenue,"cost_today":cost_today,"lifetime_revenue":lifetime_revenue,"lifetime_served":lifetime_served,"lifetime_days":lifetime_days,"best_day_revenue":best_day_revenue,"mission_done":mission_done}
 var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(data))

func load_game() -> void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
 if not f: return
 var d = JSON.parse_string(f.get_as_text())
 if typeof(d) != TYPE_DICTIONARY: return
 gold=int(d.get("gold",gold)); level=int(d.get("level",level)); xp=int(d.get("xp",xp)); day=int(d.get("day",day))
 var s=d.get("stock",stock)
 if typeof(s)==TYPE_ARRAY:
  for i in min(s.size(),stock.size()): stock[i]=int(s[i])
 shelf_limit=int(d.get("shelf_limit",shelf_limit)); shelf_count=int(d.get("shelf_count",shelf_count)); reputation=int(d.get("reputation",reputation)); staff=int(d.get("staff",staff)); supplier=int(d.get("supplier",supplier)); price_factor=float(d.get("price_factor",price_factor)); demand=float(d.get("demand",demand)); event_text=str(d.get("event_text",event_text)); event_demand_bonus=float(d.get("event_demand_bonus",event_demand_bonus)); event_profit_bonus=float(d.get("event_profit_bonus",event_profit_bonus)); served=int(d.get("served",served)); lost=int(d.get("lost",lost)); revenue=int(d.get("revenue",revenue)); cost_today=int(d.get("cost_today",cost_today)); lifetime_revenue=int(d.get("lifetime_revenue",lifetime_revenue)); lifetime_served=int(d.get("lifetime_served",lifetime_served)); lifetime_days=int(d.get("lifetime_days",lifetime_days)); best_day_revenue=int(d.get("best_day_revenue",best_day_revenue))
 var md=d.get("mission_done",mission_done)
 if typeof(md)==TYPE_ARRAY:
  for i in min(md.size(),mission_done.size()): mission_done[i]=bool(md[i])
 message="Save loaded • Day %d" % day

func reset_save() -> void:
 if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(SAVE_PATH)
 get_tree().reload_current_scene()

func _input(e: InputEvent) -> void:
 if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
  var p:=e.position
  if settlement_visible:
   if Rect2(705,455,220,55).has_point(p): next_day()
   return
  if Rect2(705,120,220,50).has_point(p): toggle_shop(); return
  if Rect2(705,180,220,42).has_point(p): next_day(); return
  if Rect2(705,295,100,42).has_point(p): change_price(-0.05); return
  if Rect2(815,295,110,42).has_point(p): change_price(0.05); return
  if Rect2(705,345,220,42).has_point(p): choose_supplier(); return
  if Rect2(705,395,220,42).has_point(p): hire_staff(); return
  if Rect2(705,445,220,42).has_point(p): expand_store(); return
  for i in PRODUCTS.size():
   if Rect2(35+(i%4)*165,365+(i/4)*65,155,55).has_point(p): restock(i); return
 if e is InputEventKey and e.pressed and not e.echo:
  match e.keycode:
   KEY_SPACE: toggle_shop()
   KEY_N: next_day()
   KEY_S: choose_supplier()
   KEY_H: hire_staff()
   KEY_U: expand_store()
   KEY_MINUS: change_price(-0.05)
   KEY_EQUAL,KEY_PLUS: change_price(0.05)
   KEY_F5: save_game(); show_toast("Game saved")
   KEY_F9: load_game(); show_toast("Game loaded")
   KEY_F10: reset_save()
   KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8: restock(e.keycode-KEY_1)

func draw_button(r:Rect2,t:String,active:=true) -> void:
 draw_rect(r,Color("4f8a62") if active else Color("9aa3aa"),true)
 draw_string(ThemeDB.fallback_font,r.position+Vector2(12,r.size.y*0.67),t,HORIZONTAL_ALIGNMENT_LEFT,r.size.x-24,16,Color.WHITE)

func _draw() -> void:
 draw_rect(Rect2(0,0,960,540),Color("e9edf0"),true)
 draw_rect(Rect2(0,0,960,72),Color("243447"),true)
 draw_string(ThemeDB.fallback_font,Vector2(24,43),"MY LITTLE SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(300,37),"DAY %d • LV.%d" % [day,level],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("dbe7f2"))
 draw_string(ThemeDB.fallback_font,Vector2(300,59),"XP %d/%d  REP %d  STAFF %d" % [xp,level*45,reputation,staff],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b8cadb"))
 draw_string(ThemeDB.fallback_font,Vector2(815,43),"%dg" % gold,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("f4d35e"))
 draw_rect(Rect2(20,88,660,250),Color("f8f4ed"),true)
 draw_rect(Rect2(20,88,660,10),Color("c8a77d"),true)
 draw_string(ThemeDB.fallback_font,Vector2(40,122),"STORE FLOOR",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("695747"))
 for s in shelf_count:
  var sx:=40.0+float(s%2)*300.0
  var sy:=135.0+float(s/2)*70.0
  draw_rect(Rect2(sx,sy,250,55),Color("e2d2bb"),true)
  draw_rect(Rect2(sx+7,sy+7,236,41),Color("fffaf1"),true)
  var a:=(s*2)%PRODUCTS.size()
  draw_string(ThemeDB.fallback_font,Vector2(sx+16,sy+27),PRODUCTS[a].name+"  "+str(stock[a]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("51463c"))
  if a+1<PRODUCTS.size(): draw_string(ThemeDB.fallback_font,Vector2(sx+135,sy+27),PRODUCTS[a+1].name+"  "+str(stock[a+1]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("51463c"))
 draw_rect(Rect2(520,288,130,30),Color("9a7650"),true)
 draw_string(ThemeDB.fallback_font,Vector2(540,309),"CHECKOUT",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
 draw_rect(Rect2(40,305,90,25),Color("7aa6c2"),true)
 draw_string(ThemeDB.fallback_font,Vector2(52,322),"ENTRANCE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color.WHITE)
 for c in waiting:
  draw_circle(c.pos,12,Color("e0a37e"))
  draw_rect(Rect2(c.pos.x-13,c.pos.y+10,26,24),Color("6c8db5"),true)
  draw_string(ThemeDB.fallback_font,c.pos+Vector2(-5,5),c.icon,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
 for f in feedback:
  draw_string(ThemeDB.fallback_font,f.pos,f.text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("3f7654"))
 draw_rect(Rect2(700,88,240,397),Color.WHITE,true)
 draw_string(ThemeDB.fallback_font,Vector2(720,113),"MANAGEMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("526170"))
 draw_button(Rect2(705,120,220,50),"CLOSE SHOP" if open else "OPEN SHOP",true)
 draw_button(Rect2(705,180,220,42),"NEXT DAY [N]")
 draw_string(ThemeDB.fallback_font,Vector2(705,248),"Stock %d/%d" % [stock_total(),shelf_limit],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
 draw_string(ThemeDB.fallback_font,Vector2(705,269),"Revenue %dg • Lost %d" % [revenue,lost],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("4d5965"))
 draw_button(Rect2(705,295,100,42),"PRICE -")
 draw_button(Rect2(815,295,110,42),"PRICE +")
 draw_string(ThemeDB.fallback_font,Vector2(705,288),"Price %d%%" % int(price_factor*100.0),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("526170"))
 draw_button(Rect2(705,345,220,42),"SUPPLIER: "+SUPPLIERS[supplier].name)
 draw_button(Rect2(705,395,220,42),"HIRE STAFF [H]")
 draw_button(Rect2(705,445,220,42),"EXPAND [U]")
 for i in PRODUCTS.size():
  var r:=Rect2(35+(i%4)*165,365+(i/4)*65,155,55)
  var unlocked:=int(PRODUCTS[i].unlock)<=level
  draw_rect(r,Color("d8e2e7") if unlocked else Color("b7bdc2"),true)
  draw_string(ThemeDB.fallback_font,r.position+Vector2(9,20),PRODUCTS[i].name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("26323a"))
  draw_string(ThemeDB.fallback_font,r.position+Vector2(9,40),"%dg → %dg  [%d]" % [PRODUCTS[i].cost,round(PRODUCTS[i].price*price_factor),stock[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("526170"))
 draw_string(ThemeDB.fallback_font,Vector2(40,525),message,HORIZONTAL_ALIGNMENT_LEFT,620,14,Color("526170"))
 if toast_time>0.0:
  draw_rect(Rect2(280,82,400,42),Color("33495b"),true)
  draw_string(ThemeDB.fallback_font,Vector2(305,110),toast,HORIZONTAL_ALIGNMENT_LEFT,350,16,Color.WHITE)
 if settlement_visible: draw_settlement()

func draw_settlement() -> void:
 draw_rect(Rect2(115,70,730,420),Color("17232d"),true)
 draw_string(ThemeDB.fallback_font,Vector2(165,125),"DAY %d SETTLEMENT" % day,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(165,160),"Event: %s" % event_text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("dbe7f2"))
 var profit:=revenue-cost_today
 draw_string(ThemeDB.fallback_font,Vector2(165,210),"Revenue       %d g" % revenue,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("f4d35e"))
 draw_string(ThemeDB.fallback_font,Vector2(165,245),"Operating cost %d g" % cost_today,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("e7b0a0"))
 draw_string(ThemeDB.fallback_font,Vector2(165,280),"DAY PROFIT    %d g" % profit,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("9fe0ae"))
 draw_string(ThemeDB.fallback_font,Vector2(165,320),"Served %d    Lost %d    Reputation %d" % [served,lost,reputation],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("dbe7f2"))
 draw_string(ThemeDB.fallback_font,Vector2(165,355),"Lifetime: %d customers • %d g revenue" % [lifetime_served,lifetime_revenue],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8cadb"))
 draw_string(ThemeDB.fallback_font,Vector2(165,392),"Next day will refresh demand and market event.",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8cadb"))
 draw_button(Rect2(705,455,120,55),"NEXT DAY",true)
 draw_button(Rect2(830,455,0,55),"",false)
