class_name CardUpgrade
extends RefCounted

static func upgraded_name(name: String) -> String:
	return name + "+"

static func upgrade(card: Dictionary) -> Dictionary:
	var result := card.duplicate(true)
	result.cost = max(0, int(result.get("cost", 1)) - (1 if result.get("damage", 0) < 15 else 0))
	if int(result.get("damage", 0)) > 0: result.damage = int(result.damage) + 8
	if int(result.get("heal", 0)) > 0: result.heal = int(result.heal) + 5
	if int(result.get("block", 0)) > 0: result.block = int(result.block) + 5
	result["upgraded"] = true
	return result
