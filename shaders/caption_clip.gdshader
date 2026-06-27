shader_type canvas_item;
// A torn paper-cut reveal for narration lines, carried over from Inkfall's captionfx. reveal 0 = hidden,
// 1 = fully shown. The leading edge is ragged per row (a seeded jitter), and the sweep runs in one of
// three deterministic directions chosen per line: 0 = left to right, 1 = right to left, 2 = centre out.

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform int variant = 0;
uniform float seed = 1.0;
uniform float depth : hint_range(0.0, 0.2) = 0.06;   // how deep the torn teeth reach, fraction of width
uniform float rows = 14.0;                            // number of torn segments down the edge

float hash(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// a ragged front: each row of the edge bites in by a seeded amount, so the cut reads as torn paper
	float row = floor(UV.y * rows);
	float jitter = (hash(row) - 0.5) * depth * 2.0;
	float front = reveal + jitter;
	float shown;
	if (variant == 1) {
		shown = step(1.0 - UV.x, front);            // right to left
	} else if (variant == 2) {
		shown = step(abs(UV.x - 0.5), front * 0.5); // centre out
	} else {
		shown = step(UV.x, front);                  // left to right
	}
	COLOR = vec4(tex.rgb, tex.a * shown);
}
