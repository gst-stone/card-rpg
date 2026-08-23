extends Node2D

# Lightweight roguelike map screen. Nodes are generated locally so the demo
# remains asset-free and easy to extend.

signal node_selected(node_type: String)

var rows := 7
var cols := 5
var current_row := 0
var selected_col := 2
var nodes: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_generate_map()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A, KEY_LEFT:
				selected_col = max(0, selected_col - 1)
				queue_redraw()
			KEY_D, KEY_RIGHT:
				selected_col = min(cols - 1, selected_col + 1)
				queue_redraw()
			KEY_ENTER, KEY_SPACE:
				_select_current_node()

func _generate_map() -> void:
	nodes.clear()
	for row in rows:
		var row_nodes: Array = []
		for col in cols:
			var roll := rng.randi_range(0, 99)
			var node_type := "battle"
			if row == rows - 1:
				node_type = "boss"
			elif roll < 15:
				node_type = "shop"
			elif roll < 30:
				node_type = "event"
			elif roll < 42:
				node_type = "rest"
			row_nodes.append(node_type)
		nodes.append(row_nodes)

func _select_current_node() -> void:
	if current_row >= rows:
		return
	var node_type: String = nodes[current_row][selected_col]
	node_selected.emit(node_type)
	current_row += 1
	if current_row < rows:
		selected_col = clamp(selected_col + rng.randi_range(-1, 1), 0, cols - 1)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("101820"), true)
	draw_string(ThemeDB.fallback_font, Vector2(55, 65), "ADVENTURE MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("f2d27b"))
	draw_string(ThemeDB.fallback_font, Vector2(55, 95), "A/D or arrows: move   Enter/Space: choose", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c5d0dc"))

	for row in rows:
		for col in cols:
			var p := Vector2(180 + col * 150, 130 + row * 52)
			if row > 0:
				var previous := Vector2(180 + col * 150, 130 + (row - 1) * 52)
				draw_line(previous, p, Color("445568"), 2.0)
			var node_type: String = nodes[row][col]
			var radius := 14.0
			if row == current_row and col == selected_col:
				radius = 21.0
				draw_circle(p, 27, Color("f2d27b", 0.18))
			draw_circle(p, radius, _node_color(node_type))
			draw_string(ThemeDB.fallback_font, p + Vector2(-28, 34), _node_label(node_type), HORIZONTAL_ALIGNMENT_LEFT, 56, 11, Color("e4ebf2"))

	if current_row >= rows:
		draw_string(ThemeDB.fallback_font, Vector2(650, 470), "BOSS REACHED", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f2d27b"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(55, 490), "Floor %d / %d" % [current_row + 1, rows], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d8e0e8"))

func _node_color(node_type: String) -> Color:
	match node_type:
		"battle": return Color("b94a59")
		"shop": return Color("d6a84f")
		"event": return Color("8f70c9")
		"rest": return Color("5fcf7a")
		"boss": return Color("8f303b")
	return Color.WHITE

func _node_label(node_type: String) -> String:
	match node_type:
		"battle": return "BATTLE"
		"shop": return "SHOP"
		"event": return "EVENT"
		"rest": return "REST"
		"boss": return "BOSS"
	return "?"
