extends CharacterBody3D

@export var speed := 8.0 # Troszkę szybciej łódką
@export var acceleration := 10.0
@export var friction := 5.0
@export var mouse_sensitivity := 0.2
@export var water_level := -1.0
@export var float_height_offset := 0.1 # Unosi łódkę wyżej, mniej zalewania
@export var buoyancy_force := 150.0 # Większa siła wyporu, mniej tonięcia
@export var water_drag := 4.0 # Keep drag
var water_node : Node3D = null

# Animation settings
@export var bob_frequency := 2.0
@export var bob_amplitude := 0.05
@export var rock_frequency := 1.5
@export var rock_amplitude := 0.02
@export var impact_cooldown := 1.0
var last_impact_time := 0.0

# Splash FX
var splash_fx_scene = preload("res://src/fx/splash_particles.tscn")
var was_underwater = false
var min_splash_velocity = -1.5 # Prędkość uderzenia wymagana do plusku
var fish_preview_mesh_paths := [
	"res://src/assets/Fish1.obj",
	"res://src/assets/Fish2.obj",
	"res://src/assets/Fish3.obj"
]
var fish_preview_meshes: Array[ArrayMesh] = []

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/SpringArm3D/Camera3D
# These rod nodes might crash if renamed, using find_child is safer but let's assume they exist
@onready var rod_pivot = $RodPivot
@onready var rod_tip = $RodPivot/RodMesh/RodTip
@onready var boat_mesh = $BoatMesh
@onready var boat_depth_mask = $BoatDepthMask
@onready var player_mesh = $MeshInstance3D
var original_boat_y := 0.0
var mask_local_offset := Vector3.ZERO
var fish_preview_mesh_instance: MeshInstance3D
var fish_preview_hide_timer: Timer

@export var fish_preview_height := 1.0
@export var fish_preview_duration := 2.0
@export var fish_preview_scale := Vector3.ONE * 0.35

var direction := Vector3.ZERO
var rotation_y := 0.0
var default_rod_rotation: Vector3

var time_passed := 0.0

# Store initial rotation to allow manual editor adjustments
var initial_mesh_basis: Basis

@onready var fishing_manager_scene = preload("res://src/fishing/fishing_manager3d.tscn")
var fishing_manager

# UI References (Now fetched dynamically from Main Scene UI)
var inventory_ui: Control
var journal_ui: Control
var shop_ui: Control
var skill_ui: Control
var draft_ui: Control
var pause_menu: Control
var interact_label_node: Label
var notification_label_node: Label
var catch_popup_ui: Control
var _notification_serial: int = 0

var current_interactable = null
var area_interactable = null # Set by triggers like Shop
var is_casting_anim = false

# Camera Shake Params
var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_boat_y = boat_mesh.position.y
	initial_mesh_basis = boat_mesh.transform.basis # Capture editor rotation
	if boat_depth_mask:
		mask_local_offset = boat_mesh.transform.basis.inverse() * (boat_depth_mask.position - boat_mesh.position)
	default_rod_rotation = rod_pivot.rotation
	
	setup_fishing_manager()
	_setup_fish_preview()
	
	# Find UI Nodes in the Scene
	# Prefer get_parent() if it's Main3D scene root
	var search_root = get_parent()
	if not search_root: search_root = get_tree().current_scene
	
	if search_root:
		# Use owned=false to be safe with instanced scenes
		inventory_ui = search_root.find_child("InventoryUI", true, false)
		journal_ui = search_root.find_child("JournalUI", true, false)
		shop_ui = search_root.find_child("ShopUI", true, false)
		skill_ui = search_root.find_child("SkillUI", true, false)
		draft_ui = search_root.find_child("DraftUI", true, false)
		pause_menu = search_root.find_child("PauseMenu", true, false)
		catch_popup_ui = search_root.find_child("CatchPopup", true, false)
		
		# For Interact Label, we might need to create it if missing in Main3D
		# Try to find a generic Label or create one
		interact_label_node = search_root.find_child("InteractLabel", true, false)
		if not interact_label_node:
			# Look in Player's own children (fallback) with recursion
			interact_label_node = find_child("InteractLabel", true, false)
		
		notification_label_node = search_root.find_child("NotificationLabel", true, false)

	_ensure_runtime_ui_labels(search_root)
	_connect_runtime_notifications()
	
	# Find Water Node for wave physics
	if search_root:
		water_node = search_root.find_child("Water", true, false)

