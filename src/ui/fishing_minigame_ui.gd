extends Control

# Signal to notify the manager
signal minigame_finished(success: bool)

# --- Stardew Valley Style Fishing Minigame ---
# Visual Configuration
const UI_HEIGHT = 400.0
const UI_WIDTH = 50.0
const FISH_SIZE = 20.0

# Physics Constants
var GRAVITY = 0.8        # Downward force (Easier)
var REEL_FORCE = 2.8     # Upward acceleration (rod pull reduced)
var BOUNCE = -0.3        # Bouncing off bottom

# Game State
var fish_position: float = 0.5    # 0.0 to 1.0 (logic bottom)
var bar_position: float = 0.0     # 0.0 to 1.0
var bar_velocity: float = 0.0

var catch_progress: float = 0.12  # 0.0 to 1.0
var CATCH_SPEED = 0.34            # Slower catch
var LOSE_SPEED = 0.08             # Faster lose
var CATCH_BAR_HEIGHT = 120.0      # Bigger bar default
var BASE_BAR_HEIGHT = 120.0       # Internal reference for dynamic sizing

var fish_target: float = 0.5
var fish_timer: float = 0.0
var fish_pause_timer: float = 0.0
var _is_running: bool = false
var _difficulty: float = 1.0
var distance_modifier: float = 1.0 # Distance impacts bar size
var fish_speed_multiplier: float = 1.0 # Contract-specific speed scaling
var global_fish_speed_boost: float = 1.35 # Make minigame feel like chasing fish
var minigame_fail_grace_active: bool = false
var minigame_fail_grace_amount: float = 0.15
var minigame_start_floor: float = 0.0
var minigame_bar_damping: float = 0.0
var minigame_bar_min_size: float = 30.0
var minigame_fish_stability_multiplier: float = 1.0
var minigame_dart_speed_multiplier: float = 1.0

# UI Nodes
var container: Panel
var catch_bar: ColorRect
var fish_icon: ColorRect
var progress_bg: ColorRect
var progress_rect: ColorRect


var active_behavior = "Mixed"
var behavior_timer = 0.0

func setup_game(fish_resource: FishResource, speed_multiplier: float = 1.0):
	var difficulty = fish_resource.difficulty # 1.0 to 5.0 typically
	fish_speed_multiplier = max(0.1, speed_multiplier) * global_fish_speed_boost
	GRAVITY = 0.85
	REEL_FORCE = 2.8
	BOUNCE = -0.3
	if InventoryManager:
		fish_speed_multiplier *= InventoryManager.minigame_fish_speed_multiplier
		fish_speed_multiplier *= InventoryManager.expedition_fish_speed_multiplier
		GRAVITY *= InventoryManager.minigame_gravity_multiplier
		minigame_bar_min_size = InventoryManager.minigame_bar_min_size
		minigame_fish_stability_multiplier = InventoryManager.minigame_fish_stability_multiplier
		minigame_dart_speed_multiplier = InventoryManager.minigame_dart_speed_multiplier
		minigame_fail_grace_active = InventoryManager.minigame_fail_grace
		minigame_fail_grace_amount = InventoryManager.minigame_fail_grace_amount
		minigame_start_floor = InventoryManager.minigame_start_floor
		minigame_bar_damping = InventoryManager.minigame_bar_damping
		REEL_FORCE *= InventoryManager.minigame_reel_force_multiplier
		BOUNCE *= InventoryManager.minigame_bounce_multiplier
	
	# Difficulty -> Bar Size (Harder = Smaller)
	# Base 150 (Huge), Min 50
	var bar_size = max(50.0, 200.0 - (difficulty * 25.0))
	if InventoryManager:
		bar_size *= InventoryManager.minigame_bar_size_multiplier
		bar_size = max(bar_size, InventoryManager.minigame_bar_min_size)
	
	# Difficulty -> Catch Speed (Harder = Faster Drain / Slower Fill)
	var catch_speed = max(0.14, 0.52 - (difficulty * 0.06))
	if InventoryManager:
		catch_speed *= InventoryManager.minigame_catch_speed_multiplier
	
	# Modifiers from Rod/Lure (Global InventoryManager)
	if InventoryManager:
		bar_size *= InventoryManager.line_strength_multiplier 
		catch_speed *= InventoryManager.reel_speed_multiplier
	
	BASE_BAR_HEIGHT = bar_size   # Store the difficulty-based unique size
	CATCH_BAR_HEIGHT = bar_size
	CATCH_SPEED = catch_speed
	LOSE_SPEED = 0.08
	if InventoryManager:
		LOSE_SPEED *= InventoryManager.minigame_lose_speed_multiplier
	
	# Start Progress Calculation
	var start_progress = 0.12
	if InventoryManager:
		start_progress += InventoryManager.minigame_start_bonus
		if minigame_start_floor > 0.0:
			start_progress = max(start_progress, minigame_start_floor)
		
		# Auto Catch Check
		if randf() < InventoryManager.auto_catch_chance:
			print("Quantum Lure Triggered! Instant Catch!")
			start_progress = 1.0
			
	catch_progress = clamp(start_progress, 0.0, 1.0)

	bar_position = 0.0
	bar_velocity = 0.0
	fish_position = 0.5
	fish_target = 0.5
	fish_timer = 0.0
	
	if "behavior_type" in fish_resource:
		active_behavior = fish_resource.behavior_type
	else:
		active_behavior = "Mixed"
	
	# UI update
	if catch_bar:
		catch_bar.custom_minimum_size.y = CATCH_BAR_HEIGHT
		catch_bar.size.y = CATCH_BAR_HEIGHT
	
	_difficulty = difficulty
	
	# If Instant Catch, we might need to signal win immediately next frame
	if catch_progress >= 1.0:
		call_deferred("_win")

