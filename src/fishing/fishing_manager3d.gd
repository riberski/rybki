extends Node3D

# State Machine
enum State { IDLE, CASTING, WAITING, BITING, REELING }
var current_state = State.IDLE

# Signals
signal bite_hooked
signal fish_caught(fish_resource)
signal fish_lost

# Exported References
@export var bobber_scene: PackedScene = preload("res://src/fishing/bobber3d.tscn")
@export var splash_scene: PackedScene = preload("res://src/fx/splash_particles.tscn")
@export var minigame_ui_path: NodePath
var minigame_ui: Control # Will assign dynamically

# Internal Variables
var bobber_instance: RigidBody3D
var bite_timer: Timer
var hook_timer: Timer
var line_mesh: ImmediateMesh
var line_mesh_instance: MeshInstance3D

# Fishing Params
@export var throw_force: float = 15.0
@export var fish_pull_boat_base: float = 2.4
@export var fish_pull_boat_max: float = 7.5
@export var fish_escape_multiplier: float = 1.95
@export var fish_escape_burst_strength: float = 1.35
@export var fish_escape_burst_frequency: float = 1.8
var active_bait_stats = {"attraction": 1.0, "quality": 1.0}
var current_fish: FishResource

# Player Reference
var player_ref: Node3D
var rod_tip: Node3D

func _ready():
	# Setup Timers
	bite_timer = Timer.new()
	bite_timer.one_shot = true
	bite_timer.timeout.connect(_on_bite_timeout)
	add_child(bite_timer)
	
	hook_timer = Timer.new()
	hook_timer.one_shot = true
	hook_timer.timeout.connect(_on_hook_timeout)
	add_child(hook_timer)
	
	player_ref = get_parent() # Assuming Player is parent
	
	# Setup Visuals
	_setup_line_renderer()

	if minigame_ui_path != NodePath(""):
		minigame_ui = get_node_or_null(minigame_ui_path)
	if not minigame_ui and get_tree().current_scene:
		minigame_ui = get_tree().current_scene.find_child("FishingMinigameUI", true, false)

func _setup_line_renderer():
	line_mesh = ImmediateMesh.new()
	line_mesh_instance = MeshInstance3D.new()
	line_mesh_instance.mesh = line_mesh
	line_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mesh_instance.material_override = mat
	
	# Add to main scene so it doesn't rotate with player locally
	# Use call deferred to wait for tree
	call_deferred("_add_line_to_scene")

func _add_line_to_scene():
	if not is_instance_valid(line_mesh_instance):
		return
	if line_mesh_instance.get_parent() == null and get_tree().current_scene:
		get_tree().current_scene.add_child(line_mesh_instance)

func _exit_tree():
	if is_instance_valid(line_mesh_instance):
		line_mesh_instance.queue_free()

func _process(_delta):
	_update_line_visual()
	
	if current_state == State.WAITING:
		if bobber_instance and bobber_instance.global_position.y < -10:
			# Failsafe if bobber falls out of world
			reset_fishing()

