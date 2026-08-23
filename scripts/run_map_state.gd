class_name RunMapState
extends RefCounted

var layers: Array = []
var current_layer := 0
var current_index := 0
var initialized := false

func setup(floor: int, seed_value: int) -> void:
	layers = RoguelikeMap.generate(floor, seed_value)
	current_layer = 0
	current_index = 0
	initialized = true

func restore(saved_layers: Array, saved_layer: int, saved_index: int, saved_initialized: bool) -> void:
	layers = saved_layers
	current_layer = saved_layer
	current_index = saved_index
	initialized = saved_initialized and not layers.is_empty()
	if initialized:
		current_layer = clamp(current_layer, 0, layers.size() - 1)
		current_index = clamp(current_index, 0, layers[current_layer].size() - 1)

func current_node() -> Dictionary:
	if not initialized or layers.is_empty(): return {}
	return layers[current_layer][current_index]

func can_enter(layer: int, index: int) -> bool:
	if not initialized or layer != current_layer + 1: return false
	if current_layer >= layers.size() or current_index >= layers[current_layer].size(): return false
	return index in layers[current_layer][current_index].next

func enter(layer: int, index: int) -> Dictionary:
	if not can_enter(layer, index): return {}
	current_layer = layer
	current_index = index
	return current_node()

func at_boss() -> bool:
	return initialized and current_layer == layers.size() - 1

func serialize() -> Dictionary:
	return {"layers": layers, "current_layer": current_layer, "current_index": current_index, "initialized": initialized}
