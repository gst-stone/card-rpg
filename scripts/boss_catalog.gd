class_name BossCatalog
extends RefCounted

const BOSSES := [
	{"name":"Guardian","hp":180,"damage":15,"pattern":["attack","attack","heavy"]},
	{"name":"Void Tyrant","hp":240,"damage":18,"pattern":["attack","weak","heavy"]},
	{"name":"Ancient Dragon","hp":300,"damage":22,"pattern":["attack","heavy","attack"]}
]

static func create_boss(floor: int) -> Dictionary:
	var index := clamp(floor / 3, 0, BOSSES.size() - 1)
	var boss: Dictionary = BOSSES[index].duplicate(true)
	boss.hp += floor * 10
	boss.damage += floor / 2
	return boss
