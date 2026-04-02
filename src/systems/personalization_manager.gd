extends Node

# PersonalizationManager.gd
# Zarządza dekoracjami, customizacją, rankingami

signal cosmetic_unlocked(id)

var unlocked_cosmetics = {}

func unlock_cosmetic(id):
	unlocked_cosmetics[id] = true
	save_state()
	emit_signal("cosmetic_unlocked", id)

func has_cosmetic(id):
	return unlocked_cosmetics.has(id)

func save_state():
	var file = FileAccess.open("user://personalization_manager.save", FileAccess.WRITE)
	file.store_var(unlocked_cosmetics)
	file.close()

func load_state():
	if FileAccess.file_exists("user://personalization_manager.save"):
		var file = FileAccess.open("user://personalization_manager.save", FileAccess.READ)
		unlocked_cosmetics = file.get_var()
		file.close()
	else:
		unlocked_cosmetics = {}
