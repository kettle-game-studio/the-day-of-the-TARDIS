shader_type spatial;

void vertex() {
	POINT_SIZE = 32.0;
}

void fragment() {
	ALBEDO = vec3(1.0, sin(TIME), cos(TIME));
	ALPHA = 1.;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
