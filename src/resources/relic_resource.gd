extends Resource
class_name RelicResource

@export var id: String
@export var name: String
@export_multiline var description: String
@export var rarity: String = "Common" # Common, Rare, Legendary, Cursed
@export var icon: Texture2D

# Effects
@export var stat_modifiers: Dictionary = {} 
# e.g. {"reel_speed": 0.1, "luck": 0.05, "fish_value": 0.2}

func apply(player):
	# Apply static modifiers to managers
	pass
