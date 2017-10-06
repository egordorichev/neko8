#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>
#include <iostream>

namespace api {
	void cls(neko *machine, u32 c) {
		c &= 0xf;
		c = c << 4 | c;

		memset(machine, VRAM_START, (byte) c, VRAM_SIZE);
	}

	u32 color(neko *machine, int c) {
		if (c < 0) {
			return (u32) peek(machine, OTHER_START);
		}

		std::cout << c << "\n";

		poke(machine, OTHER_START, c % 16); // Poke color
		return (u32) peek(machine, OTHER_START);
	}

	void line(neko *machine, u32 x0, u32 y0, u32 x1, u32 y1, int c) {
		c = color(machine, c);

		if (x0 > x1) {
			u32 tmp = x0;
			x0 = x1;
			x1 = tmp;
		}

		if (y0 > y1) {
			u32 tmp = y0;
			y0 = y1;
			y1 = tmp;
		}

		u32 dx = x1 - x0;
		u32 dy = y1 - y0;

		if (dx < 1 && dy < 1) {
			pset(machine, x0, y1, c);
			return;
		}

		if (dx > dy) {
			for (u32 x = x0; x <= x1; x++) {
				u32 y = y0 + dy * (x - x0) / dx;
				pset(machine, x, y, c);
			}
		} else {
			for (u32 y = y0; y <= y1; y++) {
				u32 x = x0 + dx * (y - y0) / dy;
				pset(machine, x, y, c);
			}
		}
	}

	void rect(neko *machine, u32 x0, u32 y0, u32 x1, u32 y1, int c) {
		color(machine, c);

		if (x0 > x1) {
			u32 tmp = x0;
			x0 = x1;
			x1 = tmp;
		}

		if (y0 > y1) {
			u32 tmp = y0;
			y0 = y1;
			y1 = tmp;
		}

		line(machine, x0, y0, x1, y0);
		line(machine, x0, y1, x1, y1);
		line(machine, x0, y0, x0, y1);
		line(machine, x1, y0, x1, y1);
	}

	void rectfill(neko *machine, u32 x0, u32 y0, u32 x1, u32 y1, int c) {
		c = color(machine, c);

		if (x0 > x1) {
			u32 tmp = x0;
			x0 = x1;
			x1 = tmp;
		}

		if (y0 > y1) {
			u32 tmp = y0;
			y0 = y1;
			y1 = tmp;
		}

		for (u32 x = x0; x <= x1; x++) {
			for (u32 y = y0; y <= y1; y++) {
				pset(machine, x, y, c);
			}
		}
	}

	void circ(neko *machine, u32 ox, u32 oy, u32 r, int c) {
		c = color(machine, c);

		int x = r;
		int y = 0;
		int decisionOver2 = 1 - x;

		while (y <= x) {
			pset(machine, ox + x, oy + y, c);
			pset(machine, ox + y, oy + x, c);
			pset(machine, ox - x, oy + y, c);
			pset(machine, ox - y, oy + x, c);
			pset(machine, ox - x, oy - y, c);
			pset(machine, ox - y, oy - x, c);
			pset(machine, ox + x, oy - y, c);
			pset(machine, ox + y, oy - x, c);

			y += 1;

			if (decisionOver2 < 0) {
				decisionOver2 = decisionOver2 + 2 * y + 1;
			} else {
				x = x - 1;
				decisionOver2 = decisionOver2 + 2 * (y - x) + 1;
			}
		}
	}

	void horizontalLine(neko *machine, u32 x0, u32 y, u32 x1, u32 c) {
		for (u32 x = x0; x <= x1; x++) {
			pset(machine, x, y, c);
		}
	}

	void plotPoints(neko *machine, u32 cx, u32 cy, u32 x, u32 y, u32 c) {
		horizontalLine(machine, cx - x, cy + y, cx + x, c);

		if (y != 0) {
			horizontalLine(machine, cx - x, cy - y, cx + x, c);
		}
	}

	void circfill(neko *machine, u32 cx, u32 cy, u32 r, int c) {
		color(machine, c);

		int x = r;
		int y = 0;
		int err = 1 - r;

		while (y <= x) {
			plotPoints(machine, cx, cy, x, y, c);

			if (err < 0) {
				err = err + 2 * y + 3;
			} else {
				if (x != y) {
					plotPoints(machine, cx, cy, y, x, c);
				}

				x -= 1;
				err = err + 2 * (y - x) + 3;
			}

			y += 1;
		}
	}

	u32 pget(neko *machine, int x, int y) {
		if (x == -1 || y == -1 || x < 0 || y < 0
		    || x > NEKO_W || y > NEKO_H) {
			return 0;
		}

		return peek4(machine, VRAM_START * 2 + x + y * NEKO_W);
	}

	void pset(neko *machine, int x, int y, int c) {
		if (x == -1 || y == -1 || c == -1 || x < 0
		    || y < 0 || x > NEKO_W || y > NEKO_H) {
			return;
		}

		poke4(machine,VRAM_START * 2 + x + y * NEKO_W, c);
	}

	u32 rnd(neko *machine, u32 a) {
		return rand() % a;
	}
};