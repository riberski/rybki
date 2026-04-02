shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