func _ready():
	_setup_ui()
	set_process(false)
	visible = false

func _setup_ui():
	# Hide legacy nodes from the .tscn
	if has_node("Panel"): $Panel.visible = false
	
	# Create Main Container
	container = Panel.new()
	container.custom_minimum_size = Vector2(UI_WIDTH, UI_HEIGHT)
	container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	container.position.x = -100 # Offset from right
	container.position.y = -UI_HEIGHT/2
	container.size = Vector2(UI_WIDTH, UI_HEIGHT)
	add_child(container)
	
	# Catch Bar (Green)
	catch_bar = ColorRect.new()
	catch_bar.name = "CatchBar"
	catch_bar.color = Color(0.3, 0.9, 0.3, 0.7)
	catch_bar.custom_minimum_size = Vector2(UI_WIDTH - 4, CATCH_BAR_HEIGHT)
	catch_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(catch_bar)
	
	# Fish Icon (Orange)
	fish_icon = ColorRect.new()
	fish_icon.name = "Fish"
	fish_icon.color = Color(1.0, 0.5, 0.0)
	fish_icon.custom_minimum_size = Vector2(FISH_SIZE, FISH_SIZE)
	fish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(fish_icon)
	
	# Progress Bar (Side)
	progress_bg = ColorRect.new()
	progress_bg.color = Color(0.1, 0.1, 0.1)
	progress_bg.custom_minimum_size = Vector2(15, UI_HEIGHT)
	progress_bg.position = Vector2(UI_WIDTH + 10, 0)
	container.add_child(progress_bg)
	
	progress_rect = ColorRect.new()
	progress_rect.color = Color(0.2, 1.0, 0.2)
	progress_rect.custom_minimum_size = Vector2(15, 0)
	progress_rect.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	progress_rect.position.y = UI_HEIGHT
	progress_bg.add_child(progress_rect)

func start_minigame():
	visible = true
	_is_running = true
	set_process(true)
	
	if not container: _setup_ui()
	
	# If progress was already set high by setup_game (relics), keep it!
	# Only reset if it's strangely low (first run safety)
	if catch_progress <= 0.05:
		catch_progress = 0.2

func hide_minigame():
	visible = false
	_is_running = false
	set_process(false)

