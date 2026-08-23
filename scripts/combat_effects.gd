class_name CombatEffects
extends RefCounted

static func apply_card(card: Dictionary, enemy: Dictionary, player: RunData, relics: Array, energy: int) -> Dictionary:
	var damage := int(card.get("damage", 0)) + RelicCatalog.damage_bonus(relics)
	var block := int(card.get("block", 0))
	var heal := int(card.get("heal", 0))
	return {"damage": damage, "block": block, "heal": heal, "energy": energy - int(card.get("cost", 0))}