func setup_fishing_manager():
	if not fishing_manager_scene: return
	fishing_manager = fishing_manager_scene.instantiate()
	add_child(fishing_manager)
	if not fishing_manager.fish_caught.is_connected(_on_fish_caught):
		fishing_manager.fish_caught.connect(_on_fish_caught)

func _setup_fish_preview():
	fish_preview_meshes.clear()
	for mesh_path in fish_preview_mesh_paths:
		var loaded = load(mesh_path)
		if loaded is ArrayMesh:
			fish_preview_meshes.append(loaded)

	fish_preview_hide_timer = Timer.new()
	fish_preview_hide_timer.one_shot = true
	fish_preview_hide_timer.timeout.connect(_hide_fish_preview)
	add_child(fish_preview_hide_timer)

	fish_preview_mesh_instance = MeshInstance3D.new()
	fish_preview_mesh_instance.visible = false
	fish_preview_mesh_instance.scale = fish_preview_scale
	fish_preview_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	if player_mesh:
		player_mesh.add_child(fish_preview_mesh_instance)
	else:
		add_child(fish_preview_mesh_instance)

	fish_preview_mesh_instance.position = Vector3(0.0, fish_preview_height, 0.0)

func _on_fish_caught(fish_resource):
	if fish_preview_meshes.is_empty() or fish_preview_mesh_instance == null:
		return

	var mesh_index := randi() % fish_preview_meshes.size()
	if fish_resource and fish_resource.get("name") != null:
		mesh_index = abs(String(fish_resource.name).hash()) % fish_preview_meshes.size()

	fish_preview_mesh_instance.mesh = fish_preview_meshes[mesh_index]
	fish_preview_mesh_instance.rotation = Vector3(0.0, PI, 0.0)
	fish_preview_mesh_instance.position = Vector3(0.0, fish_preview_height, 0.0)
	fish_preview_mesh_instance.visible = true

	if fish_preview_hide_timer:
		fish_preview_hide_timer.start(max(0.1, fish_preview_duration))

func _hide_fish_preview():
	if fish_preview_mesh_instance:
		fish_preview_mesh_instance.visible = false

func spawn_splash(water_y_pos: float):
	if splash_fx_scene:
		var splash = splash_fx_scene.instantiate()
		get_parent().add_child(splash)
		splash.global_position = global_position
		splash.global_position.y = water_y_pos
		splash.emitting = true
		
		# Optional: Add small random size varation
		var scale_mod = randf_range(0.8, 1.2)
		splash.scale = Vector3(scale_mod, scale_mod, scale_mod)

	
