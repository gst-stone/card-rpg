class_name LayeredMapView
extends Node2D

signal node_selected(node: Dictionary)

var layers: Array = []
var current_layer := 0
var current_index := 0
var hover_node := ""

func set_map(source: Array, active_layer: int = 0, active_index: int = 0) -> void:
	layers = source
	current_layer = active_layer
	current_index = active_index
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	for layer in layers.size():
		for i in layers[layer].size():
			var n: Dictionary = layers[layer][i]
			if not is_reachable(n): continue
			if event.position.distance_to(node_position(layer, i, layers[layer].size())) <= 25.0:
				node_selected.emit(n)
				return

func is_reachable(n: Dictionary) -> bool:
	if current_layer == 0: return n.layer == 0
	if n.layer != current_layer + 1: return false
	if current_layer >= layers.size(): return false
	if current_index < 0 or current_index >= layers[current_layer].size(): return false
	return int(n.index) in layers[current_layer][current_index].next

func node_position(layer: int, index: int, count: int) -> Vector2:
	var spacing := 680.0 / float(max(1, count))
	return Vector2(140.0 + spacing * (index + 0.5), 125.0 + layer * 47.0)

func _draw() -> void:
	for layer in layers.size():
		for i in layers[layer].size():
			var n: Dictionary = layers[layer][i]
			var p := node_position(layer, i, layers[layer].size())
			if layer < layers.size() - 1:
				for target in n.next:
					if int(target) < layers[layer + 1].size():
						draw_line(p, node_position(layer + 1, int(target), layers[layer + 1].size()), Color("40505f"), 2.0)
	for layer in layers.size():
		for i in layers[layer].size():
			var n: Dictionary = layers[layer][i]
			var p := node_position(layer, i, layers[layer].size())
			var reachable := is_reachable(n)
			var active := layer == current_layer and i == current_index
			var radius := 22.0 if reachable else 17.0
			if active: radius = 25.0
			draw_circle(p, radius, Color("f2d27b") if active else (Color("54728a") if reachable else Color("27333e")))
			draw_string(ThemeDB.fallback_font, p + Vector2(-18, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 36, 15, Color.WHITE)
			draw_string(ThemeDB.fallback_font, p + Vector2(-45, 33), str(n.type).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 90, 10, Color("d8e0e8"))
