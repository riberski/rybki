extends CharacterBody3D

@export var speed := 8.0 # Troszkę szybciej łódką
@export var acceleration := 10.0
@export var friction := 5.0
@export var mouse_sensitivity := 0.2
@export var water_level := -1.0
@export var buoyancy_force := 10.0
@export var water_drag := 2.0

# Animation settings
@export var bob_frequency := 2.0
@export var bob_amplitude := 0.05
@export var rock_frequency := 1.5
@export var rock_amplitude := 0.02
@export var impact_cooldown := 1.0
var last_impact_time := 0.0

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/SpringArm3D/Camera3D
@onready var rod_pivot = $RodPivot
@onready var rod_tip = $RodPivot/RodMesh/RodTip
@onready var boat_mesh = $BoatMesh
var original_boat_y := 0.0

var direction := Vector3.ZERO
var rotation_y := 0.0
var default_rod_rotation: Vector3

var time_passed := 0.0



@onready var fishing_manager_scene = preload("res://src/fishing/fishing_manager3d.tscn")
var fishing_manager

# Shop UI scene
var shop_ui_scene = preload("res://src/ui/shop_ui.tscn")
var shop_ui

# Skill UI scene
var skill_ui_scene = preload("res://src/ui/skill_ui.tscn")
var skill_ui

# GameOver
var game_over_scene = preload("res://src/ui/game_over_screen.tscn")

# Draft UI
var draft_ui_scene = preload("res://src/ui/draft_ui.tscn")

# Pause Menu
var pause_menu_scene = preload("res://src/ui/pause_menu.tscn")
var pause_menu

# Removed local inventory_manager reference, using global InventoryManager autoload
@onready var inventory_ui = $CanvasLayer/InventoryUI
@onready var journal_ui = $CanvasLayer/JournalUI

@onready var interact_label_node = $CanvasLayer/InteractLabel
var notification_label_node: Label
var current_interactable = null
var is_casting_anim = false

# Camera Shake Params
var shake_strength: float = 0.0
var shake_decay: float = 5.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if boat_mesh:
		original_boat_y = boat_mesh.position.y
	
	if rod_pivot:
		default_rod_rotation = rod_pivot.rotation
	
	fishing_manager = fishing_manager_scene.instantiate()
	add_child(fishing_manager)
	
	# Interact UI
	if has_node("CanvasLayer/InteractLabel"):
		interact_label_node = $CanvasLayer/InteractLabel
	else:
		interact_label_node = Label.new()
		interact_label_node.name = "InteractLabel"
		interact_label_node.text = "Press E to Interact"
		interact_label_node.visible = false
		
		# If CanvasLayer exists:
		if has_node("CanvasLayer"):
			$CanvasLayer.add_child(interact_label_node)
		else:
			add_child(interact_label_node)
			
		interact_label_node.anchors_preset = Control.PRESET_CENTER_BOTTOM
		interact_label_node.position = Vector2(0, -100)
		interact_label_node.grow_horizontal = Control.GROW_DIRECTION_BOTH
		interact_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Notification Label
	notification_label_node = Label.new()
	notification_label_node.name = "NotificationLabel"
	notification_label_node.visible = false
	notification_label_node.anchors_preset = Control.PRESET_CENTER_TOP
	notification_label_node.position = Vector2(0, 200)
	notification_label_node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notification_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label_node.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	notification_label_node.add_theme_font_size_override("font_size", 24)
	
	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(notification_label_node)
	else:
		add_child(notification_label_node)

	# Connect Notifications
	InventoryManager.level_up.connect(func(sp): show_notification("Level Up! SP: " + str(sp)))
	if has_node("/root/QuestManager"):
		QuestManager.quest_completed.connect(func(q): show_notification("Quest Completed: " + q.description))
	if has_node("/root/AchievementManager"):
		AchievementManager.achievement_unlocked.connect(func(id, data): show_notification("Achievement Unlocked: " + data.title))
	
	# Podpinamy końcówkę wędki (lub rękę gracza) do managera
	fishing_manager.rod_tip = rod_tip
	
	# Instantiate Shop UI
	shop_ui = shop_ui_scene.instantiate()
	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(shop_ui)
	else:
		add_child(shop_ui)
		
	shop_ui.hide() # Ensure hidden at start
	
	# Instantiate Skill UI
	if skill_ui_scene:
		skill_ui = skill_ui_scene.instantiate()
		if has_node("CanvasLayer"):
			$CanvasLayer.add_child(skill_ui)
		else:
			add_child(skill_ui)
		skill_ui.hide()
		# Instantiate Pause Menu
	pause_menu = pause_menu_scene.instantiate()
	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(pause_menu)
	else:
		add_child(pause_menu)
		
	# Instantiate Game Over Screen
	var game_over = game_over_scene.instantiate()
	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(game_over)
	else:
		add_child(game_over)

	# Instantiate Draft UI
	var draft_ui = draft_ui_scene.instantiate()
	if has_node("CanvasLayer"):
		$CanvasLayer.add_child(draft_ui)
	else:
		add_child(draft_ui)
		
	# Setup Inventory UI using the Global AutoLoad
	if inventory_ui:
		inventory_ui.set_inventory_manager(InventoryManager)

	
	# Connect Catch Popup to Global Inventory
	if fishing_manager.catch_popup:
		if not fishing_manager.catch_popup.keep_fish.is_connected(InventoryManager.add_fish):
			fishing_manager.catch_popup.keep_fish.connect(InventoryManager.add_fish)
		
	# If there was a local node, remove it to avoid confusion
	if has_node("InventoryManager"):
		get_node("InventoryManager").queue_free()

