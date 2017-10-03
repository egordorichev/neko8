#ifndef neko_api_hpp
#define neko_api_hpp

#include <config.hpp>

void cls(unsigned int c = 0);
unsigned int color(int c = 0);
void line(unsigned int x0 = 0, unsigned int y0 = 0, unsigned int x1 = 0, unsigned int y1 = 0, int c = -1);
void rect(unsigned int x0 = 0, unsigned int y0 = 0, unsigned int x1 = 0, unsigned int y1 = 0, int c = -1);
void rectfill(unsigned int x0 = 0, unsigned int y0 = 0, unsigned int x1 = 0, unsigned int y1 = 0, int c = -1);
void circ(unsigned int ox = 0, unsigned int oy = 0, unsigned int r = 1, int c = -1);
void circfill(unsigned int ox = 0, unsigned int oy = 0, unsigned int r = 1, int c = -1);
unsigned int pget(int x = -1, int y = -1);
void pset(int x = -1, int y = -1, int c = -1);
unsigned int rnd(unsigned int a = 1);

#endif