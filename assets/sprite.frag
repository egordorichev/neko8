extern float palette[16];
extern float transparent[16];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  int index=int(Texel(texture, texture_coords).r*255.0+0.5);
  float ta=float(Texel(texture,texture_coords).a);
  float col=palette[index]/255.0;
  float coltrans=transparent[index]*ta;  return vec4(col, 0.0, 0.0, coltrans);
}