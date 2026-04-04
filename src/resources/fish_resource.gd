extends Resource
class_name FishResource

@export var id: String
@export var name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var base_weight: float = 1.0
@export var difficulty: float = 1.0 # 1.0 = łatwa, 5.0 = bardzo trudna
@export var value: int = 10
@export var rarity: float = 0.5 # 0.0 - common, 1.0 - legendary
@export var is_nocturnal: bool = false # Only active at night?
@export var stamina: float = 100.0
@export var preferred_bait_id: String = ""
@export_enum("Any", "Day", "Night") var active_time: String = "Any"
@export_enum("Mixed", "Smooth", "Sinker", "Floater", "Dart") var behavior_type: String = "Mixed"
@export var mesh: Mesh # Model 3D ryby (opcjonalnie)
