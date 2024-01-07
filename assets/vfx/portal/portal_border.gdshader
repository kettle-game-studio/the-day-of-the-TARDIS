shader_type spatial;

uniform sampler2D noise_texture : filter_nearest, repeat_enable;
uniform float mult = 1.0;
uniform float speed = 5.0;

void vertex() {
	VERTEX = vec3(VERTEX.x, VERTEX.y, VERTEX.z + sin(TIME * speed + 20.0 * (VERTEX.x + VERTEX.y))*0.002);
}

void fragment() {
	ALBEDO = textureLod(noise_texture, UV + vec2(0, mult * TIME), 0.0).xyz;
	ALPHA = 0.8;
}

