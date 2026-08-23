class_name RoguelikeMap
extends RefCounted

# Generates a Slay-the-Spire-style layered map.
# Each node stores its layer, type and reachable node indices in the next layer.
static func generate(floor: int, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_value) + floor * 7919
	var layers: Array = []
	var count := rng.randi_range(3, 4)
	for layer in 8:
		var row: Array = []
		for i in count:
			var type := "battle"
			if layer == 7:
				type = "boss"
			elif layer == 0:
				type = "battle"
			else:
				var roll := rng.randi_range(0, 99)
				if roll < 14: type = "elite"
				elif roll < 29: type = "shop"
				elif roll < 43: type = "event"
				elif roll < 55: type = "rest"
			row.append({"id": "%d_%d" % [layer, i], "layer": layer, "index": i, "type": type, "next": []})
		layers.append(row)
	# Connect every node to one or two nearby nodes in the next layer.
	for layer in range(layers.size() - 1):
		for i in layers[layer].size():
			var targets: Array = []
			var a := clamp(i, 0, layers[layer + 1].size() - 1)
			targets.append(a)
			if layers[layer + 1].size() > 1 and rng.randf() < 0.55:
				var b := clamp(i + (1 if rng.randf() > 0.5 else -1), 0, layers[layer + 1].size() - 1)
				if b not in targets: targets.append(b)
			layers[layer][i].next = targets
	return layers
