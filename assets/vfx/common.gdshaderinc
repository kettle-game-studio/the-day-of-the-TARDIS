
float hash1(inout float sid) {
	float result = fract(sin(sid * 0.233) * 43758.5453);
	sid = sid + result;
	return result;
}

mat4 translation_matrix(vec3 translation) {
	mat4 result =  mat4(1);
	result[3] = vec4(translation, 1);
	return result;
}

mat4 rotation_x_matrix_sc(float sin_a, float cos_a) {
	return mat4(mat3(
		vec3(1,     0,      0),
		vec3(0, cos_a, -sin_a),
		vec3(0, sin_a,  cos_a)
	));
}

mat4 rotation_y_matrix_sc(float sin_a, float cos_a) {
	return mat4(mat3(
		vec3( cos_a, 0, sin_a),
		vec3(     0, 1,     0),
		vec3(-sin_a, 0, cos_a)
	));
}

mat4 rotation_z_matrix_sc(float sin_a, float cos_a) {
	return mat4(mat3(
		vec3( cos_a, sin_a, 0),
		vec3(-sin_a, cos_a, 0),
		vec3(0,   0,        1)
	));
}

mat4 rotation_x_matrix(float angle) {
	return rotation_x_matrix_sc(sin(angle), cos(angle));
}

mat4 rotation_y_matrix(float angle) {
	return rotation_y_matrix_sc(sin(angle), cos(angle));
}

mat4 rotation_z_matrix(float angle) {
	return rotation_z_matrix_sc(sin(angle), cos(angle));
}