func open_shop():
	if shop_ui:
		shop_ui.show_shop()

func set_interactable(obj):
	current_interactable = obj
	if interact_label_node:
		interact_label_node.visible = (obj != null)
		if obj and obj.has_method("get_interact_text"):
			interact_label_node.text = "Press E to " + obj.get_interact_text()

func is_ui_open() -> bool:
	if pause_menu and pause_menu.visible: return true
	if fishing_manager and fishing_manager.catch_popup and fishing_manager.catch_popup.visible:
		return true
	if shop_ui and shop_ui.visible: return true
	if inventory_ui and inventory_ui.visible: return true
	if journal_ui and journal_ui.visible: return true
	if skill_ui and skill_ui.visible: return true
	return false

func _unhandled_input(event):
	if is_ui_open():
		if pause_menu and pause_menu.visible and event.is_action_pressed("ui_cancel"):
			pause_menu.hide_menu()
			return
		
		# Shop
		# Allow closing specific UIs with specific keys
		if shop_ui and shop_ui.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_inventory")):
			shop_ui.hide_shop()
			return
		if inventory_ui and inventory_ui.visible and event.is_action_pressed("toggle_inventory"):
			inventory_ui.hide_inventory()
			return
		if journal_ui.visible and event.is_action_pressed("toggle_journal"):
			journal_ui.hide_journal()
			return
		if skill_ui and skill_ui.visible and event is InputEventKey and event.pressed and event.keycode == KEY_K:
			skill_ui.hide_skills()
			return
		
		# If a UI is open, generally consume the input unless it's a toggle we just handled
		return

	if event.is_action_pressed("ui_cancel"):
		if pause_menu:
			pause_menu.show_menu()
		return

	if event.is_action_pressed("interact") and current_interactable:
		current_interactable.interact(self)
	
	if event.is_action_pressed("cycle_bait"):
		# Assuming BaitDatabase is autoload
		var next_bait = BaitDatabase.get_next_bait_id(InventoryManager.current_bait_id)
		InventoryManager.change_bait(next_bait)
		if interact_label_node:
			# Temporary feedback
			show_notification("Switched to " + next_bait, 1.0)
	
	if event.is_action_pressed("toggle_inventory") and inventory_ui: 
		if fishing_manager.catch_popup and fishing_manager.catch_popup.visible: return
		
		# Close others
		if journal_ui and journal_ui.visible: journal_ui.hide_journal()
		
		if inventory_ui.visible:
			inventory_ui.hide_inventory()
		else:
			inventory_ui.show_inventory()
			
	if event.is_action_pressed("toggle_journal") and journal_ui:
		if fishing_manager.catch_popup and fishing_manager.catch_popup.visible: return
		
		# Close others
		if inventory_ui and inventory_ui.visible: inventory_ui.hide_inventory()
		
		if journal_ui.visible:
			journal_ui.hide_journal()
		else:
			journal_ui.show_journal()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if fishing_manager.catch_popup and fishing_manager.catch_popup.visible: return
		
		# Close others
		if inventory_ui and inventory_ui.visible: inventory_ui.hide_inventory()
		if journal_ui and journal_ui.visible: journal_ui.hide_journal()
		if shop_ui and shop_ui.visible: shop_ui.hide_shop()
		
		if skill_ui:
			if skill_ui.visible:
				skill_ui.hide_skills()
			else:
				skill_ui.show_skills()

	if inventory_ui.visible or (journal_ui and journal_ui.visible) or (skill_ui and skill_ui.visible): return # Block other inputs if UI open

	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity * 0.01
		rotation.y = rotation_y
		
		var pitch = camera_pivot.rotation.x - event.relative.y * mouse_sensitivity * 0.01
		camera_pivot.rotation.x = clamp(pitch, deg_to_rad(-60), deg_to_rad(60))
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			cast_rod()

