shader_type spatial;

uniform sampler2D base_texture : filter_nearest;
uniform sampler2D color_mask : filter_nearest;
uniform sampler2D Light_texture : filter_nearest;
uniform vec3 color = vec3(0.5, 0, 0);
uniform float disappearance = 1.0;
uniform float dirt = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float rand = hash(round(UV*64.0));
	if (rand > disappearance) {
		discard;
	}

	ALBEDO = max(vec3(0), mix(
		textureLod(base_texture, UV, 0.0).xyz, color,
		textureLod(color_mask, UV, 0.0).x) - (0.5 + 0.5 * rand) * dirt);
	EMISSION = textureLod(Light_texture, UV, 0.0).xyz;
}
