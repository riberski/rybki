extends Node3D

@export var player_scene: PackedScene = preload("res://src/player/Player3D.tscn")
@export var shop_scene: PackedScene = preload("res://src/world/Shop.tscn")
@export var rain_scene: PackedScene = preload("res://src/fx/rain_particles.tscn")
@export var obstacle_rock_scene: PackedScene = preload("res://src/world/obstacle_rock.tscn")
@export var extraction_zone_script: Script = preload("res://src/world/extraction_zone.gd")

@onready var sun_light = $DirectionalLight3D
@onready var sun_visual = $SunVisual
@onready var existing_world_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
var world_env: WorldEnvironment
var rain_instance: GPUParticles3D
var player_instance: Node3D
var extraction_zone_instances: Array[Area3D] = []

@export var sun_orbit_radius: float = 220.0
@export var sun_azimuth_degrees: float = 35.0
@export var daylight_energy: float = 1.15
@export var night_energy: float = 0.05
@export_file("*.hdr", "*.exr", "*.png", "*.jpg", "*.jpeg") var hdri_sky_path: String = "res://src/assets/hdri/sky.exr"
@export var hdri_sky_energy: float = 1.0

func _ready():
	_cleanup_legacy_world_chunks()
	setup_environment()
	spawn_player()
	spawn_extraction_zones()
	# spawn_shop() # Shop is now in Main3D.tscn
	spawn_obstacles()

	if TimeManager and not TimeManager.extraction_started.is_connected(_on_extraction_started):
		TimeManager.extraction_started.connect(_on_extraction_started)
	if TimeManager and not TimeManager.extraction_finished.is_connected(_on_extraction_finished):
		TimeManager.extraction_finished.connect(_on_extraction_finished)
	
	# Connect Weather System
	if rain_instance and world_env:
		# Use Call Deferred to ensure nodes are ready
		call_deferred("_setup_weather_manager")

func _cleanup_legacy_world_chunks() -> void:
	for node_name in ["Kamyczki", "Kamyk3"]:
		var node := get_node_or_null(node_name)
		if node:
			node.queue_free()

func _setup_weather_manager():
	WeatherManager.set_environment_references(world_env, rain_instance)

func setup_environment():
	# Reuse scene WorldEnvironment when available to keep map authoring intact.
	if existing_world_env:
		world_env = existing_world_env
		if world_env.environment == null:
			world_env.environment = Environment.new()
	else:
		world_env = WorldEnvironment.new()
		var env := Environment.new()
		_configure_default_environment(env)
		world_env.environment = env
		add_child(world_env)

	if world_env and world_env.environment:
		if not _apply_hdri_sky(world_env.environment):
			# Keep a usable sky when no HDRI file is present yet.
			_configure_default_environment(world_env.environment)
	
	# Create Rain Particles (attached to camera or player later)
	rain_instance = rain_scene.instantiate()
	add_child(rain_instance)
	rain_instance.position = Vector3(0, 10, 0) # Start high
	rain_instance.emitting = false

func _configure_default_environment(env: Environment) -> void:
	env.background_mode = Environment.BG_SKY
	if env.sky == null:
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

func _apply_hdri_sky(env: Environment) -> bool:
	if hdri_sky_path.strip_edges().is_empty():
		return false
	if not ResourceLoader.exists(hdri_sky_path):
		return false

	var loaded := load(hdri_sky_path)
	if loaded == null or not (loaded is Texture2D):
		return false

	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = loaded as Texture2D
	panorama.energy_multiplier = hdri_sky_energy

	var sky := Sky.new()
	sky.sky_material = panorama

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return true

func _process(delta):
	_update_sun_and_lighting()
		
	# Update Rain Position
	if rain_instance and player_instance:
		var pos = player_instance.global_position
		rain_instance.global_position = Vector3(pos.x, pos.y + 10.0, pos.z)

	_update_extraction_point_activity()


func spawn_player():
	player_instance = player_scene.instantiate()
	var spawn = $PlayerSpawn
	add_child(player_instance)
	player_instance.global_transform.origin = spawn.global_transform.origin # Safe after add_child
	# Ustaw kamerę gracza jako current
	player_instance.get_node("CameraPivot/SpringArm3D/Camera3D").current = true

func spawn_shop():
	var shop = shop_scene.instantiate()
	add_child(shop)
	# Position near the dock, slightly off-center
	# Dock was at (0, -0.75, 5). Let's put shop at (5, -0.5, 5)
	shop.global_position = Vector3(5, -0.5, 5)
	shop.rotation_degrees.y = -90

func spawn_obstacles():
	if not obstacle_rock_scene: return
	
	for i in range(15):
		var rock = obstacle_rock_scene.instantiate()
		add_child(rock)
		
		# Valid spawn area: -20 to 20, excluding dock area
		var valid = false
		var pos = Vector3.ZERO
		
		for attempt in range(10): # Try 10 times to find spot
			pos = Vector3(
				randf_range(-20.0, 20.0),
				randf_range(-0.5, 0.5), # Slight vertical variation
				randf_range(-20.0, 20.0)
			)
			
			# Check distance to Dock (approx 0, 0, 5)
			if pos.distance_to(Vector3(0, 0, 5)) > 8.0:
				valid = true
				break
		
		if valid:
			rock.global_position = pos
			rock.rotation.y = randf() * TAU
			rock.scale = Vector3.ONE * randf_range(0.8, 2.0)
		else:
			rock.queue_free()

