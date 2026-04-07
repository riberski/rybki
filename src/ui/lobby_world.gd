extends Node3D

@onready var popup: Control = $UI/Popup
@onready var popup_label: Label = $UI/Popup/Panel/Label
@onready var popup_hint: Label = $UI/Popup/Panel/Hint
@onready var draft_ui: Control = $UI/DraftUI
@onready var loadout_panel: Control = $UI/LoadoutPanel
@onready var contract_offer_ui: Control = $UI/ContractOfferUI
@onready var board_ui: Control = $BoardViewport/BoardUI
@onready var board_ui_overlay: Control = $UI/BoardUIOverlay
@onready var board_area: Area3D = get_node_or_null("Tablica/BoardArea")
@onready var board_camera: Camera3D = $BoardCamera
@onready var board_camera_target: Node3D = $BoardCameraTarget
@onready var board_mesh: Node3D = get_node_or_null("Tablica")
@onready var board_viewport: SubViewport = $BoardViewport
@onready var board_screen: MeshInstance3D = get_node_or_null("Tablica/BoardUIScreen")
@onready var board_screen_collider: CollisionObject3D = get_node_or_null("Tablica/BoardUIScreen/ScreenCollider")
@onready var player_camera: Camera3D = $LobbyPlayer/CameraPivot/SpringArm3D/Camera3D
@onready var lobby_player: Node3D = $LobbyPlayer
@onready var dir_light: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
@onready var key_light: SpotLight3D = get_node_or_null("LobbyLights/KeyLight")
@onready var fill_light: OmniLight3D = get_node_or_null("LobbyLights/FillLight")
@onready var rim_light: SpotLight3D = get_node_or_null("LobbyLights/RimLight")
@onready var board_light: SpotLight3D = get_node_or_null("BoardLight")

var board_open := false
var player_in_board_area := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _board_light_base_energy: float = 3.0

func _ready() -> void:
	_apply_visual_polish()
	popup.visible = false
	if board_camera and board_camera_target:
		board_camera.look_at(board_camera_target.global_transform.origin, Vector3.UP)
	if board_viewport and board_screen:
		var mat := board_screen.material_override
		if mat == null:
			mat = StandardMaterial3D.new()
			board_screen.material_override = mat
		mat.albedo_texture = board_viewport.get_texture()
	if draft_ui:
		draft_ui.hide()
	if loadout_panel:
		loadout_panel.hide()
	# Leave camera selection to the editor setup.
	if board_ui:
		board_ui.show()
	if board_ui_overlay:
		board_ui_overlay.hide()
		if board_ui_overlay.has_signal("action_selected"):
			board_ui_overlay.action_selected.connect(_on_board_action_selected)
		if board_ui_overlay.has_signal("close_requested"):
			board_ui_overlay.close_requested.connect(_on_board_close_requested)
	if board_area:
		board_area.monitoring = true
		board_area.monitorable = true
		board_area.collision_layer = 1
		board_area.collision_mask = 1
		board_area.body_entered.connect(_on_board_area_entered)
		board_area.body_exited.connect(_on_board_area_exited)
	_set_board_mode(false)

func _process(_delta: float) -> void:
	if board_camera and board_camera_target:
		board_camera.look_at(board_camera_target.global_transform.origin, Vector3.UP)
	if board_open:
		return
	if board_light:
		# Subtle screen glow pulse makes the board feel more alive.
		board_light.light_energy = _board_light_base_energy + sin(Time.get_ticks_msec() * 0.0025) * 0.35
	var can_use := _can_use_board()
	if popup:
		popup.visible = can_use
		if can_use:
			popup_label.text = "Tablica"
			popup_hint.text = "E: otworz tablice"
	if Input.is_action_just_pressed("interact") and can_use:
		_open_board()

func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if board_open:
		if event.is_action_pressed("ui_cancel") or _is_interact_event(event):
			_close_board()
			return
		return
	if _is_interact_event(event) and _can_use_board():
		_open_board()

