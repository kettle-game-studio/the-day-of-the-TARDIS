shader_type spatial;

uniform sampler2D base_texture : filter_nearest;
uniform sampler2D color_mask : filter_nearest;
uniform sampler2D Light_texture : filter_nearest;
uniform vec3 color = vec3(0.5, 0, 0);

void fragment() {
	ALBEDO = mix(
		textureLod(base_texture, UV, 0.0).xyz, color,
		textureLod(color_mask, UV, 0.0).x);
	EMISSION = textureLod(Light_texture, UV, 0.0).xyz;
}
