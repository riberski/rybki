extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const BOBBER_SCENE_PATH := "res://src/fishing/bobber3d.tscn"
const MINIGAME_SCENE_PATH := "res://src/ui/fishing_minigame_ui.tscn"

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State {
	IDLE,
	CASTING,
	FISHING, # Waiting for bite
	HOOKING, # Bite happened, waiting for player response
	REELING, # Minigame active
	CAUGHT,  # Success animation
}

var current_state = State.IDLE
var bobber_instance = null
var minigame_instance = null
var facing_direction = 1
var bite_timer = 0.0
var hook_timer = 0.0
var bobber_scene: PackedScene = null
var minigame_scene: PackedScene = null

@onready var exclamation_label = $Exclamation

func _ready() -> void:
	if ResourceLoader.exists(BOBBER_SCENE_PATH):
		bobber_scene = load(BOBBER_SCENE_PATH) as PackedScene
	if ResourceLoader.exists(MINIGAME_SCENE_PATH):
		minigame_scene = load(MINIGAME_SCENE_PATH) as PackedScene

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Only the authorized player controls the character
	if not is_multiplayer_authority():
		move_and_slide() # Apply synchronized velocity/gravity if any? Or just rely on position sync.
		# If position is synced directly, move_and_slide might fight it.
		# With MultiplayerSynchronizer on position, we often don't move_and_slide on remote peers.
		return

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and current_state == State.IDLE:
		velocity.y = JUMP_VELOCITY
	
	# Fishing controls
	# F key to cast
	if Input.is_physical_key_pressed(KEY_F): 
		if current_state == State.IDLE and is_on_floor():
			start_fishing()
	
	# Interactions
	if Input.is_action_just_pressed("ui_accept"): # Space/Enter
		if current_state == State.HOOKING:
			start_minigame()
		elif current_state == State.FISHING:
			cancel_fishing() # Pulled too early
			print("Pulled too early!")

	if Input.is_action_just_pressed("ui_cancel") and current_state != State.IDLE:
		cancel_fishing()
	
	# Validations
	if current_state == State.FISHING:
		bite_timer -= delta
		if bite_timer <= 0:
			trigger_bite()
			
	if current_state == State.HOOKING:
		hook_timer -= delta
		if hook_timer <= 0:
			print("Fish escaped (too slow/late)")
			cancel_fishing()
			trigger_bite()

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if current_state == State.IDLE:
		if direction:
			facing_direction = sign(direction)
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Limit movement while fishing
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func start_fishing():
	if current_state == State.IDLE:
		if bobber_scene == null:
			push_warning("Missing bobber scene: %s" % BOBBER_SCENE_PATH)
			return

		current_state = State.CASTING
		print("State: CASTING")
		
		bobber_instance = bobber_scene.instantiate()
		get_parent().add_child(bobber_instance)
		var spawn_pos_2d := global_position + Vector2(20 * facing_direction, -10)
		if bobber_instance is Node2D:
			bobber_instance.global_position = spawn_pos_2d
		elif bobber_instance is Node3D:
			bobber_instance.global_position = Vector3(spawn_pos_2d.x, 0.0, spawn_pos_2d.y)
		
		var impulse = Vector2(facing_direction * 300, -300)
		if bobber_instance.has_method("cast"):
			bobber_instance.cast(impulse)
		
		if bobber_instance.has_signal("bobber_landed"):
			bobber_instance.bobber_landed.connect(_on_bobber_landed)

func _on_bobber_landed():
	if current_state == State.CASTING:
		current_state = State.FISHING
		bite_timer = randf_range(2.0, 5.0) # Wait 2-5s for a bite
		print("State: FISHING - Waiting for bite...")

func trigger_bite():
	current_state = State.HOOKING
	hook_timer = 1.0 # 1s to react
	print("!!! BITE !!! PRESS SPACE !!!")
	exclamation_label.visible = true

func start_minigame():
	exclamation_label.visible = false
	print("Hooked! Starting Minigame...")
	if minigame_scene == null:
		push_warning("Missing minigame scene: %s" % MINIGAME_SCENE_PATH)
		cancel_fishing()
		return

	current_state = State.REELING
	
	minigame_instance = minigame_scene.instantiate()
	# Add to a CanvasLayer if available, or just as child for now
	add_child(minigame_instance)
	if minigame_instance.has_signal("minigame_finished"):
		minigame_instance.minigame_finished.connect(_on_minigame_finished)

func _on_minigame_finished(success):
	if success:
		print("FISH CAUGHT!")
		# Todo: Add fish to inventory
	else:
		print("Fish lost...")
	
	cleanup_fishing()

func cleanup_fishing():
	if is_instance_valid(minigame_instance):
		minigame_instance.queue_free()
	minigame_instance = null
	cancel_fishing()

func cancel_fishing():
	exclamation_label.visible = false
	if is_instance_valid(bobber_instance):
		bobber_instance.queue_free()
	bobber_instance = null
	current_state = State.IDLE
	print("State: IDLE")
