class_name DeckManager
extends RefCounted

static func upgrade(card_name: String) -> bool:
	return CardCatalog.upgraded_cards.has(card_name)

static func upgraded_name(card_name: String) -> String:
	if upgrade(card_name): return CardCatalog.upgraded_cards[card_name].name
	return card_name

static func upgrade_card(deck: Array, card_name: String) -> bool:
	var index := deck.find(card_name)
	if index < 0 or not upgrade(card_name): return false
	deck[index] = upgraded_name(card_name)
	return true

static func remove_card(deck: Array, card_name: String) -> bool:
	var index := deck.find(card_name)
	if index < 0 or deck.size() <= 1: return false
	deck.remove_at(index)
	return true
