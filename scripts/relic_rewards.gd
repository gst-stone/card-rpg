class_name RelicRewards
extends RefCounted

const RELICS := ["Guardian Core", "Iron Ring", "Lucky Coin"]

static func random_relic(floor: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = floor * 15485863 + Time.get_ticks_msec()
	return RELICS[rng.randi_range(0, RELICS.size() - 1)]

static func elite_reward(floor: int) -> Dictionary:
	return {"gold": 60 + floor * 12, "relic": random_relic(floor)}
