class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://card_rpg_save.json"

static func save_run(run: RunData) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(run.to_dict()))
	return true

static func load_run() -> RunData:
	var run := RunData.new()
	if not FileAccess.file_exists(SAVE_PATH): return run
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return run
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary: run.from_dict(parsed)
	return run

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(SAVE_PATH)
