#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>
#include <iostream>

#define CHECK_BIT(var, pos) ((var) & (1 << (pos)))

static const byte font[] = {
	0b1110000, 0b1010000, 0b1110000, 0b0000000, 0b1110000, 0b1100000, 0b1000000, 0b0000000, 0b1110000, 0b1000000, 0b1000000, 0b0000000, 0b1110000, 0b1000000, 0b1100000, 0b0000000, 0b1110000, 0b1100000, 0b1000000, 0b0000000, 0b1110000, 0b1100000, 0b1000000, 0b0000000, 0b1110000, 0b1000000, 0b1010000, 0b0000000, 0b1110000, 0b1000000, 0b1110000, 0b0000000, 0b1000000, 0b1110000, 0b1000000, 0b0000000, 0b1000000, 0b1110000, 0b1000000, 0b0000000, 0b1110000, 0b1000000, 0b1010000, 0b0000000, 0b1110000, 0b0000000, 0b0000000, 0b0000000, 0b1110000, 0b1100000, 0b1110000, 0b0000000, 0b1110000, 0b1000000, 0b1100000, 0b0000000, 0b1100000, 0b1000000, 0b1110000, 0b0000000, 0b1110000, 0b1010000, 0b1110000, 0b0000000, 0b1100000, 0b1010000, 0b1000000, 0b0000000, 0b1110000, 0b1010000, 0b1100000, 0b0000000, 0b1000000, 0b1000000, 0b1010000, 0b0000000, 0b1000000, 0b1110000, 0b1000000, 0b0000000, 0b1110000, 0b0000000, 0b1110000, 0b0000000, 0b1110000, 0b1000000, 0b1110000, 0b0000000, 0b1110000, 0b1000000, 0b1110000, 0b0000000, 0b1010000, 0b1000000, 0b1010000, 0b0000000, 0b1100000, 0b1000000, 0b1110000, 0b0000000, 0b1010000, 0b1000000, 0b1100000, 0b0000000, 0b1111000, 0b1010000, 0b1111000, 0b0000000, 0b1111000, 0b1010000, 0b1111000, 0b0000000, 0b1110000, 0b1000000, 0b1000000, 0b0000000, 0b1111000, 0b1000000, 0b1110000, 0b0000000, 0b1111000, 0b1010000, 0b1000000, 0b0000000, 0b1111000, 0b1010000, 0b1000000, 0b0000000, 0b1110000, 0b1000000, 0b1001000, 0b0000000, 0b1111000, 0b1000000, 0b1111000, 0b0000000, 0b1000000, 0b1111000, 0b1000000, 0b0000000, 0b1000000, 0b1111000, 0b1000000, 0b0000000, 0b1111000, 0b1000000, 0b1111000, 0b0000000, 0b1111000, 0b0000000, 0b0000000, 0b0000000, 0b1111000, 0b1100000, 0b1111000, 0b0000000, 0b1111000, 0b1000000, 0b1110000, 0b0000000, 0b1110000, 0b1000000, 0b1111000, 0b0000000, 0b1111000, 0b1010000, 0b1110000, 0b0000000, 0b1110000, 0b1001000, 0b1100000, 0b0000000, 0b1111000, 0b1010000, 0b1111000, 0b0000000, 0b1100000, 0b1010000, 0b1111000, 0b0000000, 0b1000000, 0b1111000, 0b1000000, 0b0000000, 0b1111000, 0b0000000, 0b1111000, 0b0000000, 0b1111000, 0b1000000, 0b1111000, 0b0000000, 0b1111000, 0b1000000, 0b1111000, 0b0000000, 0b1111000, 0b1000000, 0b1111000, 0b0000000, 0b1110000, 0b1000000, 0b1111000, 0b0000000, 0b1001000, 0b1010000, 0b1100000, 0b0000000, 0b1000000, 0b1111000, 0b0000000, 0b0000000, 0b1111000, 0b1010000, 0b1110000, 0b0000000, 0b1000000, 0b1010000, 0b1111000, 0b0000000, 0b1110000, 0b1000000, 0b1111000, 0b0000000, 0b1110000, 0b1010000, 0b1111000, 0b0000000, 0b1111000, 0b1000000, 0b1100000, 0b0000000, 0b1000000, 0b1000000, 0b1111000, 0b0000000, 0b1111000, 0b1010000, 0b1111000, 0b0000000, 0b1110000, 0b1010000, 0b1111000, 0b0000000, 0b1111000, 0b1000000, 0b1111000, 0b0000000, 0b0000000, 0b1110000, 0b0000000, 0b0000000, 0b1000000, 0b1010000, 0b1110000, 0b0000000, 0b1111000, 0b1000000, 0b0000000, 0b0000000, 0b0000000, 0b1000000, 0b1111000, 0b0000000, 0b1110000, 0b1000000, 0b0000000, 0b0000000, 0b1000000, 0b1111000, 0b1000000, 0b0000000, 0b1000000, 0b1111000, 0b1000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b1000000, 0b0000000, 0b0000000, 0b0000000, 0b1010000, 0b0000000, 0b0000000, 0b0000000, 0b1010000, 0b0000000, 0b0000000, 0b1000000, 0b1010000, 0b1000000, 0b0000000, 0b1000000, 0b1010000, 0b1000000, 0b0000000, 0b1000000, 0b1110000, 0b1000000, 0b0000000, 0b1010000, 0b1010000, 0b1010000, 0b0000000, 0b1001000, 0b1000000, 0b1100000, 0b0000000, 0b1111000, 0b1010000, 0b1111000, 0b0000000, 0b1000000, 0b1000000, 0b1000000, 0b0000000, 0b1010000, 0b1110000, 0b1010000, 0b0000000, 0b1100000, 0b1000000, 0b1100000, 0b0000000, 0b0000000, 0b1110000, 0b1000000, 0b0000000, 0b1000000, 0b1110000, 0b0000000, 0b0000000, 0b0000000, 0b1111000, 0b0000000, 0b0000000, 0b1111000, 0b1111000, 0b1111000, 0b0000000, 0b1110000, 0b1000000, 0b1100000, 0b0000000, 0b1111000, 0b1110000, 0b1100000, 0b0000000, 0b0000000, 0b1000000, 0b1000000, 0b0000000, 0b1100000, 0b0000000, 0b1100000, 0b0000000, 0b1000000, 0b1000000, 0b0000000, 0b0000000, 0b1000000, 0b1000000, 0b1000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000
};

