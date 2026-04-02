extends Node3D
class_name SectorManager

# Signal emitted when the current sector changes
signal sector_changed(new_sector: SectorResource)

# Track the current active sector
var active_sector: SectorResource = null

# Reference to the Player
@export var player_path: NodePath
var player: Node3D

# Reference to WorldEnvironment
@export var world_environment: WorldEnvironment
# Reference to Water Shader Material
@export var water_material: ShaderMaterial

func _ready():
	_setup_sectors()
	# Try to find player if path not set
	if !player and has_node(player_path):
		player = get_node(player_path)
	elif !player:
		# Fallback: assume player is named "Player3D" in scene
		player = get_tree().current_scene.find_child("Player3D")

func _setup_sectors():
	# Find all child Area3D nodes that are sectors
	for child in get_children():
		if child is Area3D and child.has_meta("sector_resource"):
			child.body_entered.connect(_on_sector_body_entered.bind(child))
			child.body_exited.connect(_on_sector_body_exited.bind(child))

func _on_sector_body_entered(body: Node3D, sector_area: Area3D):
	if body == player:
		var new_sector_res = sector_area.get_meta("sector_resource")
		if new_sector_res:
			_change_sector(new_sector_res)

func _on_sector_body_exited(body: Node3D, sector_area: Area3D):
	if body == player and active_sector == sector_area.get_meta("sector_resource"):
		# Check if we are still inside another sector area?
		# For now, just keep the last one or revert to default?
		# Usually overlapping areas handle this naturally, the LAST entered is usually prioritized.
		pass

func _change_sector(new_sector: SectorResource):
	if active_sector == new_sector:
		return
		
	active_sector = new_sector
	emit_signal("sector_changed", active_sector)
	
	print("Entered Sector: " + active_sector.display_name)
	
	_apply_sector_environment(new_sector)

func _apply_sector_environment(sector: SectorResource):
	# Apply visual changes
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		# Tween fog density for smooth transition
		var tween = create_tween()
		tween.tween_property(env, "volumetric_fog_density", sector.fog_density, 2.0)
		
	if water_material:
		# Tween water color
		var tween = create_tween()
		tween.tween_property(water_material, "shader_parameter/albedo", sector.water_color, 2.0)

# Helper function to get current hazard
func get_current_hazard() -> String:
	if active_sector:
		return active_sector.hazard_type
	return "NONE"

func get_current_difficulty() -> int:
	if active_sector:
		return active_sector.difficulty_tier
	return 1
