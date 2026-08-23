class_name BossCatalog
extends RefCounted

const BOSSES := [
	{"name":"Guardian","hp":180,"damage":15,"pattern":["attack","attack","heavy"]},
	{"name":"Void Tyrant","hp":240,"damage":18,"pattern":["attack","weak","heavy"]},
	{"name":"Ancient Dragon","hp":300,"damage":22,"pattern":["attack","heavy","attack"]}
]

static func create_boss(floor: int) -> Dictionary:
	var index := clamp(int(floor / 3), 0, BOSSES.size() - 1)
	var boss: Dictionary = BOSSES[index].duplicate(true)
	boss.hp += floor * 10
	boss.damage += floor / 2
	boss.phase = 1
	boss.enrage_bonus = 8
	boss.phase_announced = false
	return boss

static func phase_for(boss: Dictionary, hp: int) -> int:
	var max_hp := int(boss.get("hp", 1))
	return 2 if hp <= int(max_hp * 0.5) else 1

static func action_for(boss: Dictionary, turn: int, hp: int) -> String:
	if phase_for(boss, hp) == 2:
		return ["heavy", "poison", "attack"][max(0, turn - 1) % 3]
	var pattern: Array = boss.get("pattern", ["attack"])
	return str(pattern[max(0, turn - 1) % pattern.size()])

static func action_damage(boss: Dictionary, action: String, hp: int) -> int:
	var damage := int(boss.get("damage", 0))
	if phase_for(boss, hp) == 2: damage += int(boss.get("enrage_bonus", 8))
	if action == "heavy": damage += 10
	if action == "poison": damage = max(1, int(floor(damage * 0.5)))
	if action == "weak": damage = 0
	return damage