func cast_rod():
	if not fishing_manager: return
	if fishing_manager.current_state != fishing_manager.State.IDLE: return
	if is_casting_anim: return

	# Check bait before casting animation
	if InventoryManager.get_bait_count(InventoryManager.current_bait_id) <= 0:
		show_notification("No Bait! Press B to check inventory.", 2.0)
		return

	is_casting_anim = true
	
	if rod_pivot:
		var tween = create_tween()
		# Wind up
		tween.tween_property(rod_pivot, "rotation:x", default_rod_rotation.x + deg_to_rad(45.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Snap forward
		tween.tween_property(rod_pivot, "rotation:x", default_rod_rotation.x - deg_to_rad(45.0), 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		# Recover
		tween.tween_property(rod_pivot, "rotation:x", default_rod_rotation.x, 0.5).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): is_casting_anim = false)
		
	# Delay cast slightly to match snap (wait for snap to complete)
	get_tree().create_timer(0.4).timeout.connect(func():
		var from = rod_tip.global_position
		var cast_dir = -camera.global_transform.basis.z 
		fishing_manager.cast_bobber(from, cast_dir)
	)

func reel_rod():
	if fishing_manager:
		var target_pos = global_transform.origin
		fishing_manager.reel(target_pos, 20.0)
		
		# Animate rod shake
		if rod_pivot and not is_casting_anim:
			var shake_mult = 1.0
			if fishing_manager._has_fish:
				# Scale by tension ratio
				var ratio = fishing_manager.current_tension / fishing_manager.max_tension
				shake_mult = 1.0 + (ratio * 5.0) # UP to 6x shake
				
			var intensity = 0.05 * shake_mult
			rod_pivot.rotation.x = default_rod_rotation.x + randf_range(-intensity, intensity)
			rod_pivot.rotation.y = default_rod_rotation.y + randf_range(-intensity * 0.5, intensity * 0.5)

func apply_shake(strength: float):
	shake_strength = max(shake_strength, strength)

func show_notification(text: String, duration: float = 2.0):
	if notification_label_node:
		notification_label_node.text = text
		notification_label_node.visible = true
		
		# Animate
		notification_label_node.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_interval(duration)
		tw.tween_property(notification_label_node, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): notification_label_node.visible = false)

func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		
		# Apply random offset to camera
		camera.h_offset = randf_range(-shake_strength, shake_strength)
		camera.v_offset = randf_range(-shake_strength, shake_strength)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

