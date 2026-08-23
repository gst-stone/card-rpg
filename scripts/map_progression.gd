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

static func load_or_create(run: RunData) -> RunMapState:
	var state := RunMapState.new()
	if run.map_initialized and not run.map_layers.is_empty():
		state.restore(run.map_layers, run.map_layer, run.map_index, true)
	else:
		var seed := run.map_seed
		if seed == 0: seed = Time.get_unix_time_from_system()
		run.map_seed = seed
		state.setup(run.floor, seed)
		sync_to_run(state, run)
	return state

static func sync_to_run(state: RunMapState, run: RunData) -> void:
	var data := state.serialize()
	run.map_layers = data.layers
	run.map_layer = data.current_layer
	run.map_index = data.current_index
	run.map_initialized = data.initialized
