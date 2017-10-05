#ifndef neko_api_hpp
#define neko_api_hpp

#include <config.hpp>

struct neko;

namespace api {
	void cls(neko *machine, u32 c = 0);
	u32 color(neko *machine, int c = 0);
	void line(neko *machine, u32 x0 = 0, u32 y0 = 0, u32 x1 = 0, u32 y1 = 0, int c = -1);
	void rect(neko *machine, u32 x0 = 0, u32 y0 = 0, u32 x1 = 0, u32 y1 = 0, int c = -1);
	void rectfill(neko *machine, u32 x0 = 0, u32 y0 = 0, u32 x1 = 0, u32 y1 = 0, int c = -1);
	void circ(neko *machine, u32 ox = 0, u32 oy = 0, u32 r = 1, int c = -1);
	void circfill(neko *machine, u32 ox = 0, u32 oy = 0, u32 r = 1, int c = -1);
	u32 pget(neko *machine, int x = -1, int y = -1);
	void pset(neko *machine, int x = -1, int y = -1, int c = -1);
	u32 rnd(neko *machine, u32 a = 1);
}

#endif