func _physics_process(delta):
	# --- BOAT CHASE LOGIC ---
	# If fighting a fish, input is disabled and boat is dragged by fish
	if fishing_manager and fishing_manager.current_state == fishing_manager.State.REELING:
		# Still apply water friction so we don't accelerate infinitely
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
		# Bobbing animation during chase
		if boat_mesh:
			time_passed += delta
			var bob_offset = sin(time_passed * bob_frequency * 2.0) * bob_amplitude # Faster bobbing
			boat_mesh.position.y = original_boat_y + bob_offset
			# Tilt towards velocity
			var target_tilt = (-velocity.x * 0.05)
			var target_pitch = (-velocity.z * 0.02)
			boat_mesh.rotation.z = move_toward(boat_mesh.rotation.z, target_tilt, delta * 2.0)
			boat_mesh.rotation.x = move_toward(boat_mesh.rotation.x, target_pitch, delta * 2.0)
			
		move_and_slide() 
		return
	# ------------------------

	# Block movement if UI is open
	if is_ui_open():
		return

	# Handle reeling
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		reel_rod()
	elif rod_pivot and not is_casting_anim:
		# Reset rod rotation (smoothly)
		rod_pivot.rotation.x = move_toward(rod_pivot.rotation.x, default_rod_rotation.x, delta * 2.0)
		rod_pivot.rotation.y = move_toward(rod_pivot.rotation.y, default_rod_rotation.y, delta * 2.0)
		rod_pivot.rotation.z = move_toward(rod_pivot.rotation.z, default_rod_rotation.z, delta * 2.0)

	# Water Buoyancy & Gravity logic
	if global_position.y < water_level:
		# Jesteśmy w wodzie - wyporność
		var depth = water_level - global_position.y
		# Siła wyporu: grawitacja w górę + zależna od głębokości (sprężynowanie)
		# get_gravity() jest ujemne (np. (0, -9.8, 0)), więc odejmujemy je, żeby zneutralizować, i dodajemy siłę w górę
		var buoyancy = -get_gravity() * (depth * 0.5 + 1.0) 
		velocity += (buoyancy + get_gravity()) * delta
		
		# Opór wody (hamuje ruch w pionie i poziomie)
		velocity = velocity.move_toward(Vector3.ZERO, water_drag * delta)
	else:
		# Jesteśmy w powietrzu lub na ziemi (np. na doku)
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = speed * (1.0 + (InventoryManager.boat_speed_level - 1) * 0.2)
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
	# Boat Animation Logic
	if boat_mesh:
		time_passed += delta
		
		# Bobbing (vertical)
		var bob_offset = sin(time_passed * bob_frequency) * bob_amplitude
		boat_mesh.position.y = original_boat_y + bob_offset
		
		# Rocking (idle + move)
		var rock_roll = sin(time_passed * rock_frequency) * rock_amplitude
		var rock_pitch = cos(time_passed * rock_frequency * 0.7) * rock_amplitude 
		
		var target_tilt = (-input_dir.x * 0.1) + rock_roll
		var target_pitch = (-input_dir.y * 0.05) + rock_pitch
		
		boat_mesh.rotation.z = move_toward(boat_mesh.rotation.z, target_tilt, delta * 2.0)
		boat_mesh.rotation.x = move_toward(boat_mesh.rotation.x, target_pitch, delta * 2.0)

	var speed_before = velocity.length()
	move_and_slide()
	
	# Collision Damage Logic
	if get_slide_collision_count() > 0:
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_impact_time > impact_cooldown:
			var collision = get_slide_collision(0)
			if collision and speed_before > 8.0: # Higher threshold (boat normal speed is 8, boost > 8)
				last_impact_time = now
				var damage = 10.0 # Flat damage for now
				if QuotaManager:
					QuotaManager.take_damage(damage)
				
				# Bounce/knockback
				velocity = velocity.bounce(collision.get_normal()) * 0.5
				show_notification("CRASH! Hull Damage!", 1.0)
				apply_shake(0.5)
