#ifndef neko_api_hpp
#define neko_api_hpp

#include <config.hpp>

void cls(unsigned int color);
void color(unsigned int c);
void rect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, unsigned int c);
unsigned int pget(unsigned int x, unsigned int y);
void pset(unsigned int x, unsigned int y, unsigned int color);

#endif