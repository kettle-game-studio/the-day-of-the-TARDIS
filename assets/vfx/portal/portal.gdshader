shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D portal_camera : filter_nearest;
uniform sampler2D noise_texture : filter_nearest;
uniform float speed = 1.0;
uniform float size = 20.0;
uniform float close = 1.0;
uniform vec3 color;


void vertex() {
	VERTEX = vec3(VERTEX.x, VERTEX.y, VERTEX.z + sin(TIME * speed + 20.0 * (VERTEX.x + VERTEX.y))*0.002);
}

vec2 get_rad_coord(vec2 uv) {
	uv -= 0.5;
	float rad_x = length(uv);
	float rad_y = atan(uv.y / uv.x) / 3.14;
	if (uv.x < 0.0) {
		rad_y += 1.0;
	}
	return vec2(rad_x, rad_y);
}

void fragment() {
	float add = sin(TIME * speed + size * UV.x) + sin(TIME * speed + size * UV.y);

	vec2 rad_uv = get_rad_coord(round(UV * 32.0)/32.0);
	vec2 animation_uv = rad_uv * vec2(2.5, 0.5) + vec2(0.0, TIME);

	float k = rad_uv.x * 1.2;
	k = k * k * k * k * k;
	ALBEDO = mix(
		textureLod(noise_texture, animation_uv, 0.0).xyz,
		textureLod(portal_camera, SCREEN_UV + add * 0.001, 0.0).xyz,
		max(0.0, 1.0 * close - k)
	);
}
