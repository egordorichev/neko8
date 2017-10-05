#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>

namespace api {
	void cls(neko *machine, unsigned int c) {
		c &= 0xf;
		c = c << 4 | c;

		memset(machine, VRAM_START, (byte) c, VRAM_SIZE);
	}

	unsigned int color(neko *machine, int c) {
		if (c < 0) {
			return (unsigned int) peek(machine, OTHER_START).to_ulong();
		}

		poke(machine, OTHER_START, (unsigned int) c); // Poke color
		return (unsigned int) peek(machine, OTHER_START).to_ulong();
	}

	void line(neko *machine, unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, int c) {
		c = color(machine, c);

		if (x0 > x1) {
			unsigned int tmp = x0;
			x0 = x1;
			x1 = tmp;
		}

		if (y0 > y1) {
			unsigned int tmp = y0;
			y0 = y1;
			y1 = tmp;
		}

		unsigned int dx = x1 - x0;
		unsigned int dy = y1 - y0;

		if (dx < 1 && dy < 1) {
			pset(machine, x0, y1, c);
			return;
		}

		if (dx > dy) {
			for (unsigned int x = x0; x <= x1; x++) {
				unsigned int y = y0 + dy * (x - x0) / dx;
				pset(machine, x, y, c);
			}
		} else {
			for (unsigned int y = y0; y <= y1; y++) {
				unsigned int x = x0 + dx * (y - y0) / dy;
				pset(machine, x, y, c);
			}
		}
	}

	void rect(neko *machine, unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, int c) {
		color(machine, c);

		if (x0 > x1) {
			unsigned int tmp = x0;
			x0 = x1;
			x1 = tmp;
		}

		if (y0 > y1) {
			unsigned int tmp = y0;
			y0 = y1;
			y1 = tmp;
		}

		line(machine, x0, y0, x1, y0);
		line(machine, x0, y1, x1, y1);
		line(machine, x0, y0, x0, y1);
		line(machine, x1, y0, x1, y1);
	}

	void rectfill(neko *machine, unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, int c) {
		c = color(machine, c);

		if (x0 > x1) {
			unsigned int tmp = x0;
			x0 = x1;
			x1 = tmp;
		}

		if (y0 > y1) {
			unsigned int tmp = y0;
			y0 = y1;
			y1 = tmp;
		}

		for (unsigned int x = x0; x <= x1; x++) {
			for (unsigned int y = y0; y <= y1; y++) {
				pset(machine, x, y, c);
			}
		}
	}

	void circ(neko *machine, unsigned int ox, unsigned int oy, unsigned int r, int c) {
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

	void horizontalLine(neko *machine, unsigned int x0, unsigned int y, unsigned int x1, unsigned int c) {
		for (unsigned int x = x0; x <= x1; x++) {
			pset(machine, x, y, c);
		}
	}

	void plotPoints(neko *machine, unsigned int cx, unsigned int cy, unsigned int x, unsigned int y, unsigned int c) {
		horizontalLine(machine, cx - x, cy + y, cx + x, c);

		if (y != 0) {
			horizontalLine(machine, cx - x, cy - y, cx + x, c);
		}
	}

	void circfill(neko *machine, unsigned int cx, unsigned int cy, unsigned int r, int c) {
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

	unsigned int pget(neko *machine, int x, int y) {
		if (x == -1 || y == -1 || x < 0 || y < 0
		    || x > NEKO_W || y > NEKO_H) {
			return 0;
		}

		return peek4(machine, VRAM_START + x + y * NEKO_W).to_ulong();
	}

	void pset(neko *machine, int x, int y, int c) {
		if (x == -1 || y == -1 || c == -1 || x < 0
		    || y < 0 || x > NEKO_W || y > NEKO_H) {
			return;
		}

		poke4(machine, VRAM_START + x + y * NEKO_W, c);
	}

	unsigned int rnd(neko *machine, unsigned int a) {
		return rand() % a;
	}
};