func _process(delta):
	if not _is_running: return
	
	# Update Bar Size based on distance (Closer = Bigger)
	# distance_modifier is ~0.5 (far) to 2.5 (close)
	var dynamic_size = BASE_BAR_HEIGHT * distance_modifier
	dynamic_size = clamp(dynamic_size, minigame_bar_min_size, UI_HEIGHT * 0.8) # Keep within sane limits
	
	# Smoothly resize
	CATCH_BAR_HEIGHT = lerp(CATCH_BAR_HEIGHT, dynamic_size, delta * 2.0)
	catch_bar.custom_minimum_size.y = CATCH_BAR_HEIGHT
	catch_bar.size.y = CATCH_BAR_HEIGHT
	
	# 1. Update Fish AI
	_update_fish_behaviour(delta)
	
	# 2. Update Bar Physics (Reel action)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_SPACE):
		bar_velocity += REEL_FORCE * delta
	if minigame_bar_damping > 0.0:
		bar_velocity = move_toward(bar_velocity, 0, minigame_bar_damping * delta)
	
	# Gravity & Sticky Gears Logic
	var grav_mod = 1.0
	if InventoryManager and InventoryManager.minigame_bar_glue:
		# If user is NOT pressing, stop faster (high drag)
		if bar_velocity > 0: bar_velocity -= 2.0 * delta # Extra drag up
		else: bar_velocity += 1.0 * delta # Extra dragg down? No, drag opposes velocity.
		# Basically, apply damping
		bar_velocity = move_toward(bar_velocity, 0, 5.0 * delta)
		grav_mod = 0.8 # Less gravity pull overall
	
	bar_velocity -= GRAVITY * grav_mod * delta
	bar_position += bar_velocity * delta
	
	# Bounce and Clamp
	var max_bar_pos = 1.0 - (CATCH_BAR_HEIGHT / UI_HEIGHT)
	if bar_position < 0.0:
		bar_position = 0.0
		if bar_velocity < 0: bar_velocity *= BOUNCE
	elif bar_position > max_bar_pos:
		bar_position = max_bar_pos
		bar_velocity = 0.0
		
	# 3. Check Overlap & Progress
	var bar_top_norm = bar_position + (CATCH_BAR_HEIGHT / UI_HEIGHT)
	if fish_position >= bar_position and fish_position <= bar_top_norm:
		# Closer to fish = faster catch! (Optional: We kept this too)
		catch_progress += CATCH_SPEED * delta # Removed distance mod from speed to balance size buff
		catch_bar.color = Color(0.3, 0.9, 0.3, 0.9)
	else:
		# Lose progress logic
		var drain_mult = 1.0
		if InventoryManager:
			drain_mult = InventoryManager.minigame_drain_multiplier
			
		catch_progress -= LOSE_SPEED * drain_mult * delta
		catch_bar.color = Color(0.8, 0.3, 0.3, 0.6)
		
	catch_progress = clamp(catch_progress, 0.0, 1.1) 
	# Allow slightly over 1.0 to trigger win
	
	if catch_progress >= 1.0:
		_win()
	elif catch_progress <= 0.0:
		if minigame_fail_grace_active:
			minigame_fail_grace_active = false
			catch_progress = minigame_fail_grace_amount
		else:
			_lose()
	
	_update_visuals()