func _physics_process(delta):
	var gameplay_blocked := _is_gameplay_input_blocked()

	# Movement - TANK CONTROLS (Independent of Camera)
	
	# Rotation (A/D)
	# "move_right" (D) -> rotate negative (clockwise)
	# "move_left" (A) -> rotate positive (counter-clockwise)
	var turn_input := 0.0
	if not gameplay_blocked:
		turn_input = Input.get_axis("move_right", "move_left")
	if turn_input:
		rotation_y += turn_input * 2.5 * delta # 2.5 radians/sec turn speed
	
	# Movement (W/S)
	# "move_forward" (W) -> positive value
	var forward_input := 0.0
	if not gameplay_blocked:
		forward_input = Input.get_axis("move_backward", "move_forward")
	
	# Calculate Boat Forward Vector (Standard Godot Forward is -Z)
	# We construct a vector pointing "forward" relative to current rotation_y
	# sin/cos gives rotation from +Z (0,0,1). 
	# So we negate it to get rotation from -Z (0,0,-1) or just use the math for forward vector.
	var boat_forward = Vector3(sin(rotation_y), 0, cos(rotation_y))
	
	# If we want forward_input > 0 to move forward (along -Z with 0 rotation),
	# we expect (0,0,-1). 
	# sin(0)=0, cos(0)=1 -> (0,0,1). So we need to negate.
	var move_dir = -boat_forward
	
	# Mechanic: NITRO BOOST
	var current_speed = speed
	if not gameplay_blocked and InventoryManager and InventoryManager.can_nitro_boost:
		if Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT):
			current_speed *= InventoryManager.nitro_speed_multiplier
			# TODO: Add Nitro FX here
	
	if forward_input:
		# Accelerate along boat's forward axis
		var target_velocity = move_dir * forward_input * current_speed
		
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		# Mechanic: HOVER SKIRT (Less Friction) & ANCHOR (Max Friction)
		var friction_factor = friction
		if InventoryManager:
			friction_factor *= InventoryManager.physics_friction_multiplier
			
			if not gameplay_blocked and InventoryManager.can_anchor_brake and (Input.is_key_pressed(KEY_CTRL) or Input.is_action_pressed("ui_down")):
				friction_factor *= 10.0 # Anchor!
		
		velocity.x = move_toward(velocity.x, 0, friction_factor * delta)
		velocity.z = move_toward(velocity.z, 0, friction_factor * delta)
	
	# Buoyancy (Dynamic Waves) - 4-Point Sampling for Stability
	var avg_water_height = water_level
	var water_normal = Vector3.UP
	
	if water_node and water_node.has_method("get_height_at_position"):
		# Update water shader with boat position to create "hole" mask
		if water_node.has_method("update_boat_position"):
			water_node.update_boat_position(global_position)
		if water_node.has_method("update_boat_rotation"):
			water_node.update_boat_rotation(rotation_y)
			
		# Define sampling offsets relative to boat center (rotated by boat yaw)
		# Assuming boat length ~4m (z +/- 2) and width ~2m (x +/- 1)
		var basis_rot = Basis(Vector3.UP, rotation_y)
		var offset_front = basis_rot * Vector3(0, 0, -2.0)
		var offset_back = basis_rot * Vector3(0, 0, 2.0)
		var offset_left = basis_rot * Vector3(-1.0, 0, 0)
		var offset_right = basis_rot * Vector3(1.0, 0, 0)
		
		var h_f = water_node.get_height_at_position(global_position + offset_front)
		var h_b = water_node.get_height_at_position(global_position + offset_back)
		var h_l = water_node.get_height_at_position(global_position + offset_left)
		var h_r = water_node.get_height_at_position(global_position + offset_right)
		var h_c = water_node.get_height_at_position(global_position) # Center
		
		# Average height for buoyancy
		avg_water_height = (h_f + h_b + h_l + h_r + h_c) / 5.0
		
		# Calculate Normal from slopes
		# Tangent Z (Front - Back)
		var tangent_z = (Vector3(0, h_f, -2.0) - Vector3(0, h_b, 2.0)).normalized()
		# Tangent X (Right - Left)
		var tangent_x = (Vector3(1.0, h_r, 0) - Vector3(-1.0, h_l, 0)).normalized()
		
		# Normal is Cross(Tangent_Z, Tangent_X) ? No, typically Z is Forward.
		# Godot: Forward is -Z. 
		# If Tangent Z points Forward (0,0,-1ish)
		# Tangent X points Right (1,0,0ish)
		# Cross(X, -Z) -> -Y?
		# Let's align vectors to world space logic.
		# Vector Front-Back is roughly (0,0,-4). 
		# Vector Right-Left is roughly (2,0,0).
		# We want Up. 
		# (Right-Left) x (Back-Front) -> X axis x Z axis -> -Y?
		# (Right-Left) x (Front-Back) -> X axis x -Z axis -> Y axis. Correct.
		
		var v_z = (global_position + offset_front) - (global_position + offset_back)
		v_z.y = h_f - h_b
		
		var v_x = (global_position + offset_right) - (global_position + offset_left)
		v_x.y = h_r - h_l
		
		water_normal = v_x.cross(v_z).normalized()
	else:
		avg_water_height = water_level
	
	var current_water_height = avg_water_height
	
	# Mechanic: BOAT JUMP
	if not gameplay_blocked and InventoryManager and InventoryManager.can_boat_jump:
		if Input.is_action_just_pressed("ui_accept"): # Default Spacebar
			# Only jump if near water surface
			if global_position.y < current_water_height + 0.5:
				velocity.y = InventoryManager.boat_jump_force
				# Spawn splash FX
				spawn_splash(current_water_height)

	# Where we want the boat origin to sit relative to water surface
	var target_float_height = current_water_height + float_height_offset
	if InventoryManager:
		target_float_height += InventoryManager.float_height_modifier

	# Maksymalne zanurzenie łódki pod wodą (np. 0.2m poniżej powierzchni)
	var max_submerge = 0.2
	if global_position.y < current_water_height - max_submerge:
		global_position.y = current_water_height - max_submerge
		velocity.y = max(velocity.y, 0.0)

	# If below ideal float level, push up
	if global_position.y < target_float_height:
		var depth = target_float_height - global_position.y

		# EMERGENCY BUOYANCY
		if depth > 1.5:
			global_position.y = lerp(global_position.y, target_float_height, 10.0 * delta)
			velocity.y = max(velocity.y, 5.0)

		# Standard buoyancy proportional to depth
		var buoyancy = buoyancy_force * depth

		# If really deep relative to float target, push harder
		if depth > 0.5:
			buoyancy *= 4.0

		velocity.y += buoyancy * delta

		# Strong drag to stop endless bouncing
		velocity.y = move_toward(velocity.y, 0, water_drag * delta)

		# Cap downward velocity if underwater
		if velocity.y < 0.0:
			velocity.y = move_toward(velocity.y, 0.0, 20.0 * delta)
	else:
		# Gravity above float level
		velocity.y -= 9.8 * delta

		# Extra gravity just above target height to stick to waves
		if global_position.y < target_float_height + 0.5:
			velocity.y -= 5.0 * delta

	
	# Splash Logic (Check for hitting actual water surface)
	var is_underwater = global_position.y < current_water_height
	if is_underwater and not was_underwater:
		# Boat just hit the water
		if velocity.y < min_splash_velocity:
			spawn_splash(current_water_height)
	
	was_underwater = is_underwater
	
	move_and_slide()
	
	# Rotation Visuals
	# Calculate the base rotation (Y-axis steering)
	var steering_basis = initial_mesh_basis.rotated(Vector3.UP, rotation_y)
	
	if water_node:
		# Align the local UP vector of the steered basis to the water normal
		var cross_prod = Vector3.UP.cross(water_normal)
		
		# Only correct if not parallel (cross product has length)
		if cross_prod.length_squared() > 0.0001:
			var correction_axis = cross_prod.normalized()
			var dot = clamp(Vector3.UP.dot(water_normal), -1.0, 1.0)
			var correction_angle = acos(dot)
			
			# Apply tilt correction in world space
			var correction_quat = Quaternion(correction_axis, correction_angle)
			steering_basis = Basis(correction_quat) * steering_basis

	# Smoothly interpolate ROTATION ONLY (preserving scale)
	var current_quat = boat_mesh.transform.basis.get_rotation_quaternion()
	var new_quat = steering_basis.get_rotation_quaternion()
	
	# Slerp the rotation
	var slerped_quat = current_quat.slerp(new_quat, 5.0 * delta)
	
	# Apply back to mesh, preserving original scale
	var final_basis = Basis(slerped_quat)
	final_basis = final_basis.scaled(initial_mesh_basis.get_scale())
	
	boat_mesh.transform.basis = final_basis
	
	# Bobbing Effect: avoid double bobbing while wave buoyancy is active.
	if not water_node:
		time_passed += delta
		var bob = sin(time_passed * bob_frequency) * bob_amplitude
		boat_mesh.position.y = original_boat_y + bob
	else:
		boat_mesh.position.y = original_boat_y

	# Keep depth mask locked to boat transform, including rotated pivot offset.
	if boat_depth_mask:
		boat_depth_mask.transform.basis = boat_mesh.transform.basis
		boat_depth_mask.position = boat_mesh.position + (boat_mesh.transform.basis * mask_local_offset)

	# Rotate Player Character (The "Bean") and Fishing Rod to match Camera direction
	# This lets the player look around freely while steering the boat independently
	if player_mesh:
		# Smoothly rotate player towards camera angle
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, camera_pivot.rotation.y, 15.0 * delta)
		
	if rod_pivot:
		# Also rotate the fishing rod so it stays with the player model
		rod_pivot.rotation.y = player_mesh.rotation.y
	
	# Check interactions only when gameplay is active.
	if not gameplay_blocked:
		check_interactables()
	else:
		current_interactable = null
		if interact_label_node:
			interact_label_node.hide()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate Camera Only (Orbit around boat)
		# Independent from boat body rotation
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		
		# Rotate Camera Pitch
		camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity * 0.01
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(10))

	# Toggle Inventory
	if Input.is_action_just_pressed("toggle_inventory"):
		toggle_ui(inventory_ui)
		return

	if Input.is_action_just_pressed("toggle_journal"):
		toggle_ui(journal_ui)
		return

	if _is_gameplay_input_blocked():
		return

	# Casting / Action
	if Input.is_action_just_pressed("interact"):
		# If interactable object near, interact
		if current_interactable and current_interactable.has_method("interact"):
			current_interactable.interact(self)
	
	if Input.is_action_just_pressed("cast_rod"):
		# Try to cast OR hook depending on state
		if fishing_manager:
			# Access state via the manager script class if needed, or check logic
			# Assuming fishing_manager has public state variable
			if fishing_manager.get("current_state") == 0: # IDLE
				if not is_casting_anim and not current_interactable:
					var cast_dir = -camera_pivot.global_transform.basis.z
					fishing_manager.start_casting(rod_tip.global_position, cast_dir)
			else:
				# If not IDLE (Waiting, Biting, etc), try to hook/reel
				fishing_manager.try_hook()

