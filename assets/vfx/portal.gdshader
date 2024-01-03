shader_type spatial;
render_mode unshaded;

uniform sampler2D portal_camera : filter_nearest;

void fragment() {
	ALBEDO = textureLod(portal_camera, SCREEN_UV, 0.0).xyz;
}
