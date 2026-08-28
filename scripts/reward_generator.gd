class_name RewardGenerator
extends RefCounted

static func card_choices(floor: int) -> Array:
	var pool := ["Slash", "Ice Lance", "Blood Pact", "Fireball", "Heavy Blow", "Guard", "Focus", "Expose", "Hex", "Toxic Flask", "Quick Jab", "Fortify", "Poison Dart", "Cleave", "Siphon", "Adrenaline", "Shatter", "Riposte"]
	var rng := RandomNumberGenerator.new()
	rng.seed = floor * 7919 + Time.get_ticks_msec()
	pool.shuffle()
	return pool.slice(0, 3)

static func gold(floor: int, elite: bool = false) -> int:
	return (45 + floor * 10) if elite else (25 + floor * 7)
