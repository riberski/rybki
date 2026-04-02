extends Node

# CollectionManager.gd
# Zarządza kolekcjami ryb, relikwi, kosmetyków

signal collection_updated(type, id)

var fish_collection = {}
var relic_collection = {}
var cosmetic_collection = {}

func add_to_collection(type, id):
	match type:
		"fish":
			fish_collection[id] = true
		"relic":
			relic_collection[id] = true
		"cosmetic":
			cosmetic_collection[id] = true
	save_state()
	emit_signal("collection_updated", type, id)

func has_in_collection(type, id):
	match type:
		"fish":
			return fish_collection.has(id)
		"relic":
			return relic_collection.has(id)
		"cosmetic":
			return cosmetic_collection.has(id)
	return false

func save_state():
	var state = {
		"fish": fish_collection,
		"relic": relic_collection,
		"cosmetic": cosmetic_collection
	}
	var file = FileAccess.open("user://collection_manager.save", FileAccess.WRITE)
	file.store_var(state)
	file.close()

func load_state():
	if FileAccess.file_exists("user://collection_manager.save"):
		var file = FileAccess.open("user://collection_manager.save", FileAccess.READ)
		var state = file.get_var()
		file.close()
		fish_collection = state.get("fish", {})
		relic_collection = state.get("relic", {})
		cosmetic_collection = state.get("cosmetic", {})
	else:
		fish_collection = {}
		relic_collection = {}
		cosmetic_collection = {}