func _physics_process(delta):
	# Fish Run Mechanic: When reeling, the fish fights and swims away
	if current_state == State.REELING and is_instance_valid(bobber_instance) and is_instance_valid(player_ref):
		var bobber_body = bobber_instance as RigidBody3D
		if bobber_body:
			var shift = bobber_body.global_position - player_ref.global_position
			var dist = shift.length()
			var direction_away = shift.normalized()
			direction_away.y = 0 
			
			# Fish Strength / Run Away
			var wiggle_mult = 1.0
			if InventoryManager:
				wiggle_mult = InventoryManager.fish_run_wiggle_multiplier
			var fish_difficulty = 1.0
			if current_fish:
				fish_difficulty = float(current_fish.difficulty)
			var boat_speed = 8.0
			if player_ref and player_ref.has_method("get"):
				var speed_value = player_ref.get("speed")
				if speed_value != null:
					boat_speed = float(speed_value)
			if InventoryManager and InventoryManager.can_nitro_boost:
				boat_speed *= InventoryManager.nitro_speed_multiplier
			# Reduced force to prevent "space launch" and ensure Y is damped
			var rarity = 0.0
			if current_fish:
				rarity = float(current_fish.rarity)
			var run_force = 6.0 + (fish_difficulty * 1.2)
			# Rare fish flee faster, capped below boat speed
			run_force *= lerp(1.0, 1.5, clamp(rarity, 0.0, 1.0))
			run_force *= fish_escape_multiplier
			var burst_phase = max(0.0, sin(Time.get_ticks_msec() / 1000.0 * fish_escape_burst_frequency * wiggle_mult))
			var burst = lerp(1.0, fish_escape_burst_strength, burst_phase)
			run_force *= burst
			if InventoryManager:
				run_force *= InventoryManager.fish_run_force_multiplier
			var max_run_force = max(boat_speed * 1.35, 8.0)
			run_force = clamp(run_force, 5.0, max_run_force)
			var final_force = direction_away * run_force
			
			# Fish drags the boat while reeling: stronger fish pull more.
			if player_ref is CharacterBody3D:
				var boat_body := player_ref as CharacterBody3D
				var pull_strength = fish_pull_boat_base + (fish_difficulty * 0.9)
				pull_strength *= lerp(1.0, 1.6, clamp(rarity, 0.0, 1.0))
				if InventoryManager:
					pull_strength *= InventoryManager.fish_run_force_multiplier
				pull_strength = clamp(pull_strength, 0.0, fish_pull_boat_max)
				var boat_pull = final_force.normalized() * pull_strength
				boat_pull.y = 0.0
				boat_body.velocity += boat_pull * delta
			
			# Safety: Clamp vertical velocity if it gets crazy
			if bobber_body.linear_velocity.y > 5.0:
				bobber_body.linear_velocity.y = 5.0
			
			# Pull away on water too, keeping force horizontal
			bobber_body.apply_central_force(final_force)
			if bobber_body.global_position.y >= 0.0:
				# If above water, gravity should take over, correct velocity
				bobber_body.linear_velocity.y -= 9.8 * delta * 2.0
			
			# Chase Mechanic: Update UI challenge based on distance to fish
			# "niech ryba ucieka przed łodzią więc będziemy łapać się" -> Chase it!
			if minigame_ui:
				# 15m is standard cast distance (1.0x).
				# Reduced bonus close to boat so catches don't resolve too quickly.
				var catch_mod = clamp(1.45 - (dist / 24.0), 0.6, 1.6)
				if InventoryManager:
					catch_mod *= InventoryManager.distance_modifier_multiplier
				minigame_ui.distance_modifier = clamp(catch_mod, 0.55, 1.8)



# --- Public Actions ---

func start_casting(origin: Vector3, direction: Vector3, charge: float = 1.0):
	if current_state != State.IDLE: return
	
	# 1. Consume Bait
	var active_bait = InventoryManager.use_current_bait()
	if active_bait.is_empty():
		print("No Bait!")
		_notify_player("No bait available", 1.8)
		_check_resource_end()
		return
		
	# 2. Check Resource Limit (Bread)
	# If this was the last bread, we flag it but continue casting
	if InventoryManager.get_bait_count("bread") <= 0:
		print("LAST CAST! Make it count!")
		_notify_player("Last bread cast", 1.4)
	
	# 3. Spawn Bobber
	if not bobber_scene:
		bobber_scene = load("res://src/fishing/bobber3d.tscn")
	
	bobber_instance = bobber_scene.instantiate()
	get_tree().current_scene.add_child(bobber_instance)
	bobber_instance.global_position = origin
	
	# 4. Apply Physics
	active_bait_stats = active_bait
	current_state = State.CASTING
	if RunMetrics:
		RunMetrics.record_cast()
	
	if bobber_instance is RigidBody3D:
		# Apply Cast Range Multiplier
		var mult = 1.0
		if InventoryManager: mult = InventoryManager.cast_range_multiplier
		
		var cast_mult = 1.0
		if InventoryManager:
			cast_mult *= InventoryManager.cast_force_multiplier
		var impulse = direction.normalized() * (throw_force * charge * mult * cast_mult)
		impulse.y += 2.0 
		bobber_instance.apply_central_impulse(impulse)
	
	# 5. Wait for "Splash" / Landed
	# Simulate landing for now
	await get_tree().create_timer(1.0).timeout
	if current_state == State.CASTING:
		_on_bobber_landed()

func _on_bobber_landed():
	current_state = State.WAITING
	print("Bobber landed. Waiting...")
	
	# Calculate wait time
	var attraction = active_bait_stats.get("attraction", 1.0)
	var base_time = randf_range(2.0, 5.0)
	var time = base_time / attraction
	if InventoryManager:
		time *= InventoryManager.bite_time_multiplier
	bite_timer.start(time)

func _on_bite_timeout():
	if current_state != State.WAITING: return
	
	current_state = State.BITING
	print("BITE!")
	if RunMetrics:
		RunMetrics.record_bite()
	emit_signal("bite_hooked")
	
	# FX
	if bobber_instance:
		var splash = splash_scene.instantiate()
		get_tree().current_scene.add_child(splash)
		splash.global_position = bobber_instance.global_position
		
		# Dip bobber
		bobber_instance.apply_central_impulse(Vector3.DOWN * 5.0)
	
	# Hook Window
	var hook_window = 1.0
	if InventoryManager:
		hook_window *= InventoryManager.hook_window_multiplier
	hook_timer.start(hook_window)

