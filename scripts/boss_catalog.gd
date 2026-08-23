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
	boss.phase := 1
	boss.enrage_bonus := 8
	return boss

static func phase_for(boss: Dictionary, hp: int) -> int:
	if hp <= int(boss.hp * 0.5): return 2
	return 1

static func action_for(boss: Dictionary, turn: int, hp: int) -> String:
	if phase_for(boss, hp) == 2:
		return ["heavy", "poison", "attack"][max(0, turn - 1) % 3]
	var pattern: Array = boss.get("pattern", ["attack"])
	return str(pattern[max(0, turn - 1) % pattern.size()])
