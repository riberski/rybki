extends MeshInstance3D

# Configure wave parameters to match the shader
# These must match the values in your shader material!
@export var wave_speed := 1.0
@export var wave_height := 0.5
@export var wave_frequency := 0.5

var time := 0.0

func _process(delta):
	time += delta
	var mat = get_surface_override_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("wave_time", time)

func _ready():
	# Update shader parameters just in case they differ
	var mat = get_surface_override_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("wave_speed", wave_speed)
		mat.set_shader_parameter("wave_height", wave_height)
		mat.set_shader_parameter("wave_frequency", wave_frequency)

func update_boat_position(pos: Vector3):
	var mat = get_surface_override_material(0)
	if mat is ShaderMaterial:
		# Only update X and Z for the hole, Y doesn't matter for planarity usually
		# but shader expects vec3
		mat.set_shader_parameter("boat_position", pos)
		# Optional: Adjust radius dynamically based on boat speed or width?
		# mat.set_shader_parameter("boat_radius", 1.5)

func update_boat_rotation(rot_y: float):
	var mat = get_surface_override_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("boat_rotation_y", rot_y)

func get_height_at_position(world_pos: Vector3) -> float:
	# Convert world position to local position relative to the water plane
	# Since the plane is centered at (0,0) in XZ, world XZ = local XZ (assuming node scale 1,1)
	var local_pos = to_local(world_pos)
	
	# Use the SAME synced time variable as the shader!
	# The shader uses 'time' variable incremented in _process
	
	var x = local_pos.x
	var z = local_pos.z
	
	var h = 0.0
	# Match shader random waves (Sum of sines)
	# Wave 1: Dir 0.0, Freq 1.0, Speed 1.0, Strength 1.0
	h += get_wave_component(x, z, time, 1.0, 1.0, 0.0)
	
	# Wave 2: Dir 1.2, Freq 0.61, Speed 1.13, Strength 0.6
	h += get_wave_component(x, z, time, 0.61, 1.13, 1.2) * 0.6
	
	# Wave 3: Dir 2.5, Freq 1.73, Speed 0.82, Strength 0.3
	h += get_wave_component(x, z, time, 1.73, 0.82, 2.5) * 0.3
	
	return global_position.y + (h * wave_height)

func get_wave_component(x: float, z: float, time: float, freq_mult: float, speed_mult: float, direction: float) -> float:
	# Rotated X coordinate (Plane wave direction)
	var rx = x * cos(direction) - z * sin(direction)
	return sin(rx * wave_frequency * freq_mult + time * wave_speed * speed_mult)

func get_normal_at_position(world_pos: Vector3, sample_dist: float = 0.5) -> Vector3:
	# Estimate normal by finite differences
	var left = world_pos + Vector3(-sample_dist, 0, 0)
	var right = world_pos + Vector3(sample_dist, 0, 0)
	var up = world_pos + Vector3(0, 0, -sample_dist) # "Up" in 2D grid = -Z in 3D
	var down = world_pos + Vector3(0, 0, sample_dist) # "Down" in 2D grid = +Z in 3D
	
	var h_left = get_height_at_position(left)
	var h_right = get_height_at_position(right)
	var h_up = get_height_at_position(up)
	var h_down = get_height_at_position(down)
	
	# Normal vector components
	# nx = -(dz/dx) = -(h_right - h_left) / (2 * dist)
	# ny = 1
	# nz = -(dz/dy) = -(h_down - h_up) / (2 * dist)
	
	var nx = (h_left - h_right) / (2.0 * sample_dist)
	var nz = (h_up - h_down) / (2.0 * sample_dist)
	var ny = 1.0 # Base Y component
	
	return Vector3(nx, ny, nz).normalized()

