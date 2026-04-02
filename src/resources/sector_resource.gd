extends Resource
class_name SectorResource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var difficulty_tier: int = 1 # 1-4
@export var ambient_music: AudioStream

@export_group("Environmental Hazards")
@export var hazard_type: String = "NONE" # ACID, ICE, VORTEX, ELECTRIC
@export var hazard_intensity: float = 0.0

@export_group("Fish Population")
@export var available_fish: Array[Resource] = [] # Array of FishResource
@export var fish_rarity_multiplier: float = 1.0

@export_group("Visuals")
@export var fog_density: float = 0.0
@export var water_color: Color = Color(0.0, 0.5, 1.0, 1.0)
