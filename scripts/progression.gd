class_name Progression
extends RefCounted

static func upgrade_cost(floor: int) -> int:
	return 40 + floor * 10

static func can_upgrade(run: RunData) -> bool:
	return run.gold >= upgrade_cost(run.floor) and run.deck.size() > 0

static func upgrade_first_card(run: RunData) -> String:
	if not can_upgrade(run): return ""
	var name: String = str(run.deck[0])
	if not run.spend_gold(upgrade_cost(run.floor)): return ""
	# Store upgraded cards as Card+ names; CardCatalog resolves the base card.
	if not name.ends_with("+"):
		run.deck[0] = CardUpgrade.upgraded_name(name)
	return str(run.deck[0])