func _update_fish_behaviour(delta):
	fish_timer -= delta
	behavior_timer += delta
	var max_fish_pos = 1.0 - (FISH_SIZE/UI_HEIGHT)
	
	if fish_pause_timer > 0.0:
		fish_pause_timer = max(0.0, fish_pause_timer - delta)
		return
	
	if InventoryManager and fish_timer <= 0.0:
		var pause_chance = InventoryManager.minigame_fish_pause_chance
		if pause_chance > 0.0 and randf() < pause_chance:
			fish_pause_timer = max(0.1, InventoryManager.minigame_fish_pause_duration)
			fish_timer = fish_pause_timer
			return
	
	match active_behavior:
		"Smooth": # "Pływają w kółko" (Sine wave pattern)
			var freq = (1.5 + (_difficulty * 0.5)) * fish_speed_multiplier
			var amp = 0.35
			# Center oscillation
			var sine_val = sin(behavior_timer * freq) * amp
			fish_target = 0.5 + sine_val
			# Smooth follow
			fish_position = lerp(fish_position, clamp(fish_target, 0.0, max_fish_pos), delta * 3.0 * fish_speed_multiplier)
			
		"Sinker": # "Stoją w miejscu" (Bottom preference, slow)
			if fish_timer <= 0:
				fish_timer = randf_range(2.0, 5.0) * minigame_fish_stability_multiplier
				# 80% chance to be at bottom, 20% to move up slightly
				if randf() < 0.8:
					fish_target = randf_range(0.0, 0.25)
				else:
					fish_target = randf_range(0.25, 0.5)
			
			# Very slow drift
			fish_position = move_toward(fish_position, fish_target, delta * 0.15 * fish_speed_multiplier)
			
		"Floater": # "Stoją w miejscu" (Top preference, slow)
			if fish_timer <= 0:
				fish_timer = randf_range(2.0, 5.0) * minigame_fish_stability_multiplier
				if randf() < 0.8:
					fish_target = randf_range(0.75, max_fish_pos)
				else:
					fish_target = randf_range(0.5, 0.75)
			
			fish_position = move_toward(fish_position, fish_target, delta * 0.15 * fish_speed_multiplier)
			
		"Dart": # "Szybciej uciekają" (Stop & Dash)
			if fish_timer <= 0:
				# 30% chance to Dash, 70% chance to Wait
				if randf() < 0.4:
					# DASH!
					fish_timer = randf_range(0.3, 0.8) * minigame_fish_stability_multiplier # Short dash time
					fish_target = randf_range(0.0, max_fish_pos)
					# Ensure we actually move far enough to make it a dash
					if abs(fish_target - fish_position) < 0.3:
						fish_target = 1.0 if fish_position < 0.5 else 0.0
				else:
					# IDLE
					fish_timer = randf_range(0.5, 1.5)
					# Stay roughly here
			
			var dist = abs(fish_position - fish_target)
			var speed = 0.5
			# If target is far, move SUPER fast
			if dist > 0.1: 
				speed = (3.0 + (_difficulty * 1.5)) * fish_speed_multiplier * minigame_dart_speed_multiplier
				fish_position = move_toward(fish_position, fish_target, delta * speed)
			else:
				# Drift
				fish_position = lerp(fish_position, fish_target, delta * 1.0 * fish_speed_multiplier)
				
		"Mixed", _: # Default Random
			if fish_timer <= 0 or abs(fish_position - fish_target) < 0.02:
				fish_timer = randf_range(1.5, 4.0) * minigame_fish_stability_multiplier
				if randf() > 0.6:
					fish_target = randf_range(0.0, max_fish_pos)
				else:
					fish_target = clamp(fish_position + randf_range(-0.2, 0.2), 0.0, max_fish_pos)
			
			var speed = (0.5 + (_difficulty * 0.3)) * fish_speed_multiplier
			fish_position = lerp(fish_position, fish_target, delta * speed)

	fish_position = clamp(fish_position, 0.0, max_fish_pos)

func _update_visuals():
	var fish_y = UI_HEIGHT - (fish_position * UI_HEIGHT) - FISH_SIZE
	fish_icon.position.y = fish_y
	fish_icon.position.x = (UI_WIDTH - FISH_SIZE) / 2
	
	var bar_y = UI_HEIGHT - (bar_position * UI_HEIGHT) - CATCH_BAR_HEIGHT
	catch_bar.position.y = bar_y
	catch_bar.position.x = 2
	
	progress_rect.custom_minimum_size.y = catch_progress * UI_HEIGHT
	progress_rect.position.y = UI_HEIGHT - progress_rect.custom_minimum_size.y

func _win():
	emit_signal("minigame_finished", true)
	hide_minigame()

func _lose():
	emit_signal("minigame_finished", false)
	hide_minigame()

# Stub compatibility functions
func update_tension(_a, _b): pass
func update_distance(_a): pass
func show_warning(_a): pass
func update_player_stamina(_a, _b): pass
func update_stamina(_a, _b): pass
