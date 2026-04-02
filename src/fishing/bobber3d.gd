extends RigidBody3D

signal bobber_landed

var in_water = false
var water_node = null

func _ready():
	# Find Water node in the scene tree
	water_node = get_tree().root.find_child("Water", true, false)

func cast(impulse: Vector3):
	linear_velocity = impulse

func _physics_process(delta):
	var water_height = 0.0
	if water_node and water_node.has_method("get_height_at_position"):
		water_height = water_node.get_height_at_position(global_position)
		
	if global_position.y < water_height:
		if not in_water:
			in_water = true
			# Water drag
			linear_damp = 5.0
			angular_damp = 5.0
			# Reduce vertical velocity on impact to reduce bouncing
			linear_velocity.y *= 0.2
			emit_signal("bobber_landed")
		
		# Simple Buoyancy
		var depth = water_height - global_position.y
		# Gravity compensation (approx 9.8 * mass) + float force
		# Adjust 20.0 multiplier for stiffness
		apply_central_force(Vector3.UP * (10.0 + depth * 40.0))
	else:
		if in_water:
			in_water = false
			linear_damp = 0.5 # Air drag
			angular_damp = 0.5

func bob_down():
	apply_central_impulse(Vector3.DOWN * 5.0)
