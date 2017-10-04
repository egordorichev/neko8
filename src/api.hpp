#ifndef neko_api_hpp
#define neko_api_hpp

#include <config.hpp>

struct neko;

namespace api {
	void cls(neko *machine, unsigned int c = 0);
	unsigned int color(neko *machine, int c = 0);
	void line(neko *machine, unsigned int x0 = 0, unsigned int y0 = 0, unsigned int x1 = 0, unsigned int y1 = 0, int c = -1);
	void rect(neko *machine, unsigned int x0 = 0, unsigned int y0 = 0, unsigned int x1 = 0, unsigned int y1 = 0, int c = -1);
	void rectfill(neko *machine, unsigned int x0 = 0, unsigned int y0 = 0, unsigned int x1 = 0, unsigned int y1 = 0, int c = -1);
	void circ(neko *machine, unsigned int ox = 0, unsigned int oy = 0, unsigned int r = 1, int c = -1);
	void circfill(neko *machine, unsigned int ox = 0, unsigned int oy = 0, unsigned int r = 1, int c = -1);
	unsigned int pget(neko *machine, int x = -1, int y = -1);
	void pset(neko *machine, int x = -1, int y = -1, int c = -1);
	unsigned int rnd(neko *machine, unsigned int a = 1);
}

#endif
