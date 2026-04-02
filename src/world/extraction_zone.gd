extends Area3D

@export var extraction_half_size: float = 1.5

var _player_inside: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true

func _on_body_entered(body: Node) -> void:
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

	TimeManager.finish_extraction("zone_extract")

func get_interact_text() -> String:
	if TimeManager and TimeManager.extraction_active:
		return "Extract"
	return "Extraction inactive"

func setup_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(extraction_half_size * 2.0, 2.0, extraction_half_size * 2.0)
	collision.shape = shape
	add_child(collision)

func setup_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(extraction_half_size * 2.0, 0.06, extraction_half_size * 2.0)
	mesh_instance.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.95, 0.6, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	mesh_instance.position.y = -0.45
	add_child(mesh_instance)

func initialize_visuals() -> void:
	if get_child_count() == 0:
		setup_collision()
		setup_visual()