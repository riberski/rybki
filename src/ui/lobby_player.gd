extends CharacterBody3D

@export var speed := 4.0
@export var acceleration := 12.0
@export var friction := 8.0
@export var gravity_multiplier := 1.0
@export var look_sensitivity := 0.01
@export var min_pitch_deg := -45.0
@export var max_pitch_deg := 45.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var animated_model: Node = get_node_or_null("AnimatedModel")
var animation_player: AnimationPlayer = null
var walk_animation := ""
var idle_animation := ""
var gravity: float = 9.8

func _ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity")) * gravity_multiplier
	collision_layer = 1
	collision_mask = 1
	add_to_group("lobby_player")
	_ensure_lobby_camera_setup()
	_disable_mesh_self_collision()
	_setup_locomotion_animations()
	set_physics_process(true)
	set_process_unhandled_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ensure_lobby_camera_setup() -> void:
	if camera_3d:
		camera_3d.current = true
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())

func _disable_mesh_self_collision() -> void:
	var mesh_static := get_node_or_null("MeshInstance3D/StaticBody3D") as StaticBody3D
	if mesh_static == null:
		return

	mesh_static.collision_layer = 0
	mesh_static.collision_mask = 0
	var mesh_shape := mesh_static.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_shape:
		mesh_shape.disabled = true
	if spring_arm:
		spring_arm.add_excluded_object(mesh_static.get_rid())

func _setup_locomotion_animations() -> void:
	if animated_model == null:
		return

	animation_player = animated_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null:
		return

	var anim_list := animation_player.get_animation_list()
	for anim_name in anim_list:
		var anim_name_l := String(anim_name).to_lower()
		if walk_animation == "" and (anim_name_l.contains("walk") or anim_name_l.contains("run") or anim_name_l.contains("move")):
			walk_animation = anim_name
		if idle_animation == "" and anim_name_l.contains("idle"):
			idle_animation = anim_name

	if walk_animation == "" and anim_list.size() > 0:
		walk_animation = anim_list[0]
	if idle_animation == "":
		idle_animation = walk_animation
	_ensure_animation_loop(walk_animation)
	_ensure_animation_loop(idle_animation)
	if idle_animation != "":
		animation_player.play(idle_animation)

func _ensure_animation_loop(animation_name: String) -> void:
	if animation_player == null or animation_name == "":
		return
	var anim := animation_player.get_animation(animation_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR

func _update_locomotion_animations(input_dir: Vector3) -> void:
	if animation_player == null:
		return

	var moving := input_dir.length() > 0.01
	var target_anim := idle_animation
	if moving and walk_animation != "":
		target_anim = walk_animation
	if target_anim != "" and animation_player.current_animation != target_anim:
		animation_player.play(target_anim)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * look_sensitivity
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x - event.relative.y * look_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)

func _physics_process(delta: float) -> void:
	var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_vec == Vector2.ZERO:
		input_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vec == Vector2.ZERO:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_vec.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_vec.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vec.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vec.y += 1.0
		input_vec = input_vec.normalized()
	var input_dir := Vector3(input_vec.x, 0.0, input_vec.y)
	input_dir = (Basis(Vector3.UP, rotation.y) * input_dir).normalized()

	if input_dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, input_dir.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, input_dir.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	_update_locomotion_animations(input_dir)

	move_and_slide()
