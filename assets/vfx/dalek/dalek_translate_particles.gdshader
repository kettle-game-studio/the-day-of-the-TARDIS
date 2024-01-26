shader_type particles;
render_mode disable_force, disable_velocity;

#include "res://assets/vfx/common.gdshaderinc"

uniform vec3 color: source_color;
uniform float dalek_down_radius;
uniform float dalek_up_radius;
uniform float bottom_k = 1;
uniform vec3 bottom_offset;
uniform sampler2D base_texture : filter_nearest;
uniform sampler2D color_mask : filter_nearest;
uniform sampler2D light_texture : filter_nearest;

uniform vec3  start_point;
uniform float start_rotation;
uniform float start_height;
uniform float start_dirt;
uniform float start_neck;

uniform vec3  end_point;
uniform float end_rotation;
uniform float end_height;
uniform float end_dirt;
uniform float end_neck;


float easing(float x) {
	bool inv = (x > 0.5);
	if (inv) x = 1.0 - x;
	x = x * 2.0;
	x = x * x * x * x * x * 0.5;
	if (inv) x = 1.0 - x;
	return x;
}

void start() {
}

void process() {
	float seed = float(INDEX);
	CUSTOM.x += DELTA;

	float time_ration = CUSTOM.x / LIFETIME;
	//float time_ration = hash1(seed);
	//float time_ration = 0.0;

	float h = hash1(seed);
	h = h * h;
	float angle_h = hash1(seed);
	float base_height = mix(start_height,   end_height,   easing(time_ration));
	float neck        = mix(start_neck,     end_neck,     easing(time_ration));
	vec3  offset      = mix(start_point,    end_point,    easing(time_ration));
	float rotation    = mix(start_rotation, end_rotation, easing(time_ration));
	float dirt        = mix(start_dirt,     end_dirt,     easing(time_ration));
	float angle = angle_h * PI * 2.0;
	float height = base_height * h;
	float radius = mix(dalek_down_radius, dalek_up_radius, h);
	float sin_angle = sin(angle);
	float cos_angle = cos(angle);

	float x_angle_sin = 0.0;
	float x_angle_cos = 1.0;

	float dh = base_height - height;
	if (dh < radius) {
		dh = radius - dh;
		float old_r = radius;
		radius = sqrt(radius * radius - dh * dh);
		x_angle_sin = dh / old_r;
		x_angle_cos = radius / old_r;
	}

	vec3 point = vec3(0, height, 0) + vec3(sin_angle, 0, cos_angle) * radius;

	if (height < neck) {
		float k = (neck - height) / neck;
		point.x *= mix(1.0, bottom_k, k);
		point += bottom_offset * k;
	}

	TRANSFORM =
		translation_matrix(offset)
		* rotation_y_matrix(-rotation)
		* translation_matrix(point)
		* rotation_y_matrix_sc(-sin_angle, cos_angle)
		* rotation_x_matrix_sc(x_angle_sin, x_angle_cos);

	vec2 uv = vec2(angle_h, 1.0 - h);
	COLOR = vec4(
		clamp(mix(
			textureLod(base_texture, uv, 0.0).rgb, color,
			textureLod(color_mask, uv, 0.0).r) - (0.5 + 0.5 * hash1(seed)) * dirt,
			0, 1),
		textureLod(light_texture, uv, 0.0).r);

	if (time_ration > 1.0) COLOR.w = -1.0;
}