func spawn_extraction_zones() -> void:
	if extraction_zone_script == null:
		return

	var points = [
		{"name": "ExtractionStatic", "type": 0, "window": Vector2i(0, 1200), "capacity": 99},
		{"name": "ExtractionDynamic", "type": 1, "window": Vector2i(45, 1200), "capacity": 1},
		{"name": "ExtractionHidden", "type": 2, "window": Vector2i(0, 1200), "capacity": 1},
		{"name": "ExtractionEmergency", "type": 3, "window": Vector2i(0, 1200), "capacity": 1}
	]

	for point in points:
		var zone := Area3D.new()
		zone.name = str(point["name"])
		zone.set_script(extraction_zone_script)
		add_child(zone)
		if zone.has_method("initialize_visuals"):
			zone.initialize_visuals()
		if zone.has_method("configure"):
			zone.configure(int(point["type"]), point["window"], int(point["capacity"]))
		extraction_zone_instances.append(zone)

	_randomize_extraction_zone_positions()

func _on_extraction_started(_total_seconds: int) -> void:
	_randomize_extraction_zone_positions()
	for zone in extraction_zone_instances:
		if not is_instance_valid(zone):
			continue
		var point_type := int(zone.get("point_type"))
		if zone.has_method("set_active"):
			# Hidden point stays dark until discovered.
			zone.set_active(point_type != 2)
	if player_instance and player_instance.has_method("show_notification"):
		player_instance.show_notification("Nowy punkt ekstrakcji zostal oznaczony", 2.2)

func _on_extraction_finished(reason: String) -> void:
	if InventoryManager:
		InventoryManager.save_game()
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/lobby_world.tscn")

func _randomize_extraction_zone_positions() -> void:
	if extraction_zone_instances.is_empty():
		return

	var min_coord := -20.0
	var max_coord := 20.0
	var dock_pos := Vector3(0.0, 0.0, 5.0)
	var used_positions: Array[Vector3] = []

	for zone in extraction_zone_instances:
		if not is_instance_valid(zone):
			continue
		var chosen := Vector3(12.0, -0.45, -12.0)
		var found := false
		for _attempt in range(50):
			var candidate := Vector3(
				randf_range(min_coord, max_coord),
				-0.45,
				randf_range(min_coord, max_coord)
			)
			if candidate.distance_to(dock_pos) < 9.0:
				continue
			if player_instance and candidate.distance_to(player_instance.global_position) < 8.0:
				continue
			var too_close := false
			for used in used_positions:
				if candidate.distance_to(used) < 7.0:
					too_close = true
					break
			if too_close:
				continue
			chosen = candidate
			found = true
			break

		if not found:
			chosen = Vector3(randf_range(10.0, 16.0), -0.45, randf_range(-16.0, -10.0))
		zone.global_position = chosen
		used_positions.append(chosen)

func _update_extraction_point_activity() -> void:
	if TimeManager == null or extraction_zone_instances.is_empty():
		return

	var active := TimeManager.extraction_active
	var elapsed := 0
	if active:
		elapsed = TimeManager.extraction_duration_seconds - int(ceil(TimeManager.extraction_remaining_seconds))

	for zone in extraction_zone_instances:
		if not is_instance_valid(zone):
			continue
		if not zone.has_method("set_active"):
			continue

		var point_type := int(zone.get("point_type"))
		var should_be_active := active

		if point_type == 1:
			# Dynamic extraction appears after early roam period.
			should_be_active = active and elapsed >= 45
		elif point_type == 2:
			# Hidden extraction controls itself after discovery.
			continue
		elif point_type == 3:
			# Emergency extraction only in final minute.
			should_be_active = active and TimeManager.extraction_remaining_seconds <= 60.0

		zone.set_active(should_be_active)

func _update_sun_and_lighting() -> void:
	if sun_light == null:
		return

	var time_of_day: float = 12.0
	if TimeManager:
		time_of_day = TimeManager.current_time

	# 0..1 normalized day progress
	var day_t: float = fposmod(time_of_day, 24.0) / 24.0
	var sun_angle: float = day_t * TAU

	# Elevation curve: max at noon, below horizon at night
	var elevation_raw: float = sin(sun_angle - PI * 0.5)
	var elevation_norm: float = clamp((elevation_raw + 1.0) * 0.5, 0.0, 1.0)
	var daylight_factor: float = clamp((elevation_raw + 0.08) / 1.08, 0.0, 1.0)

	# Azimuth drift gives side-to-side sun travel across sky.
	var azimuth_rad: float = deg_to_rad(sun_azimuth_degrees)
	var horizontal: float = cos(sun_angle - PI * 0.5)
	var sun_dir := Vector3(
		horizontal * cos(azimuth_rad),
		elevation_raw,
		horizontal * sin(azimuth_rad)
	).normalized()

	# Directional light points along its -Z axis.
	sun_light.look_at(sun_light.global_position + sun_dir, Vector3.UP)
	sun_light.light_energy = lerp(night_energy, daylight_energy, daylight_factor)
	sun_light.light_color = Color(
		lerp(0.50, 1.0, elevation_norm),
		lerp(0.58, 0.96, elevation_norm),
		lerp(0.75, 0.86, elevation_norm)
	)

	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = lerp(0.22, 0.72, daylight_factor)

	if sun_visual:
		var center := Vector3.ZERO
		if player_instance:
			center = player_instance.global_position
		sun_visual.global_position = center + (sun_dir * sun_orbit_radius)
		sun_visual.visible = elevation_raw > -0.18