func _on_hook_timeout():
	if current_state == State.BITING:
		var retry = false
		if InventoryManager and randf() < InventoryManager.bite_retry_chance:
			retry = true
		if retry:
			current_state = State.WAITING
			bite_timer.start(0.6)
		else:
			print("Fish got away...")
			_notify_player("Fish got away", 1.4)
			if RunMetrics:
				RunMetrics.record_loss()
			reset_fishing()

func try_hook():
	if current_state == State.BITING:
		print("HOOKED!")
		if RunMetrics:
			RunMetrics.record_hook()
		hook_timer.stop()
		start_minigame()
	elif current_state == State.WAITING:
		print("Pulled too early!")
		_notify_player("Too early", 1.2)
		if RunMetrics:
			RunMetrics.record_loss()
		reset_fishing()
	elif current_state == State.REELING:
		# Already reeling, maybe fast forward or cancel? No-op.
		pass
	else:
		reset_fishing()

func start_minigame():
	current_state = State.REELING
	
	# Pick Fish
	current_fish = FishDatabase.get_random_fish()
	if not current_fish:
		print("Error: No fish found in database!")
		reset_fishing()
		return
		
	# Find UI if needed
	if not minigame_ui:
		# Search in CanvasLayer
		minigame_ui = get_tree().current_scene.find_child("FishingMinigameUI", true, false)

	if not minigame_ui:
		_notify_player("Minigame UI missing", 2.0)
		reset_fishing()
		return
	
	if minigame_ui:
		var speed_multiplier = 1.0
		if QuestManager and not QuestManager.active_quest.is_empty():
			var active = QuestManager.active_quest
			if active.get("type", "") == "earn_money":
				speed_multiplier = float(active.get("fish_speed_multiplier", 1.0))
		minigame_ui.setup_game(current_fish, speed_multiplier)
		minigame_ui.show()
		minigame_ui.start_minigame()
		
		# Connect signal if not already
		if not minigame_ui.is_connected("minigame_finished", _on_minigame_finished):
			minigame_ui.connect("minigame_finished", _on_minigame_finished)
		
		# Keep camera look active while reeling.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_minigame_finished(success: bool):
	if minigame_ui: minigame_ui.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if success:
		print("Caught: ", current_fish.name)
		InventoryManager.add_expedition_fish(current_fish)
		if RunMetrics:
			RunMetrics.record_catch()
		emit_signal("fish_caught", current_fish)
		
		# Show Catch Popup
		var popup = get_tree().current_scene.find_child("CatchPopup", true, false)
		if popup:
			popup.show_fish(current_fish)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			# Wait for popup to close before resetting state
			# We disconnect first to avoid multiple connections if reused
			if popup.is_connected("popup_closed", _on_popup_closed):
				popup.disconnect("popup_closed", _on_popup_closed)
			popup.connect("popup_closed", _on_popup_closed, CONNECT_ONE_SHOT)
			return # Do NOT reset yet
			
	else:
		if RunMetrics:
			RunMetrics.record_loss()
		_notify_player("Fish escaped", 1.5)
		emit_signal("fish_lost")
	
	reset_fishing()

func _on_popup_closed():
	reset_fishing()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func check_for_turn_end():
	# If current bait is bread and we have 0 left, end day
	# Design: Bread is the main turn counter. If Bread == 0, end day.
	if InventoryManager.get_bait_count("bread") <= 0:
		print("Out of Bread! Calling QuotaManager end check...")
		if QuotaManager: QuotaManager.check_run_status()

func _check_resource_end():
	# Called when trying to cast but failing due to no bait
	check_for_turn_end()

func reset_fishing():
	current_state = State.IDLE
	if is_instance_valid(bobber_instance):
		bobber_instance.queue_free()
	bobber_instance = null
	
	if line_mesh:
		line_mesh.clear_surfaces()
	
	# Check for Game Over / Next Day *AFTER* the cast is fully complete
	check_for_turn_end()

func _notify_player(message: String, duration: float = 1.5) -> void:
	if is_instance_valid(player_ref) and player_ref.has_method("show_notification"):
		player_ref.show_notification(message, duration)

func _update_line_visual():
	if not line_mesh: return
	line_mesh.clear_surfaces()
	
	if current_state == State.IDLE: return
	if not is_instance_valid(bobber_instance): return
	
	# Find Rod Tip dynamically if null
	if not rod_tip:
		var p = get_parent()
		if p: rod_tip = p.find_child("RodTip", true, false)
	
	if not rod_tip: return
	
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	line_mesh.surface_add_vertex(rod_tip.global_position)
	line_mesh.surface_add_vertex(bobber_instance.global_position)
	line_mesh.surface_end()