func set_interactable(obj):
	area_interactable = obj
	# Force an update immediately so the text appears
	check_interactables()

func open_shop():
	if shop_ui:
		toggle_ui(shop_ui)
		return

	var root = get_tree().current_scene
	if not root:
		root = get_parent() # Fallback to parent

	if root:
		shop_ui = root.find_child("ShopUI", true, false)
		if shop_ui:
			toggle_ui(shop_ui)

func toggle_ui(ui_node):
	if not ui_node:
		return

	if ui_node.visible:
		if ui_node.has_method("hide_inventory"):
			ui_node.hide_inventory()
		else:
			ui_node.hide()
	else:
		if ui_node.has_method("show_inventory"):
			ui_node.show_inventory()
		else:
			ui_node.show()

	_refresh_mouse_mode_from_ui_state()

func check_interactables():
	if _is_gameplay_input_blocked():
		current_interactable = null
		if interact_label_node:
			interact_label_node.hide()
		return

	# Perform a raycast or area check for interactables
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * 5.0 # 5 meters range
	var query = PhysicsRayQueryParameters3D.create(from, to)

	# Exclude self
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	current_interactable = null

	if result:
		var collider = result.collider
		if collider.has_method("interact"):
			current_interactable = collider
			if interact_label_node:
				interact_label_node.text = "Press E to interact"
				interact_label_node.show()
			return

	# If nothing from Raycast, try Area trigger
	if not current_interactable and area_interactable:
		current_interactable = area_interactable
		if interact_label_node:
			var txt = "Press E to Interact"
			if area_interactable.has_method("get_interact_text"):
				txt = area_interactable.get_interact_text()
			interact_label_node.text = txt
			interact_label_node.show()
		return

	if interact_label_node:
		interact_label_node.hide()

