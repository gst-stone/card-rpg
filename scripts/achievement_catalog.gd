class_name AchievementCatalog
extends RefCounted

const ACHIEVEMENTS := {
	"first_blood": {"name":"First Blood","description":"Win your first battle."},
	"elite_slayer": {"name":"Elite Slayer","description":"Defeat an elite enemy."},
	"poison_master": {"name":"Venom","description":"Apply Poison during a run."},
	"boss_breaker": {"name":"Boss Breaker","description":"Defeat a boss."},
	"deck_builder": {"name":"Deck Builder","description":"Reach 15 cards in a deck."}
}

static func all() -> Dictionary:
	return ACHIEVEMENTS.duplicate(true)
