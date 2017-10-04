#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>
#include <iostream>

void cls(unsigned int c) {
	c &= 0xf;
	c = c << 4 | c;

	memset(VRAM_START, (byte) c, VRAM_SIZE);
}

unsigned int color(int c) {
	if (c < 0) {
		return (unsigned int) peek(OTHER_START).to_ulong();
	}

	poke(OTHER_START, (unsigned int) c); // Poke color
	return (unsigned int) peek(OTHER_START).to_ulong();
}

void line(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, int c) {
	c = color(c);

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
		pset(x0, y1, c);
		return;
	}

	if (dx > dy) {
		for (unsigned int x = x0; x <= x1; x++) {
			unsigned int y = y0 + dy * (x - x0) / dx;
			pset(x, y, c);
		}
	} else {
		for (unsigned int y = y0; y <= y1; y++) {
			unsigned int x = x0 + dx * (y - y0) / dy;
			pset(x, y, c);
		}
	}
}

void rect(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, int c) {
	color(c);

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

	line(x0, y0, x1, y0);
	line(x0, y1, x1, y1);
	line(x0, y0, x0, y1);
	line(x1, y0, x1, y1);
}

void rectfill(unsigned int x0, unsigned int y0, unsigned int x1, unsigned int y1, int c) {
	c = color(c);

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
			pset(x, y, c);
		}
	}
}

void circ(unsigned int ox, unsigned int oy, unsigned int r, int c) {
	c = color(c);

	int x = r;
	int y = 0;
	int decisionOver2 = 1 - x;

	while (y <= x) {
		pset(ox + x, oy + y, c);
		pset(ox + y, oy + x, c);
		pset(ox - x, oy + y, c);
		pset(ox - y, oy + x, c);
		pset(ox - x, oy - y, c);
		pset(ox - y, oy - x, c);
		pset(ox + x, oy - y, c);
		pset(ox + y, oy - x, c);

		y += 1;

		if (decisionOver2 < 0) {
			decisionOver2 = decisionOver2 + 2 * y + 1;
		} else {
			x = x - 1;
			decisionOver2 = decisionOver2 + 2 * (y-x) + 1;
		}
	}
}

void horizontalLine(unsigned int x0, unsigned int y, unsigned int x1, unsigned int c) {
	for (unsigned int x = x0; x <= x1; x++) {
		pset(x, y, c);
	}
}

void plotPoints(unsigned int cx, unsigned int cy, unsigned int x, unsigned int y, unsigned int c) {
	horizontalLine(cx - x, cy + y, cx + x, c);

	if (y != 0) {
		horizontalLine(cx - x, cy - y, cx + x, c);
	}
}

void circfill(unsigned int cx, unsigned int cy, unsigned int r, int c) {
	color(c);

	int x = r;
	int y = 0;
	int err = 1 - r;

	while (y <= x) {
		plotPoints(cx, cy, x, y, c);

		if (err < 0) {
			err = err + 2 * y + 3;
		} else {
			if (x != y) {
				plotPoints(cx, cy, y, x, c);
			}

			x -= 1;
			err = err + 2 * (y - x) + 3;
		}

		y += 1;
	}
}

unsigned int pget(int x, int y) {
	if (x == -1 || y == -1 || x < 0 || y < 0
	    || x > machine.config->canvasWidth || y > machine.config->canvasHeight) {
		return 0;
	}

	return peek4(VRAM_START + x + y * machine.config->canvasWidth).to_ulong();
}

void pset(int x, int y, int c) {
	if (x == -1 || y == -1 || c == -1 || x < 0
	    || y < 0 || x > machine.config->canvasWidth || y > machine.config->canvasHeight) {
		return;
	}

	poke4(VRAM_START + x + y * machine.config->canvasWidth, c);
}

unsigned int rnd(unsigned int a) {
	return rand() % a;
}
