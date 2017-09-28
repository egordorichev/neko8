extern float palette[16];
vec4 effect(vec4 color, Image texture,
	vec2 texture_coords, vec2 screen_coords) {
vec4 texcolor = Texel(texture, texture_coords);
if(texcolor.a == 0.0) {
return vec4(0.0,0.0,0.0,0.0);
}
int index = int(color.r*16.0);
return vec4(vec3(palette[index]/16.0),1.0);
}