static const char *letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!?[]({}.,;:<>+=%#^*~/\\\\|$@&`\\\"'-_ ";

namespace api {
	float rnd(neko *machine, float b) {
		float a = 0;
		float random = ((float) rand()) / (float) RAND_MAX;
		float diff = b - a;
		float r = random * diff;
		return a + r;
	}

	float min(neko *machine, float a, float b) {
		return a > b ? b : a;
	}

	float max(neko *machine, float a, float b) {
		return a < b ? b : a;
	}

	float mid(neko *machine, float a, float b, float c) {
		if (a > b) {
			s32 tmp = a;
			a = b;
			b = tmp;
		}

		max(machine, a, min(machine, b, c));
	}

	void cls(neko *machine, u32 c) {
		c &= 0xf;
		c = c << 4 | c;

		memset(machine, VRAM_START, (byte) c, VRAM_SIZE);
	}

	u32 color(neko *machine, int c) {
		if (c < 0) {
			return (u32) peek(machine, DRAW_START);
		}

		poke(machine, DRAW_START, c % 16); // Poke color
		return (u32) peek(machine, DRAW_START);
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
		    || x > NEKO_W - 1 || y > NEKO_H - 1) {
			return 0;
		}

		return peek4(machine, VRAM_START * 2 + x + y * NEKO_W);
	}

	void pset(neko *machine, int x, int y, int c) {
		if (x == -1 || y == -1 || c == -1 || x < 0
		    || y < 0 || x > NEKO_W - 1 || y > NEKO_H - 1) {
			return;
		}

		poke4(machine, VRAM_START * 2 + x + y * NEKO_W, c);
	}

	void clip(neko *machine, int x, int y, int w, int h) {
		if (x == -1) {
			x = 0;
		}

		if (y == -1) {
			y = 0;
		}

		if (w == -1) {
			w = NEKO_W;
		}

		if (h == -1) {
			h = NEKO_H;
		}

		x = mid(machine, 0, NEKO_W - 1, x);
		y = mid(machine, 0, NEKO_H - 1, y);
		w = mid(machine, 0, NEKO_W, w);
		h = mid(machine, 0, NEKO_H, h);

		poke(machine, DRAW_START + 0x0005, x); // Clip X
		poke(machine, DRAW_START + 0x0006, y); // Clip Y
		poke(machine, DRAW_START + 0x0007, w); // Clip W
		poke(machine, DRAW_START + 0x0008, h); // Clip H
	}

	// Used for capping FPS
	float nextFrame = SDL_GetPerformanceCounter();
	float timePerFrame = SDL_GetPerformanceFrequency() / 60.0f;

	void flip(neko *machine) {
		// Render neko8
		machine::render(machine);
		// Sync window
		SDL_RenderPresent(machine->graphics->renderer);
		// Cap FPS
		float delay = nextFrame - SDL_GetPerformanceCounter();

		if (delay > 0) {
			SDL_Delay(delay * 1000 / SDL_GetPerformanceFrequency());
		} else {
			nextFrame -= delay;
		}
	}

	void print(neko *machine, char *str, int px, int py, int c) {
		c = color(machine, c);

		for (u32 i = 0; i < strlen(str); i++) {
			char ch = str[i];
			int id = -1;

			for (int j = 0; j < strlen(letters); j++) {
				if (letters[j] == ch) {
					id = j;
					break;
				}
			}

			if (id == -1) {
				continue; // Char is not found
			}

			for (byte x = 0; x < 4; x++) {
				byte b = font[id * 4 + x];

				for (byte y = 0; y < 8; y++) {
					if (CHECK_BIT(b, y)) {
						pset(machine, px + x + i * 4, py + y, c);
					}
				}
			}
		}
	}
};