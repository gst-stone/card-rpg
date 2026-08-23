class_name MapGenerator
extends RefCounted

static func generate(floor: int, seed_value: int = 0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else Time.get_unix_time_from_system()
	var rows: Array = []
	for row in range(1, 8):
		var nodes: Array = []
		var count := 3 if row < 7 else 1
		for col in range(count):
			var type := _roll_type(rng, row, floor)
			nodes.append({"id":"%d-%d"%[row,col],"type":type,"row":row,"col":col,"visited":false})
		rows.append(nodes)
	rows[0][0].type = "battle"
	rows[6][0].type = "boss"
	return rows

static func _roll_type(rng: RandomNumberGenerator, row: int, floor: int) -> String:
	if row == 6: return "boss"
	var roll := rng.randi_range(0,99)
	if roll < 45: return "battle"
	if roll < 65: return "event"
	if roll < 80: return "rest"
	if roll < 92: return "shop"
	return "elite"
