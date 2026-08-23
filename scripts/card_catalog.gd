class_name CardCatalog
extends RefCounted

const CARDS := {
	"Strike": {"cost": 1, "damage": 15, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 15 damage."},
	"Strike+": {"cost": 1, "damage": 20, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 20 damage."},
	"Fireball": {"cost": 2, "damage": 25, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 25 damage."},
	"Fireball+": {"cost": 2, "damage": 34, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 34 damage."},
	"Guard": {"cost": 1, "damage": 0, "heal": 10, "block": 8, "draw": 0, "type": "skill", "description": "Gain 8 block and heal 10 HP."},
	"Guard+": {"cost": 1, "damage": 0, "heal": 14, "block": 12, "draw": 0, "type": "skill", "description": "Gain 12 block and heal 14 HP."},
	"Heavy Blow": {"cost": 3, "damage": 40, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 40 damage."},
	"Heavy Blow+": {"cost": 2, "damage": 45, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 45 damage."},
	"Slash": {"cost": 1, "damage": 22, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 22 damage."},
	"Slash+": {"cost": 1, "damage": 29, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 29 damage."},
	"Ice Lance": {"cost": 2, "damage": 30, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 30 damage."},
	"Ice Lance+": {"cost": 2, "damage": 40, "heal": 0, "block": 0, "draw": 0, "type": "attack", "description": "Deal 40 damage."},
	"Blood Pact": {"cost": 1, "damage": 18, "heal": 8, "block": 0, "draw": 0, "type": "skill", "description": "Deal 18 damage and heal 8 HP."},
	"Blood Pact+": {"cost": 1, "damage": 24, "heal": 12, "block": 0, "draw": 0, "type": "skill", "description": "Deal 24 damage and heal 12 HP."},
	"Focus": {"cost": 1, "damage": 0, "heal": 0, "block": 5, "draw": 2, "type": "skill", "description": "Gain 5 block and draw 2 cards."},
	"Focus+": {"cost": 1, "damage": 0, "heal": 0, "block": 8, "draw": 2, "type": "skill", "description": "Gain 8 block and draw 2 cards."}
}

const upgraded_cards := {
	"Strike": {"name":"Strike+"}, "Fireball":{"name":"Fireball+"}, "Guard":{"name":"Guard+"},
	"Heavy Blow":{"name":"Heavy Blow+"}, "Slash":{"name":"Slash+"}, "Ice Lance":{"name":"Ice Lance+"}, "Blood Pact":{"name":"Blood Pact+"}, "Focus":{"name":"Focus+"}
}

static func get_card(name: String) -> Dictionary:
	return CARDS.get(name, {})

static func card_type(name: String) -> String:
	return str(get_card(name).get("type", "skill"))

static func all_names() -> Array:
	return CARDS.keys()
