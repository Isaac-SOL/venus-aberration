shader_type canvas_item;

// Translated from https://www.shadertoy.com/view/4ddGWr

const float palette_size = 4.0;
const mat4 bayer_mat = mat4(
	vec4(1,   9,  3, 11),
	vec4(13,  5, 15,  7),
	vec4(4,  12,  2, 10),
	vec4(16,  8, 14,  6)
) / 16.0;

float quantize(float val, float period) {
	return floor((val + (period / 2.0)) / period) * period;
}

float bayer4x4(vec2 uv) {
	vec2 bayer_coord = floor(uv);
	bayer_coord = mod(bayer_coord, 4.0);
	int bayer_index = int(bayer_coord.x + bayer_coord.y * 4.0);
	if (bayer_index ==  0) return bayer_mat[0][0];
	if (bayer_index ==  1) return bayer_mat[0][1];
	if (bayer_index ==  2) return bayer_mat[0][2];
	if (bayer_index ==  3) return bayer_mat[0][3];
	if (bayer_index ==  4) return bayer_mat[1][0];
	if (bayer_index ==  5) return bayer_mat[1][1];
	if (bayer_index ==  6) return bayer_mat[1][2];
	if (bayer_index ==  7) return bayer_mat[1][3];
	if (bayer_index ==  8) return bayer_mat[2][0];
	if (bayer_index ==  9) return bayer_mat[2][1];
	if (bayer_index == 10) return bayer_mat[2][2];
	if (bayer_index == 11) return bayer_mat[2][3];
	if (bayer_index == 12) return bayer_mat[3][0];
	if (bayer_index == 13) return bayer_mat[3][1];
	if (bayer_index == 14) return bayer_mat[3][2];
	if (bayer_index == 15) return bayer_mat[3][3];
	return 0.0; // impossible
}

void fragment() {
	float quant_period = 1.0 / (palette_size - 1.0);
	vec4 base_col = texture(TEXTURE, UV);
	base_col += (bayer4x4(FRAGCOORD.xy) - 0.5) * quant_period;
	float quantized = quantize(base_col.g, quant_period);
	vec3 quant_vec = vec3(0, quantized, 0);
	COLOR.rgb = quant_vec;
	if (base_col.g < 0.2) COLOR.a = 0.0;
}
