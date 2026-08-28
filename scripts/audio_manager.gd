class_name AudioManager
extends Node

var enabled := true

func play_sfx(_name: String) -> void:
	if not enabled: return
	# Production hook: attach AudioStreamPlayer assets here.

func set_enabled(value: bool) -> void:
	enabled = value