func show_notification(text: String, duration: float = 2.0):
	if notification_label_node:
		_notification_serial += 1
		var token := _notification_serial
		notification_label_node.text = text
		notification_label_node.show()
		await get_tree().create_timer(duration).timeout
		if token == _notification_serial and notification_label_node:
			notification_label_node.hide()
	else:
		print("Notification: ", text)

func _is_ui_visible(ui_node: Control) -> bool:
	return ui_node != null and ui_node.visible

func _is_gameplay_input_blocked() -> bool:
	return get_tree().paused \
		or _is_ui_visible(inventory_ui) \
		or _is_ui_visible(journal_ui) \
		or _is_ui_visible(shop_ui) \
		or _is_ui_visible(skill_ui) \
		or _is_ui_visible(draft_ui) \
		or _is_ui_visible(pause_menu) \
		or _is_ui_visible(catch_popup_ui)

func _refresh_mouse_mode_from_ui_state() -> void:
	if _is_gameplay_input_blocked():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _connect_runtime_notifications() -> void:
	if InventoryManager and not InventoryManager.level_up.is_connected(_on_level_up_notification):
		InventoryManager.level_up.connect(_on_level_up_notification)
	if QuestManager and not QuestManager.quest_completed.is_connected(_on_quest_completed_notification):
		QuestManager.quest_completed.connect(_on_quest_completed_notification)
	if AchievementManager and not AchievementManager.achievement_unlocked.is_connected(_on_achievement_unlocked_notification):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked_notification)

