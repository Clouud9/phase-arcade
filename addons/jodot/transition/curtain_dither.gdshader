shader_type canvas_item;

// A directional wipe like curtain.gdshader, but the leading edge fades through
// a 5x5 ordered dither instead of the smooth triangular wave. The edge steps
// between a fixed set of dither patterns as the curtain opens and closes.
//
// By default everything is measured in the ColorRect's own texel space rather
// than screen space, so the pattern scales with camera zoom instead of the
// window. Set `use_frag_coords` to measure in viewport pixels instead, which is
// how the other shaders in addons/jodot/transition work and what a full-screen
// curtain wants.
//
// factor follows the convention shared with curtain.gdshader:
// 1.0 is fully closed (opaque), 0.0 is fully open (transparent).
uniform float factor: hint_range(0, 1) = 1.0;
// Size of the ColorRect in texels. Only used when `use_frag_coords` is off, and
// must then match the ColorRect's actual size for the wipe to span it; defaults
// to the 256x240 play area.
uniform vec2 rect_size = vec2(256.0, 240.0);
// Ignore `rect_size` and measure the wipe (and dither) in viewport pixels
// instead. A hand-maintained `rect_size` silently goes wrong whenever the
// ColorRect is resized -- a full-screen curtain left at the 256x240 default
// only wipes a small patch -- so prefer this for anything not sized to the play
// area or not following camera zoom.
uniform bool use_frag_coords = false;
// Height of the dithered (semi-transparent) leading edge, in texels. Larger
// values spread the dither further across the curtain instead of keeping it a
// thin fringe.
uniform float edge_size = 30.0;
uniform int direction: hint_enum("down", "up", "left", "right");
// How many dither patterns the edge fades between (0%, 1/(n-1), ... 100%).
uniform int patterns: hint_range(2, 25) = 7;
// Texels per dither cell; > 1 gives a chunkier, more visible pattern.
uniform float dither_scale = 1.0;

// 5x5 dispersed-dot ordered dither, values 0..24. A cell's value is the order
// in which it lights up, so lit cells stay as far apart as possible. Indexed by
// (y * 5 + x) and tiled over the curtain.
const int DITHER[25] = {
	2, 5, 3, 5, 1,
	5, 4, 6, 4, 5,
	3, 6, 0, 6, 3,
	5, 4, 6, 4, 5,
	1, 5, 3, 5, 2
};

// VERTEX is in local pixel (texel) space, so this is the fragment's position
// relative to the ColorRect, independent of zoom or window resolution. Only
// read when `use_frag_coords` is off; otherwise FRAGCOORD is used directly.
varying vec2 texel_pos;

float dither_threshold(vec2 coord) {
	ivec2 cell = ivec2(mod(floor(coord / dither_scale), 5.0));
	return (float(DITHER[cell.y * 5 + cell.x]) + 0.5) / 7.0;
}

void vertex() {
	texel_pos = VERTEX;
}

void fragment() {
	// Pick the coordinate space: the ColorRect's own texels, or viewport
	// pixels. `size` is always the extent of that space, standing in for
	// `rect_size` in the latter case.
	vec2 size = use_frag_coords ? 1.0 / SCREEN_PIXEL_SIZE : rect_size;
	vec2 pos = use_frag_coords ? FRAGCOORD.xy : texel_pos;

	// The rotated coordinate sweeps `axis_half` either side of the wipe's
	// center: the full height for vertical wipes, the full width for horizontal
	// ones. The rotation is about `size * 0.5` and `.y` is read *after* it, so
	// that component ends up centred on `center.y = size.y * 0.5` for every
	// direction -- vertical included. Hence `axis_center` is always
	// `size.y * 0.5`. The semi-transparent section is `fringe` long, so the
	// sweep overshoots by that much at both ends and only the opaque section is
	// ever visible once fully closed (or nothing, when fully open).
	bool horizontal = (direction == 2 || direction == 3); // left or right
	float axis_half = (horizontal ? size.x : size.y) * 0.5;
	float axis_center = size.y * 0.5;
	float fringe = edge_size * 2.0;
	float curtain_height = mix(axis_center - axis_half - fringe, axis_center + axis_half + fringe, factor);

	// Define rotation matrix based on direction
	mat2[] rotations = {
		mat2(vec2(1.0, 0.0), vec2(0.0, 1.0)), // 0: down (default)
		mat2(vec2(-1.0, 0.0), vec2(0.0, -1.0)), // 180 deg
		mat2(vec2(0.0, 1.0), vec2(-1.0, 0.0)), // 90 deg CW
		mat2(vec2(0.0, -1.0), vec2(1.0, 0.0)) // 90 deg CCW
	};

	// Rotate coordinates around the center of the ColorRect
	vec2 center = size / 2.0;
	vec2 pos_rotated = rotations[direction] * (pos - center) + center;

	// 0.0 on the open side of the edge, 1.0 once fully covered. Snapping to
	// `patterns` steps is what makes the edge fade between discrete dither
	// patterns rather than continuously.
	float steps = float(patterns - 1);
	float cover = clamp((curtain_height - pos_rotated.y) / fringe, 0.0, 1.0);
	cover = round(cover * steps) / steps;

	COLOR.a = step(dither_threshold(pos), cover);
}
