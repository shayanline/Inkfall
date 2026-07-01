shader_type canvas_item;
// One level of the bloom pyramid. Reads the source texture, optionally bright-passes it (only the
// first level, the lit scene -> b0), and blurs with a 3x3 tent at the OUTPUT texel scale so each
// successive downsample compounds a real, widening blur. Chaining six of these from 1/2 down to 1/64
// resolution gives a wide, smooth glow that reaches across the frame for the cost of tiny buffers,
// which a single full-res forward gather cannot do. Compatibility-safe: only texture() and a fixed
// tap pattern, no mipmaps, no textureLod.

uniform sampler2D tex : filter_linear;
uniform vec2 texel;                                  // 1 / output size, set from the script
uniform bool do_bright = false;                      // bright-pass on the first level only
uniform float threshold : hint_range(0.1, 1.0) = 0.42;

// Bright-pass: keep only the part of a sample above the threshold, soft knee. Uses the max channel so
// saturated neon (low luma, high value) still blooms, matching the old inline bloom's bright_pass.
vec3 bright(vec3 c) {
	float v = max(max(c.r, c.g), c.b);
	float s = smoothstep(threshold - 0.10, threshold + 0.10, v);
	return c * s;
}

void fragment() {
	vec2 uv = UV;
	vec3 c = texture(tex, uv).rgb * 4.0;
	c += texture(tex, uv + vec2(texel.x, 0.0)).rgb * 2.0;
	c += texture(tex, uv + vec2(-texel.x, 0.0)).rgb * 2.0;
	c += texture(tex, uv + vec2(0.0, texel.y)).rgb * 2.0;
	c += texture(tex, uv + vec2(0.0, -texel.y)).rgb * 2.0;
	c += texture(tex, uv + texel).rgb;
	c += texture(tex, uv - texel).rgb;
	c += texture(tex, uv + vec2(texel.x, -texel.y)).rgb;
	c += texture(tex, uv + vec2(-texel.x, texel.y)).rgb;
	c /= 16.0;
	if (do_bright) {
		c = bright(c);
	}
	COLOR = vec4(c, 1.0);
}
