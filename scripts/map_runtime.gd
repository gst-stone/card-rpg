class_name MapRuntime
extends RefCounted

var state: RunMapState
var run: RunData

func _init(active_run: RunData) -> void:
	run = active_run
	state = MapProgression.load_or_create(run)
	_sync()

func available_nodes() -> Array:
	if not state.initialized or state.layers.is_empty(): return []
	var result: Array = []
	var next_layer := state.current_layer + 1
	if state.current_layer == 0:
		next_layer = 0
	for node in state.layers[next_layer]:
		if state.current_layer == 0 or state.can_enter(next_layer, int(node.index)):
			result.append(node)
	return result

func enter_node(layer: int, index: int) -> Dictionary:
	var node: Dictionary
	if state.current_layer == 0 and layer == 0:
		if index < 0 or index >= state.layers[0].size(): return {}
		state.current_layer = 0
		state.current_index = index
		node = state.current_node()
	else:
		node = state.enter(layer, index)
	if node.is_empty(): return {}
	MapProgression.next_floor(state, run)
	_sync()
	return node

func complete_node() -> void:
	_sync()

func _sync() -> void:
	MapProgression.sync_to_run(state, run)
