#include <code.hpp>
#include <api.hpp>
#include <carts.hpp>
#include <iostream>
#include <vector>

#define COLORS_TEXT 6
#define COLORS_NON_CHAR 5
#define COLORS_kEYWORD 8
#define COLORS_API 9
#define COLORS_NUMBER 12
#define COLORS_SIGN 7
#define COLORS_COMMENT 13
#define COLORS_STRING 12

static bool isLetter(char symbol) {
	return (symbol >= 'A' && symbol <= 'Z') || (symbol >= 'a' && symbol <= 'z') || (symbol == '_');
}

static bool isNumber(char symbol) {
	return (symbol >= '0' && symbol <= '9');
}

static bool isWord(char symbol) {
	return isLetter(symbol) || isNumber(symbol);
}

static bool isDot(char symbol) {
	return (symbol == '.');
}

static void highlightNonChar(neko_code *code) {
	char *text = code->code;
	byte *color = code->colors;

	while (*text) {
		if (*text <= 32) {
			*color = COLORS_NON_CHAR;
		}

		*text++;
		*color++;
	}
}

static void highlightWords(neko_code *code, std::vector<const char *> words, byte c) {
	const char *pointer = code->code;
	s32 count = words.size();

	while (*pointer) {
		char symbol = *pointer;
		const char *start = pointer;

		while (symbol && (isLetter(symbol) || isNumber(symbol))) {
			symbol = *++pointer;
		}

		size_t size = pointer - start;

		for (s32 i = 0; i < count; i++) {
			const char *keyword = words[i];

			if (size == strlen(keyword) && memcmp(start, keyword, size) == 0) {
				memset(code->colors + (start - code->code), c, size);
				break;
			}
		}

		pointer++;
	}
}

static std::vector<const char *> luaKeywords = {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "goto", "if",
	"in", "local", "nil", "not", "or", "repeat",
	"return", "then", "true", "until", "while"
};

static void highlightLuaKeywords(neko_code *code) {
	highlightWords(code, luaKeywords, COLORS_kEYWORD);
}

static std::vector<const char *> apiList = {
	"circ", "circfill", "rect", "rectfill", "pget", "pset",
	"rnd", "max", "min", "mid", "cos", "sin", "print", "printh",
	"cls", "_draw", "_update", "_init" // Callbacks are also marked
};

static void highlightAPI(neko_code *code) {
	highlightWords(code, apiList, COLORS_API);
}

static void highlightNumbers(neko_code *code) {
	const char *text = code->code;
	const char *pointer = text;

	while (*pointer) {
		char symbol = *pointer;

		if (isLetter(symbol)) {
			while (symbol && (isLetter(symbol) || isNumber(symbol) || isDot(symbol))) {
				symbol = *++pointer;
			}
		}

		const char *start = pointer;
		while (symbol && (isNumber(symbol) || isDot(symbol))) {
			symbol = *++pointer;
		}

		if (!isLetter(symbol)) {
			memset(code->colors + (start - text), COLORS_NUMBER, pointer - start);
		}

		pointer++;
	}
}

static std::vector<const char *> luaSigns = {
	"+", "-", "*", "/", "%", "^", "#",
	"&", "~", "|", "<<", ">>", "//",
	"==", "~=", "<=", ">=", "<", ">", "=",
	"(", ")", "{", "}", "[", "]", "::",
	";", ":", ",", ".", "..", "...",
};

static void highlightSigns(neko_code *code) {
	const char *text = code->code;

	for (s32 i = 0; i < luaSigns.size(); i++) {
		const char *sign = luaSigns[i];
		const char *start = text;

		while ((start = strstr(start, sign))) {
			size_t size = strlen(sign);
			memset(code->colors + (start - text), COLORS_SIGN, size);
			start += size;
		}
	}
}

static void highlightCommentsBase(neko_code *code, const char *pattern1, const char *pattern2, s32 extraSize) {
	const char *text = code->code;
	const char *pointer = text;

	while (*pointer) {
		char *start = (char *) strstr(pointer, pattern1);

		if (start) {
			char *end = strstr(start + strlen(pattern1), pattern2);

			if (!end) {
				end = start + strlen(start);
			}

			if (end) {
				end += extraSize;

				memset(code->colors + (start - text), COLORS_COMMENT, end - start);
				pointer = end;
			}
		}

		pointer++;
	}
}

static void highlightStrings(neko_code *code, const char *text, byte *color, char separator) {
	char *start = SDL_strchr(text, separator);

	if (start) {
		char *end = SDL_strchr(start + 1, separator);

		if (end) {
			end++;
			byte *colorPtr = color + (start - text);

			if (*colorPtr != COLORS_COMMENT)
				memset(colorPtr, COLORS_STRING, end - start);

			highlightStrings(code, end, color + (end - text), separator);
		}
	}
}

static void parseSyntax(neko *machine, neko_code *code) {
	if (code->colors != nullptr) {
		delete code->colors;
	}

	int len = strlen(code->code);

	code->colors = new byte[len];
	memset(code->colors, COLORS_TEXT, len);

	if (machine->carts->loaded->lang == LANG_LUA) {
		highlightNonChar(code);
		highlightLuaKeywords(code);
		highlightAPI(code);
		highlightNumbers(code);
		highlightSigns(code);
		highlightCommentsBase(code, "--", "\n", 0);
	}
}

neko_code::neko_code(neko *machine) {
	this->code = machine->carts->loaded->code;
	this->onEdit(machine);
}

neko_code::~neko_code() {
	delete[] this->colors;
}

void neko_code::escape(neko *machine) {
	api::cls(machine, 0);
}

void neko_code::event(neko *machine, SDL_Event *event) {

}

void neko_code::render(neko *machine) {
	api::cls(machine, 2);
	api::rectfill(machine, 0, 0, NEKO_W, 6, 1);
	api::print(machine, "neko8", 1, 1, 7);
	api::rectfill(machine, 0, NEKO_H - 6, NEKO_W, NEKO_H, 1);

	s32 x = 0;
	s32 y = 0;

	char *pointer = this->code;
	byte *color = this->colors;

	while (*pointer) {
		char ch = *pointer;
		byte c = *color;

		api::printChar(machine, ch, x + 1, y + 8, c);

		if (ch == '\n') {
			x = 0;
			y += 6;
		} else {
			x += 4;
		}

		*pointer++;
		*color++;
	}
}

void neko_code::onEdit(neko *machine) {
	parseSyntax(machine, this);
}