class_name CombatEffects
extends RefCounted

static func apply_card(card: Dictionary, enemy: Dictionary, player: RunData, relics: Array, energy: int) -> Dictionary:
	var damage := int(card.get("damage", 0)) + RelicCatalog.damage_bonus(relics)
	var block := int(card.get("block", 0)) + RelicCatalog.block_bonus(relics)
	var heal := int(card.get("heal", 0))
	if damage > 0: heal += RelicCatalog.lifesteal(relics)
	return {
		"damage": damage,
		"block": block,
		"heal": heal,
		"draw": int(card.get("draw", 0)),
		"vulnerable": int(card.get("vulnerable", 0)),
		"weak": int(card.get("weak", 0)),
		"poison": int(card.get("poison", 0)),
		"energy": energy - int(card.get("cost", 0))
	}

static func enemy_phase_damage(base_damage: int, status: StatusEffects) -> int:
	return status.reduce_damage(base_damage)
