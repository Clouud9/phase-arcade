shader_type canvas_item;

uniform float factor: hint_range(0,1) = 1;
uniform vec2 pixel_offset = vec2(0.0, 0.0);
uniform sampler2D noise;
uniform float noise_influence = 0.1;

float length_squared(vec2 v) {
	return v.x*v.x + v.y*v.y;
}
float dist_squared(vec2 v1, vec2 v2) {
	return length_squared(v1 - v2);
}

float noise_value(vec2 uv) {
	return 1.0 + (texture(noise, uv).r - 0.5) * noise_influence;
}

// factor follows the convention shared with curtain.gdshader:
// 1.0 is fully closed, 0.0 is fully open. The radius is inverted to match,
// because a larger disc here means *less* of the screen is covered.
const float diagonal = sqrt(2); //TODO actual factor depends on screen aspect ratio
void fragment() {
	vec2 RESOLUTION = vec2(1.0 / SCREEN_PIXEL_SIZE.x, 1.0/ SCREEN_PIXEL_SIZE.y);
	float cr = max(RESOLUTION.x, RESOLUTION.y) * (1.0 - factor) / diagonal;
	vec2 c = RESOLUTION * 0.5 + pixel_offset;
	COLOR.a = sqrt(dist_squared(c, VERTEX)) - cr * noise_value(UV) + 1.0;
}
