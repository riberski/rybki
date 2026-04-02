extends Node

signal journal_updated(fish_id: String, record_data: Dictionary)
signal new_species_caught(fish_id: String)
signal new_record_weight(fish_id: String, weight: float)

# Journal Data Structure:
# {
#   "fish_id": {
#       "caught_count": 0,
#       "max_weight": 0.0,
#       "is_discovered": false
#   }
# }

var journal: Dictionary = {}
const SAVE_FILE_PATH = "user://journal.json"

func _ready():
	InventoryManager.inventory_updated.connect(_on_fish_caught)
	load_journal()

func _on_fish_caught(fish):
	if fish == null: return # Selling
	
	var id = fish.id
	var weight = fish.base_weight # W przyszłości to powinno być unikalne waga instancji, ale na razie używamy base lub symulujemy
	# Symulacja wagi instancji (jeśli nie jest przekazywana, to generujemy tu lub bierzemy z obiektu jeśli tam była losowana)
	# Zakładamy, że FishResource to "gatunek", a konkretna ryba powinna mieć wagę. 
	# inventory_manager trzyma FishResource. 
	# Jeśli chcemy unikalne wagi, musielibyśmy mieć instancje ryb. 
	# Na potrzeby journala, możemy dodać losową wariancję tutaj, jeśli system ryb tego nie ma,
	# albo po prostu używać base_weight.
	
	# Sprawdzenie czy mamy wpis
	if not journal.has(id):
		journal[id] = {
			"caught_count": 0,
			"max_weight": 0.0,
			"is_discovered": false
		}
	
	var entry = journal[id]
	
	# New Discovery?
	if not entry["is_discovered"]:
		entry["is_discovered"] = true
		new_species_caught.emit(id)
	
	# Update Count
	entry["caught_count"] += 1
	
	# Check Record (Symulujemy, że waga tej konkretnej ryby to base_weight +/- 20%)
	# Uwaga: To trochę hack, bo w ekwipunku ryba może mieć inną wagę jeśli tam nie zapisujemy instancji.
	# Ale w FishingManager3D waga jest używana do fizyki.
	# Przyjmijmy base_weight jako wagę dla uproszczenia, lub dodajmy "instancję" ryby do sygnału inventory.
	# Na razie base_weight.
	
	if weight > entry["max_weight"]:
		entry["max_weight"] = weight
		new_record_weight.emit(id, weight)
	
	journal_updated.emit(id, entry)
	save_journal()

func get_entry(fish_id: String) -> Dictionary:
	return journal.get(fish_id, {
		"caught_count": 0,
		"max_weight": 0.0,
		"is_discovered": false
	})

func save_journal():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(journal))

func reset():
	journal.clear()
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	
	# Emit empty journal update or similar if UI listens? 
	# Actually wait, maybe clear UI signal?
	print("Journal Reset!")

func load_journal():
	if not FileAccess.file_exists(SAVE_FILE_PATH): return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			# Merge carefuly
			for id in data:
				journal[id] = data[id]
