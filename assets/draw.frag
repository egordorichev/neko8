extern float palette[16];
vec4 effect(vec4 color, Image texture,
			vec2 texture_coords,
			vec2 screen_coords) {
	int index = int(color.r*16.0);
	return vec4(vec3(palette[index]/16.0),1.0);
}