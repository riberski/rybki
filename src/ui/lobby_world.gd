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

var board_open := false
var player_in_board_area := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	popup.visible = false
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

func _process(_delta: float) -> void:
	if board_open:
		return
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
	board_open = true
	popup.visible = false
	_previous_mouse_mode = Input.get_mouse_mode()
	if board_camera:
		board_camera.current = true
	if player_camera:
		player_camera.current = false
	if lobby_player:
		lobby_player.set_physics_process(false)
		lobby_player.set_process_input(false)
		lobby_player.set_process_unhandled_input(false)
	if board_ui_overlay:
		board_ui_overlay.show()
		if board_ui_overlay.has_method("_refresh_all"):
			board_ui_overlay.call("_refresh_all")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_board() -> void:
	board_open = false
	if board_camera:
		board_camera.current = false
	if player_camera:
		player_camera.current = true
	if lobby_player:
		lobby_player.set_physics_process(true)
		lobby_player.set_process_input(true)
		lobby_player.set_process_unhandled_input(true)
	if board_ui_overlay:
		board_ui_overlay.hide()
	Input.set_mouse_mode(_previous_mouse_mode)

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
