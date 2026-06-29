shader_type canvas_item;
// The moon asset's tones are extremely tight (luminance ~0.76 to 0.87), so the maria are nearly
// invisible, and the screen-space desaturate flattens them further. This expands that narrow band
// around a pivot into a wide range, so the craters drop to a clear mid grey while the body stays
// bright. Tuned to the asset's measured tones. Preserves the soft-edge alpha.
uniform float pivot : hint_range(0.5, 1.0) = 0.81;
uniform float contrast : hint_range(1.0, 8.0) = 4.0;
uniform float out_mid : hint_range(0.4, 1.0) = 0.72;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = clamp((c.rgb - pivot) * contrast + out_mid, 0.0, 1.0);
	COLOR = c;
}
