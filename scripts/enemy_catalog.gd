class_name EnemyCatalog
extends RefCounted

const ENEMIES := {
	"Cultist": {"hp":45,"damage":7,"intent":"Attack"},
	"Wolf": {"hp":55,"damage":10,"intent":"Attack"},
	"Golem": {"hp":80,"damage":6,"intent":"Heavy Attack"},
	"Elite Knight": {"hp":120,"damage":14,"intent":"Elite Attack"},
	"Plague Witch": {"hp":68,"damage":9,"intent":"Poison"},
	"Blood Hound": {"hp":72,"damage":11,"intent":"Heavy Attack"},
	"Stone Warden": {"hp":105,"damage":8,"intent":"Guard"}
}

static func create_enemy(floor: int, elite: bool = false) -> Dictionary:
	var names := ["Cultist","Wolf","Golem","Plague Witch","Blood Hound","Stone Warden"]
	var name: String = "Elite Knight" if elite else names[(floor - 1) % names.size()]
	var base: Dictionary = ENEMIES[name]
	var scale := max(0, floor - 1)
	var hp := int(base.hp) + scale * 8
	var damage := int(base.damage) + scale * 2
	return {"name":name,"max_hp":hp,"hp":hp,"damage":damage,"intent":base.intent,"turn":1,"phase":1}

static func next_intent(enemy: Dictionary, turn: int) -> String:
	var name := str(enemy.get("name", "Cultist"))
	match name:
		"Cultist": return ["Attack", "Attack", "Weakening Chant"][max(0, turn - 1) % 3]
		"Wolf": return ["Attack", "Heavy Attack"][max(0, turn - 1) % 2]
		"Golem": return ["Heavy Attack", "Guard", "Attack"][max(0, turn - 1) % 3]
		"Elite Knight": return ["Heavy Attack", "Attack", "Weakening Strike"][max(0, turn - 1) % 3]
		"Plague Witch": return ["Poison", "Poison", "Attack", "Weakening Chant"][max(0, turn - 1) % 4]
		"Blood Hound": return ["Heavy Attack", "Attack", "Attack"][max(0, turn - 1) % 3]
		"Stone Warden": return ["Guard", "Heavy Attack", "Attack"][max(0, turn - 1) % 3]
	return "Attack"

static func intent_damage(enemy: Dictionary, turn: int) -> int:
	var base := int(enemy.get("damage", 0))
	var intent := next_intent(enemy, turn)
	if intent == "Heavy Attack": return base + 8
	if intent == "Weakening Chant": return 0
	if intent == "Guard": return 0
	if intent == "Poison": return base - 2
	return base

static func action_for(enemy: Dictionary, turn: int) -> String:
	var intent := next_intent(enemy, turn)
	match intent:
		"Heavy Attack": return "heavy"
		"Guard": return "guard"
		"Weakening Chant", "Weakening Strike": return "weak"
		"Poison": return "poison"
	return "attack"
