extern vec4 palette[16];

  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    int index=int(Texel(texture, texture_coords).r*255.0+0.5);
    float ta=float(Texel(texture,texture_coords).a);
    // lookup the colour in the palette by index
    vec4 col=palette[index]/255.0;    col.a = col.a*color.a*ta;
    return col;
}