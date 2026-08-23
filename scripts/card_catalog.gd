extends RefCounted

const CARDS := {
	"Strike": {"cost": 1, "damage": 15, "heal": 0, "block": 0, "rarity": "Basic"},
	"Guard": {"cost": 1, "damage": 0, "heal": 10, "block": 0, "rarity": "Basic"},
	"Fireball": {"cost": 2, "damage": 25, "heal": 0, "block": 0, "rarity": "Uncommon"},
	"Heavy Blow": {"cost": 3, "damage": 40, "heal": 0, "block": 0, "rarity": "Rare"},
	"Quick Jab": {"cost": 0, "damage": 7, "heal": 0, "block": 0, "rarity": "Uncommon"},
	"Drain": {"cost": 2, "damage": 12, "heal": 12, "block": 0, "rarity": "Uncommon"},
	"Shield Bash": {"cost": 1, "damage": 10, "heal": 0, "block": 8, "rarity": "Uncommon"},
	"Meteor": {"cost": 3, "damage": 55, "heal": 0, "block": 0, "rarity": "Rare"}
}

static func get_card(name: String) -> Dictionary:
	return CARDS.get(name, CARDS["Strike"])

static func names() -> Array:
	return CARDS.keys()
