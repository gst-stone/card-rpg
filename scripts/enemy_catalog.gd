extends RefCounted

const ENEMIES := {
	"Cultist": {"hp":45,"damage":7,"intent":"Attack"},
	"Wolf": {"hp":55,"damage":10,"intent":"Attack"},
	"Golem": {"hp":80,"damage":6,"intent":"Heavy Attack"},
	"Elite Knight": {"hp":120,"damage":14,"intent":"Elite Attack"}
}

static func create_enemy(floor: int, elite: bool = false) -> Dictionary:
	var names := ["Cultist","Wolf","Golem"]
	var name: String = "Elite Knight" if elite else names[(floor - 1) % names.size()]
	var base: Dictionary = ENEMIES[name]
	var scale := max(0, floor - 1)
	return {"name":name,"max_hp":int(base.hp) + scale * 8,"hp":int(base.hp) + scale * 8,"damage":int(base.damage) + scale * 2,"intent":base.intent}
