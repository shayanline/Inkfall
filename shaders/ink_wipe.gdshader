shader_type canvas_item;
// An ink-bleed wipe for scene transitions. progress 0 = clear, 1 = fully inked black.
// The ink front is broken up by value noise so it reads as a torn comic-panel edge,
// not a clean bar. Put this on a full-rect ColorRect on the top CanvasLayer.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_softness : hint_range(0.001, 0.3) = 0.06;
uniform float noise_scale : hint_range(1.0, 24.0) = 7.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// three horizontal bands close from alternating sides (comic panels)
	float band = floor(UV.y * 3.0);
	bool from_left = mod(band, 2.0) == 0.0;
	float x = from_left ? UV.x : 1.0 - UV.x;

	// ragged ink front
	float n = vnoise(vec2(UV.x, UV.y) * noise_scale);
	float front = progress * 1.15 + (n - 0.5) * 0.18;

	float inked = smoothstep(front + edge_softness, front - edge_softness, x);
	COLOR = vec4(ink_color.rgb, ink_color.a * inked);
}
