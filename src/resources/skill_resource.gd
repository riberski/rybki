extends Resource
class_name SkillResource

@export var id: String = "skill_id"
@export var skill_name: String = "Skill Name"
@export_multiline var description: String = "Skill Description"
@export var icon: Texture2D
@export var max_level: int = 1
@export var cost: int = 0 # Cost in money or XP points?
@export var type: String = "passive" # e.g., "passive", "active"
