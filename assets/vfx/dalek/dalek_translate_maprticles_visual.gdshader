shader_type spatial;
render_mode cull_disabled;


void vertex() {
}

void fragment() {
	if (COLOR.w < 0.5) discard;
	ALBEDO = COLOR.xyz;
}
