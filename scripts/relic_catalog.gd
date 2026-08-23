extends RefCounted

const RELICS := {
	"Guardian Core": {"description": "+10 max HP", "max_hp": 10, "damage_bonus": 0, "gold_bonus": 0},
	"Iron Ring": {"description": "+2 damage to every card", "max_hp": 0, "damage_bonus": 2, "gold_bonus": 0},
	"Lucky Coin": {"description": "+20% battle gold", "max_hp": 0, "damage_bonus": 0, "gold_bonus": 20}
}

static func get_relic(name: String) -> Dictionary:
	return RELICS.get(name, {})

static func damage_bonus(relics: Array) -> int:
	var value := 0
	for relic in relics: value += int(get_relic(relic).get("damage_bonus", 0))
	return value

static func max_hp_bonus(relics: Array) -> int:
	var value := 0
	for relic in relics: value += int(get_relic(relic).get("max_hp", 0))
	return value
