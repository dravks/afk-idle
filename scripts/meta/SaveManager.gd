extends Node
class_name SaveManager
## JSON kayit: user://afk_save.json. Semayi bilmez; sozluk alir/verir.
## Eksik/bozuk kayit varsayilanla birlesir (anahtar dusmez).

const SAVE_PATH := "user://afk_save.json"

static func default_data() -> Dictionary:
	return {
		"gold": 0,
		"hero_exp": 0,
		"dust": 0,
		"last_claim_timestamp": 0,
		"current_stage": 1,
		"owned_hero_ids": [],
		"hero_levels": {},
		"crystal_slots": [],
	}

func save_game(player_data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: yazma hatasi: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(player_data, "\t"))
	f.close()

func load_game() -> Dictionary:
	var out := default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return out
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: bozuk kayit, varsayilan donuluyor")
		return out
	for key in (parsed as Dictionary).keys():
		out[key] = (parsed as Dictionary)[key]
	return out

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func wipe() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
