extern float palette[16];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  int index=int(color.r*255.0+0.5);
  float ta=float(Texel(texture,texture_coords).a);
  float col=palette[index]/255.0;  return vec4(col, 0.0, 0.0, color.a*ta);
}