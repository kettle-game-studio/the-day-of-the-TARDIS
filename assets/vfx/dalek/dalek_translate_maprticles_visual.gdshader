shader_type spatial;
render_mode cull_disabled;

uniform vec3 emission: source_color; 

void vertex() {
}

void fragment() {
	if (COLOR.w < -0.5) discard;
	ALBEDO = COLOR.xyz;
	EMISSION = emission * COLOR.w;
}
