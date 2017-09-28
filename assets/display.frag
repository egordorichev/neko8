extern vec4 palette[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords, vec2 screen_coords) {
	int index = int(Texel(texture, texture_coords).r*15.0);
	return palette[index]/256.0;
}