class_name MapView
extends Node2D

signal node_selected(node_type: String)

var nodes: Array = []
var selected := -1

func set_nodes(source: Array) -> void:
	nodes = source
	selected = -1
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	for i in nodes.size():
		var p := node_position(i)
		if event.position.distance_to(p) <= 32.0:
			selected = i
			var node_type := str(nodes[i].type)
			node_selected.emit(node_type)
			var controller := get_parent()
			if controller != null and controller.has_method("select_node"):
				controller.select_node(node_type)
			queue_redraw()
			return

func node_position(i: int) -> Vector2:
	var count := max(1, nodes.size())
	var spacing := 700.0 / float(count)
	return Vector2(130.0 + spacing * (i + 0.5), 270.0)

func _draw() -> void:
	if nodes.is_empty(): return
	for i in nodes.size():
		var p := node_position(i)
		if i > 0:
			draw_line(node_position(i - 1), p, Color("506070"), 3.0)
		var radius := 32.0 if i == selected else 26.0
		draw_circle(p, radius, Color("f2d27b") if i == selected else Color("394b5f"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-24, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 48, 18, Color.WHITE)
		draw_string(ThemeDB.fallback_font, p + Vector2(-55, 55), str(nodes[i].type).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 110, 13, Color("d8e0e8"))
