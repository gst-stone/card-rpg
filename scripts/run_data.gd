class_name RunData
extends RefCounted

var player_hp: int = 100
var max_hp: int = 100
var gold: int = 100
var floor: int = 1
var deck: Array = ["Strike", "Strike", "Fireball", "Guard", "Heavy Blow"]
var relics: Array = []
var current_node: String = "map"
var map_seed: int = 0
var map_layers: Array = []
var map_layer: int = 0
var map_index: int = 0
var map_initialized: bool = false

func add_gold(amount: int) -> void:
	gold += max(0, amount)

func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount: return false
	gold -= amount
	return true

func add_card(card_name: String) -> void:
	deck.append(card_name)

func remove_card(card_name: String) -> bool:
	var index := deck.find(card_name)
	if index < 0: return false
	deck.remove_at(index)
	return true

func heal(amount: int) -> void:
	player_hp = min(max_hp, player_hp + max(0, amount))

func take_damage(amount: int) -> void:
	player_hp = max(0, player_hp - max(0, amount))

func add_relic(relic_name: String) -> void:
	if not relics.has(relic_name): relics.append(relic_name)

func apply_relics() -> void:
	max_hp = 100 + RelicCatalog.max_hp_bonus(relics)
	player_hp = min(player_hp, max_hp)

func to_dict() -> Dictionary:
	return {"player_hp":player_hp,"max_hp":max_hp,"gold":gold,"floor":floor,"deck":deck,"relics":relics,"current_node":current_node,"map_seed":map_seed,"map_layers":map_layers,"map_layer":map_layer,"map_index":map_index,"map_initialized":map_initialized}

func from_dict(data: Dictionary) -> void:
	player_hp = int(data.get("player_hp", 100)); max_hp = int(data.get("max_hp", 100)); gold = int(data.get("gold", 100)); floor = int(data.get("floor", 1))
	deck = data.get("deck", ["Strike", "Strike", "Fireball", "Guard", "Heavy Blow"]); relics = data.get("relics", []); current_node = str(data.get("current_node", "map"))
	map_seed = int(data.get("map_seed", 0)); map_layers = data.get("map_layers", []); map_layer = int(data.get("map_layer", 0)); map_index = int(data.get("map_index", 0)); map_initialized = bool(data.get("map_initialized", false))
