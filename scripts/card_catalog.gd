class_name CardCatalog
extends RefCounted

const CARDS := {
	"Strike": {"cost": 1, "damage": 15, "heal": 0, "block": 0, "description": "Deal 15 damage."},
	"Fireball": {"cost": 2, "damage": 25, "heal": 0, "block": 0, "description": "Deal 25 damage."},
	"Guard": {"cost": 1, "damage": 0, "heal": 10, "block": 8, "description": "Gain 8 block and heal 10 HP."},
	"Heavy Blow": {"cost": 3, "damage": 40, "heal": 0, "block": 0, "description": "Deal 40 damage."},
	"Slash": {"cost": 1, "damage": 22, "heal": 0, "block": 0, "description": "Deal 22 damage."},
	"Ice Lance": {"cost": 2, "damage": 30, "heal": 0, "block": 0, "description": "Deal 30 damage."},
	"Blood Pact": {"cost": 1, "damage": 18, "heal": 8, "block": 0, "description": "Deal 18 damage and heal 8 HP."}
}

static func get_card(name: String) -> Dictionary:
	return CARDS.get(name, {})

static func all_names() -> Array:
	return CARDS.keys()
