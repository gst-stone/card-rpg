class_name MapGenerator
extends RefCounted

# Generates a seven-floor branching route.
# The middle path guarantees event, rest, shop and elite opportunities.
static func generate(floor: int, seed_value: int = 0) -> Array:
	var rng := RandomNumberGenerator.new()
	var actual_seed := seed_value if seed_value != 0 else 7919 + floor * 104729
	rng.seed = actual_seed
	var rows: Array = []
	var guaranteed := ["battle", "event", "battle", "rest", "shop", "elite"]
	for row in range(7):
		var nodes: Array = []
		var count := 3 if row < 6 else 1
		for col in range(count):
			var type := _roll_type(rng, row, floor)
			if row > 0 and row < 6 and col == 1:
				type = guaranteed[row]
			nodes.append({
				"id": "%d-%d" % [row, col],
				"type": type,
				"row": row,
				"col": col,
				"visited": false
			})
		rows.append(nodes)
	rows[0][0].type = "battle"
	rows[6][0].type = "boss"
	return rows

static func _roll_type(rng: RandomNumberGenerator, row: int, floor: int) -> String:
	if row == 0: return "battle"
	if row == 6: return "boss"
	var roll := rng.randi_range(0, 99)
	if roll < 42: return "battle"
	if roll < 60: return "event"
	if roll < 74: return "rest"
	if roll < 88: return "shop"
	return "elite"
