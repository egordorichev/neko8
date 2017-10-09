#include <api.hpp>
#include <ram.hpp>
#include <neko.hpp>
#include <iostream>
#include <cmath>

#define PI 3.14159265358979323846f
#define CHECK_BIT(var, pos) ((var) & (1 << (pos)))

static const char *font[] = {
	"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111001101100111011100110101011101110101010001110110001101110010011100110111010101010101010101010111011001110111010101110100011101110111011100100111011000110010001101100000000000000000000101000000000001010101001001010000000101000010011100100110001001010010000000000",
	"111011001110110011101110111010101110111010101000111011000110111001001110011011101010101010101010101011101010101010001010100010001000101001000100101010001110101010101010101010101000010010101010101010101010001001000010001010101000100000101010101010100100001010000010100001000100000000000100010001000100010011100010111010100100001001000100010011001010110000101010100000000000",
	"101011001000101011001100100010100100010011001000111010101010101010101010100001001010101010100100111000101110110010001010110011001000111001000100110010001010101010101110101011001110010010101010101001001110010001001110011011101110111000101110111010100100011010000010100011000110000000000000000010000010111000000100101000001110111001000100010001101010111000000000000011100000",
	"111010101000101010001000101011100100010010101000101010101010111011001100001001001010111011101010001010001010101010001010100010001010101001000100101010001010101010101000110010100010010010101110111010100010100001001000001000100010101000101010001010100000000010000010100001000100000001000100010001000100010011101000111000000100100001000100010011101000101000000000000000000000",
	"101011101110110011101000111010101110110010101110101010101100100001101010110001000110010011101010111011101010111001101110111010001110101011101100101011101010101011001000011010101100010001100100111010101110111011101110111000101110111000101110001011100100010011000110010001101100010010001000000000101000000000001010101000001010000010000010010001000110111000000000000000001110"
};

static const char *letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!?[]({}.,;:<>+=%#^*~/\\|$@&`\"'-_";
static int llen = strlen(letters);

namespace api {
	static int applyCamX(neko *machine, int x) {
		return x - (int) (peek(machine, DRAW_START + 0x0044) | peek(machine, DRAW_START + 0x0043) << 8) * (peek4(machine, (DRAW_START + 0x0047) * 2) == 0 ? 1 : -1);
	}

	static int applyCamY(neko *machine, int y) {
		return y - (int) (peek(machine, DRAW_START + 0x0046) | peek(machine, DRAW_START + 0x0045) << 8) * (peek4(machine, (DRAW_START + 0x0047) * 2 + 1) == 0 ? 1 : -1);
	}

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

	float sin(neko *machine, float a) {
		return std::sin(a * PI / 180);
	}

	float cos(neko *machine, float a) {
		return std::cos(a * PI / 180);
	}

	void cls(neko *machine, u32 c) {
		c &= 0xf;
		c = c << 4 | c;

		memset(machine, VRAM_START, (byte) c, VRAM_SIZE);
		cursor(machine, 0, 0);
	}

	void cursor(neko *machine, byte x = 0, byte y = 0) {
		poke(machine, DRAW_START + 0x0003, x);
		poke(machine, DRAW_START + 0x0004, y);
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

		/*x0 = applyCamX(machine, x0);
		y0 = applyCamY(machine, y0);
		x1 = applyCamX(machine, x1);
		y1 = applyCamY(machine, y1);*/

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

		/*x0 = applyCamX(machine, x0);
		y0 = applyCamY(machine, y0);
		x1 = applyCamX(machine, x1);
		y1 = applyCamY(machine, y1);*/

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

		/*x0 = applyCamX(machine, x0);
		y0 = applyCamY(machine, y0);
		x1 = applyCamX(machine, x1);
		y1 = applyCamY(machine, y1);*/

		for (u32 x = x0; x <= x1; x++) {
			for (u32 y = y0; y <= y1; y++) {
				pset(machine, x, y, c);
			}
		}
	}

	void circ(neko *machine, u32 ox, u32 oy, u32 r, int c) {
		c = color(machine, c);

		/*ox = applyCamX(machine, ox);
		oy = applyCamY(machine, oy);*/

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
		for (u32 x = max(machine, 0, x0); x <= min(machine, NEKO_W - 1, x1); x++) {
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

		/*cx = applyCamX(machine, cx);
		cy = applyCamY(machine, cy);*/

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
		if (x == -1 || y == -1 || x < 0 || y < 0 || x > NEKO_W - 1 || y > NEKO_H - 1) {
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

	static void scroll(neko *machine, int pixels) {
		// TODO
	}

	void print(neko *machine, const char *str, int px, int py, int c) {
		c = color(machine, c);
		bool canScroll = false;

		if (px == -1 && py == -1) {
			px = peek(machine, DRAW_START + 0x0003);
			py = peek(machine, DRAW_START + 0x0004);
			canScroll = true;
		}

		/*px = applyCamX(machine, px);
		py = applyCamY(machine, py);*/

		// Actually print the string
		for (u32 i = 0; i < strlen(str); i++) {
			char ch = str[i];
			int id = -1;

			for (int j = 0; j < llen; j++) {
				if (letters[j] == ch) {
					id = j;
					break;
				}
			}

			if (id >= 0) {
				for (byte y = 0; y < 5; y++) {
					for (byte x = 0; x < 4; x++) {
						const char *b = font[y];

						if (b[id * 4 + x] == '1') {
							pset(machine, px + x + i * 4, py + y, c);
						}
					}
				}
			}
		}

		if (canScroll) {
			py += 6;

			if (py > NEKO_H - 6) {
				py -= 6;
				scroll(machine, 6);
			}

			poke(machine, DRAW_START + 0x0004, py);
		}
	}

	void pal(neko *machine, s16 c0, s16 c1) {
		if (c0 == -1) {
			// Reset palette
			for (u32 i = 0; i < 16; i++) {
				// Color mapping
				poke4(machine, (DRAW_START + 0x0039) * 2 + i, i);
			}
		} else if (c1 == -1) {
			poke4(machine, (DRAW_START + 0x0039) * 2 + c0 % 16, c0 % 16);
		} else {
			poke4(machine, (DRAW_START + 0x0039) * 2 + c0 % 16, c1 % 16);
		}
	}

	void palt(neko *machine, s16 c, bool transp) {
		byte v = peek(machine, DRAW_START + 0x0041 + c % 8);

		if (transp) {
			v |= 1 << c % 8;
		} else {
			v &= ~(1 << c % 8);
		}

		poke(machine, DRAW_START + 0x0041 + c % 8, v);
	}

	void camera(neko *machine, s32 x, s32 y) {
		poke4(machine, (DRAW_START + 0x0047) * 2, x >= 0 ? 0 : 1);
		poke4(machine, (DRAW_START + 0x0047) * 2 + 1, y >= 0 ? 0 : 1);

		x = abs(x);
		y = abs(y);

		poke(machine, DRAW_START + 0x0043, (x >> 8 & 0xFF)); // Camera Y (first byte)
		poke(machine, DRAW_START + 0x0044, x & 0xFF); // Camera X (second byte)
		poke(machine, DRAW_START + 0x0045, (y >> 8)); // Camera Y (first byte)
		poke(machine, DRAW_START + 0x0046, y & 0xFF); // Camera X (second byte
	}
};