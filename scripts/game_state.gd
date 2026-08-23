class_name GameState
extends Node

signal state_changed(state: String)

enum State { MAP, BATTLE, SHOP, EVENT, REST, BOSS, VICTORY, DEFEAT }

var current_state: State = State.MAP
var run: RunData

func setup(run_data: RunData) -> void:
	run = run_data

func go_to(state: State) -> void:
	current_state = state
	if run:
		run.current_node = state_name(state)
		SaveManager.save_run(run)
	state_changed.emit(state_name(state))

func state_name(state: State) -> String:
	match state:
		State.MAP: return "map"
		State.BATTLE: return "battle"
		State.SHOP: return "shop"
		State.EVENT: return "event"
		State.REST: return "rest"
		State.BOSS: return "boss"
		State.VICTORY: return "victory"
		State.DEFEAT: return "defeat"
	return "map"
