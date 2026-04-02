extends Node

signal skill_unlocked(skill_id: String, level: int)
signal skill_points_changed(new_amount: int)

var skill_points: int = 1 # Start with 1 free point

# Define available skills
var skills: Dictionary = {
	"lucky_catch": {
		"name": "Lucky Catch",
		"description": "10% chance to catch double fish.",
		"level": 0,
		"max_level": 3,
		"cost": 1
	},
	"fast_reel": {
		"name": "Fast Reel",
		"description": "Reel speed increased by 10%.",
		"level": 0,
		"max_level": 5,
		"cost": 1
	},
	"night_owl": {
		"name": "Night Owl",
		"description": "Fish bite 20% faster at night.",
		"level": 0,
		"max_level": 1,
		"cost": 2
	},
	"sturdy_line": {
		"name": "Sturdy Line",
		"description": "Line tension increases slower.",
		"level": 0,
		"max_level": 3,
		"cost": 1
	}
}

const SAVE_FILE_PATH = "user://skills.json"

func _ready():
	load_skills()

func reset():
	skill_points = 1
	for id in skills:
		skills[id].level = 0
	skill_points_changed.emit(skill_points)
	save_skills()
	print("Skills Reset!")

func save_skills():
	var data = {
		"points": skill_points,
		"skills": skills
	}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_skills():
	if not FileAccess.file_exists(SAVE_FILE_PATH): return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			skill_points = data.get("points", 1)
			var loaded_skills = data.get("skills", {})
			# Merge levels carefully to preserve static data like cost/desc if they changed in code
			for id in loaded_skills:
				if skills.has(id):
					skills[id].level = loaded_skills[id].get("level", 0)
			
			skill_points_changed.emit(skill_points)

func add_skill_points(amount: int):
	skill_points += amount
	skill_points_changed.emit(skill_points)
	save_skills()

func can_unlock_skill(skill_id: String) -> bool:
	if not skills.has(skill_id): return false
	var skill = skills[skill_id]
	return skill.level < skill.max_level and skill_points >= skill.cost

func unlock_skill(skill_id: String) -> bool:
	if can_unlock_skill(skill_id):
		var skill = skills[skill_id]
		skill_points -= skill.cost
		skill.level += 1
		skill_points_changed.emit(skill_points)
		skill_unlocked.emit(skill_id, skill.level)
		print("Unlocked skill: ", skill_id, " Level: ", skill.level)
		return true
	return false

func get_skill_level(skill_id: String) -> int:
	if skills.has(skill_id):
		return skills[skill_id].level
	return 0

func get_bonus(skill_id: String) -> float:
	var level = get_skill_level(skill_id)
	if level == 0: return 0.0
	
	# Logic for bonus calculation based on skill
	match skill_id:
		"lucky_catch": return level * 0.10 # 10% per level
		"fast_reel": return level * 0.10 # 10% per level
		"night_owl": return level * 0.20 # 20%
		"sturdy_line": return level * 0.15 # 15% reduction
	return 0.0
