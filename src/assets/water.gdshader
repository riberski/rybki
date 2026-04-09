shader_type spatial;
render_mode specular_schlick_ggx; // Smooth specular for reflective water

uniform sampler2D albedo_texture : source_color;
uniform vec4 color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.12;
uniform float gloss_roughness : hint_range(0.0, 1.0) = 0.03;
uniform float reflect_strength : hint_range(0.0, 1.0) = 0.9;
uniform float fresnel_power : hint_range(1.0, 8.0) = 5.0;

// Wave settings (Falowanie)
uniform float wave_speed = 1.0;
uniform float wave_height = 0.5; // Wyższe fale dla lepszego efektu
uniform float wave_frequency = 0.5; // Częstsze fale

// Sync Time
uniform float wave_time = 0.0;

// Boat Interaction
uniform vec3 boat_position;
uniform float boat_radius = 1.5;

// Boat Mask Tuning (Editable in Inspector)
uniform vec2 mask_offset = vec2(0.0, 1.1); // Przesunięcie maski (X, Y) - moved to positive Z (Back/Stern adjustment)
uniform vec2 mask_size = vec2(0.9, 1.8);   // Rozmiar maski (Szerokość, Długość)

// Boat Rotation (Yaw)
uniform float boat_rotation_y = 0.0;

varying vec3 v_vertex; // Potrzebne do obliczenia płaskich normalnych
varying vec3 v_world_pos; // World position for boat mask

float get_wave(vec2 pos, float time, float freq_mult, float speed_mult, float direction) {
	float x = pos.x * cos(direction) - pos.y * sin(direction);
	// No Y usage, plane wave
	// We use x component of rotated vector to create directional waves
	// Use synced wave_time instead of TIME if provided, or fallback (additive)
	// For full sync, we should rely on passed time.
	float t = time; 
	return sin(x * wave_frequency * freq_mult + t * wave_speed * speed_mult);
}

float get_height(vec2 pos, float time) {
	float h = 0.0;
	// Sum of 3 waves with different directions, frequencies and speeds for "random" look
	h += get_wave(pos, time, 1.0, 1.0, 0.0);           // Main wave
	h += get_wave(pos, time, 0.61, 1.13, 1.2) * 0.6;   // Secondary crossing wave
	h += get_wave(pos, time, 1.73, 0.82, 2.5) * 0.3;   // Small detailed wave
	return h * wave_height;
}

void vertex() {
	// Calculate World Position for Fragment shader
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Displacement - Use wave_time for sync
	float h = get_height(VERTEX.xz, wave_time);
	VERTEX.y += h;
	
	// Przekazujemy pozycję wierzchołka (View Space) do fragment shadera
	v_vertex = VERTEX;
}

void fragment() {
	// --- LOW POLY FLAT SHADING MAGIC ---
	// Obliczamy wektory styczne na podstawie zmiany pozycji piksela
	vec3 dX = dFdx(v_vertex);
	vec3 dY = dFdy(v_vertex);
	// Iloczyn wektorowy daje nam wektor prostopadły do powierzchni trójkąta (normalną)
	NORMAL = normalize(cross(dX, dY));
	// -----------------------------------

	// Scrolling UVs for flow effect - Scaled for larger plane (10x size)
	vec2 uv_scroll = (UV * 10.0) + vec2(wave_time * 0.02, wave_time * 0.01);
	
	vec4 tex_color = texture(albedo_texture, uv_scroll);
	
	ALBEDO = color.rgb * tex_color.rgb; 
	
	// Boat Masking (Hole in water)
	// We use the world position distance from boat center to create a hole
	// Rotated elliptical mask for boat shape (longer in Z, narrower in X)
	// Relative position
	vec2 rel_pos = v_world_pos.xz - boat_position.xz;
	
	// Rotate relative position by NEGATIVE boat rotation to align with axis-aligned ellipse logic
	// Standard 2D rotation: x' = x cos - y sin, y' = x sin + y cos
	// We need inverse rotation (rotate the "world" back to local boat space)
	
	// FIX ROTATION: If boat rotates RIGHT (Negative Y in Godot?), mask should rotate RIGHT. 
	// If mask rotates opposite way, try POSITIVE boat_rotation_y.
	float rot = boat_rotation_y; 
	
	float s = sin(rot);
	float c = cos(rot);
	vec2 local_pos = vec2(rel_pos.x * c - rel_pos.y * s, rel_pos.x * s + rel_pos.y * c);
	
	// Ellipse equation: (x/a)^2 + (y/b)^2 <= 1
	// Boat is narrow (width ~1.5) and long (length ~4.0)
	// a (width radius) = 0.8, b (length radius) = 2.0
	// We normalize distance so 1.0 is the edge
	// Use Inspector parameters: mask_offset and mask_size
	
	float dist_ellipse = length((local_pos - mask_offset) / mask_size);
	
	// Keep this calculation for potential future boat interaction tuning,
	// but render water as fully opaque.
	float _mask = smoothstep(0, 0, dist_ellipse);

	// Fresnel-based reflections: stronger and sharper at grazing angles
	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - max(dot(NORMAL, view_dir), 0.0), fresnel_power);
	SPECULAR = mix(0.2, reflect_strength, fresnel);
	ROUGHNESS = mix(roughness, gloss_roughness, fresnel);
	METALLIC = 0.0;
}
