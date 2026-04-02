extends Resource
class_name BaitResource

@export var name: String = "Generic Bait"
@export var price: int = 10
@export var attraction_bonus: float = 1.0 # Multiplier for bite speed (higher is faster)
@export var quality: float = 1.0 # Multiplier for fish value/rarity chance
@export var icon: Texture2D
