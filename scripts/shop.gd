extends RefCounted

class_name Shop

static func cards() -> Array:
	return [
		{"name":"Slash","cost":75,"damage":22},
		{"name":"Ice Lance","cost":90,"damage":30},
		{"name":"Blood Pact","cost":80,"damage":18,"heal":8}
	]

static func relics() -> Array:
	return [
		{"name":"Guardian Core","cost":120},
		{"name":"Iron Ring","cost":140},
		{"name":"Lucky Coin","cost":130}
	]

static func random_cards() -> Array:
	var result := cards().duplicate()
	result.shuffle()
	return result.slice(0, 2)

static func random_relic() -> Dictionary:
	var result := relics().duplicate()
	result.shuffle()
	return result[0]
