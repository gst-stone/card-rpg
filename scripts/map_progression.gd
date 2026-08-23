class_name MapProgression
extends RefCounted

static func next_floor(state: RunMapState, run: RunData) -> void:
	if not state.initialized: return
	if state.at_boss(): return
	run.floor = max(run.floor, state.current_layer + 1)

static func node_label(node: Dictionary) -> String:
	if node.is_empty(): return ""
	return str(node.type).capitalize()

static func is_terminal(state: RunMapState) -> bool:
	return state.at_boss()
