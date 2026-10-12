shader_type canvas_item;

uniform float factor: hint_range(0,1) = 1;
uniform float wave_size = 30.0;
uniform int direction: hint_enum("down", "up", "left", "right");

float wave(float x) {
	return abs(mod(x, 2.0 * wave_size) - wave_size);
}

float wave_curtain(vec2 pos, float curtain_height) {
	float y_limit = pos.y - wave(pos.x);
	return smoothstep(y_limit, y_limit+2.0, curtain_height);
}

void fragment() {
	vec2 RESOLUTION = vec2(1.0 / SCREEN_PIXEL_SIZE.x, 1.0/ SCREEN_PIXEL_SIZE.y);
	vec2 pixel_coord = RESOLUTION * UV;

	// Adjust calculations for horizontal vs vertical wipes
	float factor_hack = 0.0;
	float res_major_axis = RESOLUTION.y;
	if (direction == 2 || direction == 3) { // left or right
		res_major_axis = RESOLUTION.x;
		factor_hack = (1.0 - (RESOLUTION.y / RESOLUTION.x)) * .47;
	}
	
	float fudge_amount = (wave_size * 4.0);
	float curtain_height = (factor - factor_hack) * (res_major_axis + fudge_amount) - fudge_amount;

	// Define rotation matrix based on direction
	mat2[] rotations = {
		mat2(vec2(1.0, 0.0), vec2(0.0, 1.0)), // 0: down (default)
		mat2(vec2(-1.0, 0.0), vec2(0.0, -1.0)), // 180 deg
		mat2(vec2(0.0, 1.0), vec2(-1.0, 0.0)), // 90 deg CW
		mat2(vec2(0.0, -1.0), vec2(1.0, 0.0)) // 90 deg CCW
	};
	

	// Rotate coordinates around the center of the screen
	vec2 center = RESOLUTION / 2.0;
	vec2 pixel_coord_rotated = rotations[direction] * (pixel_coord - center) + center;

	COLOR.a =
		0.4 * wave_curtain(pixel_coord_rotated, curtain_height) +
		0.3 * wave_curtain(pixel_coord_rotated, curtain_height + wave_size) +
		0.3 * wave_curtain(pixel_coord_rotated, curtain_height + wave_size * 2.0);
}