func _is_interact_event(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		return true
	return false

func _push_board_input(event: InputEvent) -> void:
	if board_viewport == null or board_camera == null or board_screen == null:
		return
	if not board_viewport.is_inside_tree():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		var hit_pos: Vector3
		var has_hit := false
		if board_screen_collider:
			var origin := board_camera.project_ray_origin(event.position)
			var dir := board_camera.project_ray_normal(event.position)
			var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 200.0)
			params.collide_with_areas = true
			params.collide_with_bodies = true
			params.collision_mask = 1
			var result := get_world_3d().direct_space_state.intersect_ray(params)
			if result and result.get("collider") == board_screen_collider:
				hit_pos = result["position"]
				has_hit = true
		var quad := board_screen.mesh as QuadMesh
		if quad == null:
			return
		var view_size := get_viewport().get_visible_rect().size
		if view_size.x <= 0.0 or view_size.y <= 0.0:
			return
		if not has_hit:
			var origin_fallback := board_camera.project_ray_origin(event.position)
			var dir_fallback := board_camera.project_ray_normal(event.position)
			var normal := board_screen.global_transform.basis.z.normalized()
			var plane := Plane(normal, board_screen.global_transform.origin)
			var denom := plane.normal.dot(dir_fallback)
			if abs(denom) < 0.00001:
				return
			var t := -(plane.normal.dot(origin_fallback) + plane.d) / denom
			if t < 0.0:
				plane = Plane(-normal, board_screen.global_transform.origin)
				denom = plane.normal.dot(dir_fallback)
				if abs(denom) < 0.00001:
					return
				t = -(plane.normal.dot(origin_fallback) + plane.d) / denom
				if t < 0.0:
					return
			hit_pos = origin_fallback + dir_fallback * t
		var local := board_screen.global_transform.affine_inverse() * hit_pos
		var half := quad.size * 0.5
		if abs(local.x) > half.x or abs(local.y) > half.y:
			return
		var u := (local.x / quad.size.x) + 0.5
		var v := 0.5 - (local.y / quad.size.y)
		var mat := board_screen.material_override
		if mat is StandardMaterial3D and mat.uv1_scale.x < 0.0:
			u = 1.0 - u
		var viewport_pos := Vector2(u * board_viewport.size.x, v * board_viewport.size.y)
		var remapped := event.duplicate()
		remapped.position = viewport_pos
		remapped.global_position = viewport_pos
		if remapped is InputEventMouseMotion:
			var scale := Vector2(board_viewport.size.x / view_size.x, board_viewport.size.y / view_size.y)
			remapped.relative = remapped.relative * scale
		if board_viewport.is_inside_tree():
			board_viewport.push_input(remapped)
		return
	if board_viewport.is_inside_tree():
		board_viewport.push_input(event)

func _on_board_area_entered(body: Node) -> void:
	if body != lobby_player and not body.is_in_group("lobby_player"):
		return
	player_in_board_area = true
	popup_label.text = "Tablica"
	popup_hint.text = "E: otworz tablice"
	popup.visible = true

func _on_board_area_exited(body: Node) -> void:
	if body != lobby_player and not body.is_in_group("lobby_player"):
		return
	player_in_board_area = false
	if not board_open:
		popup.visible = false

func _can_use_board() -> bool:
	if lobby_player == null:
		return false
	if player_in_board_area:
		return true

	if board_area:
		var shape_node := board_area.get_node_or_null("CollisionShape3D")
		if shape_node:
			var shape = shape_node.shape
			if shape is BoxShape3D:
				var local_pos = board_area.to_local(lobby_player.global_transform.origin)
				var half = shape.size * 0.5
				var margin = 0.9
				if abs(local_pos.x) <= half.x + margin and abs(local_pos.z) <= half.z + margin:
					return true

	if board_mesh:
		var horizontal_player := lobby_player.global_transform.origin
		horizontal_player.y = 0.0
		var horizontal_board := board_mesh.global_transform.origin
		horizontal_board.y = 0.0
		return horizontal_player.distance_to(horizontal_board) <= 8.0

	return false

func _open_board() -> void:
	popup.visible = false
	_previous_mouse_mode = Input.get_mouse_mode()
	_set_board_mode(true)
	if board_ui_overlay:
		board_ui_overlay.show()
		if board_ui_overlay.has_method("_refresh_all"):
			board_ui_overlay.call("_refresh_all")

func _close_board() -> void:
	_set_board_mode(false)
	if board_ui_overlay:
		board_ui_overlay.hide()
	# Always return to mouselook after board is closed.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _set_board_mode(active: bool) -> void:
	board_open = active
	if board_camera:
		board_camera.current = active
	if player_camera:
		player_camera.current = not active
	if lobby_player:
		lobby_player.set_physics_process(not active)
		lobby_player.set_process_input(not active)
		lobby_player.set_process_unhandled_input(not active)
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _apply_visual_polish() -> void:
	_setup_environment()
	_setup_ground_visual()
	_setup_lighting_visuals()
	_style_popup()

func _setup_environment() -> void:
	var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if world_env == null:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)

	var env: Environment = world_env.environment
	if env == null:
		env = Environment.new()
		world_env.environment = env

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.18, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.78, 0.86)
	env.ambient_light_energy = 1.25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.30
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.16
	env.fog_enabled = false

func _setup_ground_visual() -> void:
	var ground_mesh: MeshInstance3D = get_node_or_null("LobbyGroundVisual")
	if ground_mesh == null:
		ground_mesh = MeshInstance3D.new()
		ground_mesh.name = "LobbyGroundVisual"
		var plane := PlaneMesh.new()
		plane.size = Vector2(70.0, 70.0)
		plane.subdivide_depth = 10
		plane.subdivide_width = 10
		ground_mesh.mesh = plane
		ground_mesh.position = Vector3(0.0, -0.48, 0.0)
		add_child(ground_mesh)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.22, 0.27)
	mat.roughness = 0.90
	mat.metallic = 0.02
	mat.emission_enabled = true
	mat.emission = Color(0.14, 0.18, 0.22)
	mat.emission_energy_multiplier = 0.35
	ground_mesh.material_override = mat

