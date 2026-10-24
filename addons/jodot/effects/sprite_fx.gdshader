shader_type canvas_item;
uniform vec3 light: source_color = vec3(1.0);
uniform vec3 midtone: source_color = vec3(.5);
uniform vec3 dark: source_color = vec3(.2);
uniform bool apply_palette = false;
uniform vec2 scale = vec2(1.0);
uniform float mosaic = 1;
uniform float rotation = 0.0;

vec2 rotate_uv(vec2 uv, float angle, vec2 center, vec2 ratio) {
	uv -= center;
	uv *= ratio;
	float s = sin(angle);
	float c = cos(angle);
	mat2 rot = mat2(vec2(c, -s), vec2(s, c));
	uv = rot * uv;

	uv /= ratio;
	uv += center;
	return uv;
}

vec2 round_uv(vec2 uv, vec2 tex_px_size){
	vec2 factor = tex_px_size * mosaic / (scale * 1.0);
	return vec2(
		floor(uv.x / factor.x) * factor.x,
		floor(uv.y / factor.y) * factor.y
	);
}

vec2 transform_uv(mat4 tform, vec2 uv) {
	return (tform * vec4(uv, 0.0, 1.0)).xy;
}

void vertex() {
	VERTEX *= scale;
}

void fragment() {
	vec2 rounded_uv = round_uv(UV, TEXTURE_PIXEL_SIZE);
	vec2 ratio = scale / TEXTURE_PIXEL_SIZE;
	vec2 center = (REGION_RECT.xy + (REGION_RECT.zw / 2.0));
	COLOR = texture(TEXTURE, rotate_uv(rounded_uv, rotation, center, ratio));

	if (apply_palette && COLOR.a > 0.0) {
		if (COLOR.b > 0.65)
			COLOR.rgb=light;
		else if (COLOR.b > 0.5)
			COLOR.rgb=midtone;
		else if (COLOR.b > 0.3)
			COLOR.rgb=dark;
	}
}
