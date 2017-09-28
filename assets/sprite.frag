extern float palette[16];
extern float transparent[16];
vec4 effect(vec4 color, Image texture,
	vec2 texture_coords, vec2 screen_coords) {
int index = int(floor(Texel(texture, texture_coords).r*16.0));
float alpha = transparent[index];
return vec4(vec3(palette[index]/16.0),alpha);
}