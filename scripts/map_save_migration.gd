class_name MapSaveMigration
extends RefCounted

static func ensure_map(run: RunData) -> RunMapState:
	var state := RunMapState.new()
	if run.map_initialized and not run.map_layers.is_empty():
		state.restore(run.map_layers, run.map_layer, run.map_index, true)
		return state
	var seed := run.map_seed
	if seed == 0:
		seed = Time.get_unix_time_from_system()
		run.map_seed = seed
	state.setup(run.floor, seed)
	MapProgression.sync_to_run(state, run)
	return state