func _setup_lighting_visuals() -> void:
	if dir_light:
		dir_light.light_color = Color(0.90, 0.95, 1.0)
		dir_light.light_energy = 1.45
		dir_light.shadow_enabled = true

	if key_light:
		key_light.light_energy = 6.4
		key_light.light_color = Color(1.0, 0.90, 0.78)
		key_light.shadow_enabled = true

	if fill_light:
		fill_light.light_energy = 2.1
		fill_light.light_color = Color(0.66, 0.78, 1.0)

	if rim_light:
		rim_light.light_energy = 4.0
		rim_light.light_color = Color(0.86, 0.96, 1.0)

	if board_light:
		board_light.light_color = Color(0.77, 0.90, 1.0)
		board_light.light_energy = 5.0
		_board_light_base_energy = board_light.light_energy

	_ensure_extra_lights()

func _ensure_extra_lights() -> void:
	# Accent lights deepen contrast and make lobby feel less flat.
	var warm_left := _ensure_spot_light(
		"AccentWarmLeft",
		Vector3(-8.0, 3.6, 2.3),
		Vector3(-4.0, 1.2, -1.2),
		Color(1.0, 0.82, 0.63),
		3.0,
		13.0,
		47.0
	)
	if warm_left:
		warm_left.shadow_enabled = false

	var cool_right := _ensure_spot_light(
		"AccentCoolRight",
		Vector3(4.8, 3.4, 5.6),
		Vector3(-0.8, 1.5, 0.0),
		Color(0.67, 0.84, 1.0),
		2.7,
		12.5,
		44.0
	)
	if cool_right:
		cool_right.shadow_enabled = false

	var board_glow := _ensure_omni_light(
		"AccentBoardGlow",
		Vector3(-6.2, 2.0, -14.1),
		Color(0.52, 0.76, 1.0),
		1.5,
		6.5
	)
	if board_glow:
		board_glow.shadow_enabled = false

	var player_fill := _ensure_omni_light(
		"AccentPlayerFill",
		Vector3(-4.4, 2.1, 3.6),
		Color(1.0, 0.93, 0.83),
		1.25,
		5.0
	)
	if player_fill:
		player_fill.shadow_enabled = false

func _ensure_spot_light(
	name_id: String,
	position_value: Vector3,
	target: Vector3,
	color_value: Color,
	energy: float,
	range_value: float,
	angle_value: float
) -> SpotLight3D:
	var light: SpotLight3D = get_node_or_null(name_id)
	if light == null:
		light = SpotLight3D.new()
		light.name = name_id
		add_child(light)
	light.position = position_value
	light.look_at(target, Vector3.UP)
	light.light_color = color_value
	light.light_energy = energy
	light.spot_range = range_value
	light.spot_angle = angle_value
	light.spot_attenuation = 1.15
	return light

func _ensure_omni_light(
	name_id: String,
	position_value: Vector3,
	color_value: Color,
	energy: float,
	range_value: float
) -> OmniLight3D:
	var light: OmniLight3D = get_node_or_null(name_id)
	if light == null:
		light = OmniLight3D.new()
		light.name = name_id
		add_child(light)
	light.position = position_value
	light.light_color = color_value
	light.light_energy = energy
	light.omni_range = range_value
	return light

func _style_popup() -> void:
	if popup == null:
		return
	var popup_panel: Panel = popup.get_node_or_null("Panel")
	if popup_panel:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.13, 0.18, 0.90)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.35, 0.58, 0.80, 0.95)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		popup_panel.add_theme_stylebox_override("panel", style)

	if popup_label:
		popup_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
		popup_label.add_theme_font_size_override("font_size", 21)
	if popup_hint:
		popup_hint.add_theme_color_override("font_color", Color(0.62, 0.82, 1.0))
		popup_hint.add_theme_font_size_override("font_size", 16)

func _execute_option(option_id: String) -> void:
	match option_id:
		"start_run":
			_close_board()
			if TimeManager:
				TimeManager.set_extraction_duration_minutes(TimeManager.EXTRACTION_MAX_MINUTES)
				TimeManager.start_extraction()
			get_tree().change_scene_to_file("res://src/Main3D.tscn")
		"sell_all":
			pass
		"claim_fish":
			pass
		"buy_crate":
			pass
		"loadout":
			pass
		"contract":
			pass
		"return_menu":
			_close_board()
			if InventoryManager:
				InventoryManager.save_game()
			get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
		"plan_expedition":
			pass
		"manage_boats":
			pass

func _on_board_action_selected(action_id: String) -> void:
	_execute_option(action_id)

func _on_board_close_requested() -> void:
	_close_board()