func _on_level_up_notification(new_sp: int) -> void:
	show_notification("Level up! SP: %d" % new_sp, 2.0)

func _on_quest_completed_notification(quest_data: Dictionary) -> void:
	var desc := str(quest_data.get("description", "Contract complete"))
	show_notification("Quest complete: %s" % desc, 2.5)

func _on_achievement_unlocked_notification(_achievement_id: String, achievement_data: Dictionary) -> void:
	var title := str(achievement_data.get("title", "Achievement unlocked"))
	show_notification("Achievement: %s" % title, 2.5)

func _ensure_runtime_ui_labels(search_root: Node) -> void:
	var ui_parent: Node = null
	if search_root:
		ui_parent = search_root.find_child("UI", true, false)
	if ui_parent == null and has_node("CanvasLayer"):
		ui_parent = $CanvasLayer
	if ui_parent == null:
		ui_parent = self

	if interact_label_node == null:
		interact_label_node = Label.new()
		interact_label_node.name = "InteractLabel"
		interact_label_node.text = "Press E to interact"
		interact_label_node.visible = false
		ui_parent.add_child(interact_label_node)
		interact_label_node.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		interact_label_node.offset_top = -120.0
		interact_label_node.offset_bottom = -80.0
		interact_label_node.grow_horizontal = Control.GROW_DIRECTION_BOTH
		interact_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if notification_label_node == null:
		notification_label_node = Label.new()
		notification_label_node.name = "NotificationLabel"
		notification_label_node.visible = false
		ui_parent.add_child(notification_label_node)
		notification_label_node.set_anchors_preset(Control.PRESET_CENTER_TOP)
		notification_label_node.offset_top = 110.0
		notification_label_node.offset_bottom = 150.0
		notification_label_node.grow_horizontal = Control.GROW_DIRECTION_BOTH
		notification_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notification_label_node.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		notification_label_node.add_theme_font_size_override("font_size", 22)
