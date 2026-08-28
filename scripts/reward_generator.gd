class_name RewardGenerator
extends RefCounted

const CARD_POOL := ["Slash", "Ice Lance", "Blood Pact", "Fireball", "Heavy Blow", "Guard", "Focus", "Expose", "Hex", "Toxic Flask", "Quick Jab", "Fortify", "Poison Dart", "Cleave", "Siphon", "Adrenaline", "Shatter", "Riposte"]

static func card_choices(floor: int) -> Array:
	var pool := CARD_POOL.duplicate()
	var rng := RandomNumberGenerator.new()
	# Deterministic by floor: loading the same run does not silently reroll rewards.
	rng.seed = 104729 + floor * 7919
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

static func gold(floor: int, elite: bool = false) -> int:
	return (45 + floor * 10) if elite else (25 + floor * 7)
