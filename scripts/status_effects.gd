class_name StatusEffects
extends RefCounted

var vulnerable := 0
var weak := 0
var poison := 0
var player_block := 0

func start_turn() -> void:
	player_block = 0

func reduce_damage(amount: int) -> int:
	var value := amount
	if weak > 0: value = int(floor(value * 0.75))
	return max(0, value)

func outgoing_damage(amount: int) -> int:
	if vulnerable > 0: return int(ceil(amount * 1.25))
	return amount

func absorb(amount: int) -> int:
	var blocked := min(player_block, amount)
	player_block -= blocked
	return amount - blocked

func tick() -> void:
	vulnerable = max(0, vulnerable - 1)
	weak = max(0, weak - 1)
	poison = max(0, poison - 1)
