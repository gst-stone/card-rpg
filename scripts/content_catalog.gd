class_name ContentCatalog
extends RefCounted

const ACTS := {
	1: {"name":"Whispering Woods","subtitle":"The road begins beneath ancient trees."},
	2: {"name":"Ashen Citadel","subtitle":"Steel and fire guard the inner gate."},
	3: {"name":"Void Sanctum","subtitle":"Reality bends around the final throne."}
}

const BOSS_REWARDS := ["Fireball+", "Fortify+", "Shatter+"]

static func act_name(floor: int) -> String:
	return str(ACTS.get(clamp(int(floor), 1, 3), ACTS[1]).name)

static func act_subtitle(floor: int) -> String:
	return str(ACTS.get(clamp(int(floor), 1, 3), ACTS[1]).subtitle)

static func boss_reward(floor: int) -> String:
	return BOSS_REWARDS[(max(1, floor) - 1) % BOSS_REWARDS.size()]
