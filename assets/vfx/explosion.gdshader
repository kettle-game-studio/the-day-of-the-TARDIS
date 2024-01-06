shader_type spatial;

uniform sampler2D light_texture : filter_nearest;
uniform float speed = 1.0;
uniform float alpha = 1.0;

void fragment() {
	ALBEDO = vec3(0);
	EMISSION = textureLod(light_texture, UV + vec2(0, -round(speed * TIME*32.0))/32.0, 0.0).xyz;
	ALPHA = alpha;
}
