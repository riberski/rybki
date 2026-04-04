extends Area3D

enum PointType { STATIC, DYNAMIC, HIDDEN, EMERGENCY }

@export var extraction_half_size: float = 1.5
@export var point_type: int = PointType.STATIC
@export var active_time: Vector2i = Vector2i(0, 1200)
@export var capacity: int = 1

var _player_inside: Node = null
var _active: bool = true
var _remaining_uses: int = 1
var _discovered_hidden: bool = false
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	_remaining_uses = max(1, capacity)
	if point_type == PointType.HIDDEN:
		_discovered_hidden = false
		set_active(false)
	else:
		set_active(true)

func _on_body_entered(body: Node) -> void:
	if point_type == PointType.HIDDEN and not _discovered_hidden:
		_discovered_hidden = true
		set_active(true)
		if body and body.has_method("show_notification"):
			body.show_notification("Odkryto ukryty punkt ekstrakcji", 2.0)
	if body.has_method("set_interactable"):
		_player_inside = body
		body.set_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body == _player_inside and body.has_method("set_interactable"):
		body.set_interactable(null)
		_player_inside = null

func interact(player: Node) -> void:
	if TimeManager == null or not TimeManager.extraction_active:
		if player and player.has_method("show_notification"):
			player.show_notification("Ekstrakcja nie jest aktywna", 1.8)
		return
	if not _active:
		if player and player.has_method("show_notification"):
			player.show_notification("Ten punkt ekstrakcji jest nieaktywny", 1.8)
		return
	if _remaining_uses <= 0:
		if player and player.has_method("show_notification"):
			player.show_notification("Punkt ekstrakcji jest juz wyczerpany", 1.8)
		return

	_remaining_uses -= 1
	TimeManager.finish_extraction("zone_extract")

func get_interact_text() -> String:
	if TimeManager and TimeManager.extraction_active and _active:
		var type_label := "Extract"
		match point_type:
			PointType.DYNAMIC:
				type_label = "Dynamic Extract"
			PointType.HIDDEN:
				type_label = "Hidden Extract"
			PointType.EMERGENCY:
				type_label = "Emergency Extract"
			_:
				type_label = "Extract"
		if _remaining_uses <= 0:
			return "%s (depleted)" % type_label
		return "%s (%d)" % [type_label, _remaining_uses]
	return "Extraction inactive"

func setup_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(extraction_half_size * 2.0, 2.0, extraction_half_size * 2.0)
	collision.shape = shape
	add_child(collision)

func setup_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(extraction_half_size * 2.0, 0.06, extraction_half_size * 2.0)
	_mesh_instance.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.95, 0.6, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_instance.material_override = mat
	_mesh_instance.position.y = -0.45
	add_child(_mesh_instance)

func initialize_visuals() -> void:
	if get_child_count() == 0:
		setup_collision()
		setup_visual()

func configure(type_value: int, active_time_window: Vector2i, max_capacity: int) -> void:
	point_type = type_value
	active_time = active_time_window
	capacity = max(1, max_capacity)
	_remaining_uses = capacity

func set_active(is_active: bool) -> void:
	_active = is_active
	monitoring = is_active or point_type == PointType.HIDDEN
	visible = is_active or point_type == PointType.HIDDEN
	if _mesh_instance and _mesh_instance.material_override is StandardMaterial3D:
		var mat := _mesh_instance.material_override as StandardMaterial3D
		if point_type == PointType.EMERGENCY:
			mat.albedo_color = Color(1.0, 0.35, 0.25, 0.85) if is_active else Color(0.5, 0.25, 0.22, 0.35)
		elif point_type == PointType.HIDDEN:
			mat.albedo_color = Color(0.25, 0.55, 1.0, 0.8) if is_active else Color(0.08, 0.12, 0.2, 0.18)
		elif point_type == PointType.DYNAMIC:
			mat.albedo_color = Color(0.95, 0.82, 0.25, 0.8) if is_active else Color(0.35, 0.32, 0.14, 0.32)
		else:
			mat.albedo_color = Color(0.2, 0.95, 0.6, 0.8) if is_active else Color(0.2, 0.3, 0.24, 0.3)