extends Node

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

# Achievement Structure:
# {
#   "id": "first_catch",
#   "title": "First Cast",
#   "description": "Catch your first fish.",
#   "icon": null, # Texture path later
#   "unlocked": false
# }

var achievements: Dictionary = {
	"first_catch": {
		"title": "First Cast",
		"description": "Catch your first fish.",
		"unlocked": false
	},
	"novice_angler": {
		"title": "Novice Angler",
		"description": "Catch 10 fish.",
		"unlocked": false
	},
	"master_angler": {
		"title": "Master Angler",
		"description": "Catch 50 fish.",
		"unlocked": false
	},
	"big_earner": {
		"title": "Big Earner",
		"description": "Earn 1000 gold.",
		"unlocked": false
	},
	"lucky_catch": {
		"title": "Lucky Catch",
		"description": "Catch a rare fish.",
		"unlocked": false
	},
	"quest_hunter": {
		"title": "Quest Hunter",
		"description": "Complete 5 quests.",
		"unlocked": false
	}
}

var total_fish_caught: int = 0
var total_quests_completed: int = 0
var meta_currency: int = 0 # "Scales" or similar currency
const SAVE_FILE_PATH = "user://achievements.json"

func _ready():
	InventoryManager.inventory_updated.connect(_on_fish_caught)
	InventoryManager.money_updated.connect(_on_money_updated)
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").quest_completed.connect(_on_quest_completed)
	
	load_achievements()

func _on_fish_caught(fish):
	if fish == null: return # Selling
	
	total_fish_caught += 1
	
	unlock_achievement("first_catch")
	if fish.rarity >= 0.8:
		unlock_achievement("lucky_catch")
	
	if total_fish_caught >= 10:
		unlock_achievement("novice_angler")
	if total_fish_caught >= 50:
		unlock_achievement("master_angler")
		
	save_achievements()

func _on_money_updated(amount):
	if amount >= 1000:
		unlock_achievement("big_earner")
	save_achievements()

func reset():
	total_fish_caught = 0
	total_quests_completed = 0
	# Do NOT reset meta_currency on generic reset, maybe?
	# Usually meta persists. But if this is "Wipe Save", then yes.
	# Let's say reset() is only for debug wipe.
	meta_currency = 0
	
	for key in achievements:
		achievements[key]["unlocked"] = false
		
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	print("Achievements Reset!")

func _on_quest_completed(_quest_data):
	total_quests_completed += 1
	if total_quests_completed >= 5:
		unlock_achievement("quest_hunter")
	save_achievements()

func unlock_achievement(id: String):
	if not achievements.has(id): return
	if achievements[id]["unlocked"]: return # Already unlocked
	
	achievements[id]["unlocked"] = true
	achievement_unlocked.emit(id, achievements[id])
	print("ACHIEVEMENT UNLOCKED: ", achievements[id]["title"])
	save_achievements()

func add_meta_currency(amount: int):
	meta_currency += amount
	save_achievements()
	print("Earned %d Scales. Total: %d" % [amount, meta_currency])

func save_achievements():
	var save_data = {
		"achievements": achievements,
		"meta_currency": meta_currency,
		"stats": {
			"total_fish": total_fish_caught,
			"total_quests": total_quests_completed
		}
	}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

func load_achievements():
	if not FileAccess.file_exists(SAVE_FILE_PATH): return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		if data.has("meta_currency"):
			meta_currency = int(data["meta_currency"])
			
		if data.has("achievements"):
			# Merge loaded state with current structure (in case we added new ones)
			for id in data["achievements"]:
				if achievements.has(id):
					achievements[id]["unlocked"] = data["achievements"][id]["unlocked"]
		if data.has("stats"):
			total_fish_caught = data["stats"].get("total_fish", 0)
			total_quests_completed = data["stats"].get("total_quests", 0)
