shader_type spatial;
render_mode cull_disabled;

uniform sampler2D base_texture : filter_nearest;
uniform sampler2D light_texture : filter_nearest;
uniform vec3 color = vec3(0, 1, 0);
uniform float emission = 1.0;

void fragment() {
	ALBEDO = textureLod(base_texture, UV, 0.0).xyz;
	EMISSION = textureLod(light_texture, UV, 0.0).y * color * emission;
}
