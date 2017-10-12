#include <code.hpp>
#include <api.hpp>
#include <carts.hpp>
#include <iostream>
#include <vector>

#define CODE_W NEKO_W / 4
#define CODE_H (NEKO_H - 14) / 6

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
	memset(code->colors, COLORS_TEXT, CODE_SIZE);

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
	this->cursorX = 0;
	this->cursorY = 0;

	this->code = machine->carts->loaded->code;
	this->cursorPosition = this->code;

	this->colors = new byte[CODE_SIZE];
	this->onEdit(machine);
}

neko_code::~neko_code() {
	delete[] this->code;
	delete[] this->colors;
}

void neko_code::escape(neko *machine) {
	api::cls(machine, 0);
}

static char *getLineByPosition(neko_code *code, char *pos) {
	char *text = code->code;
	char *line = text;

	while (text < pos) {
		if (*text++ == '\n') {
			line = text;
		}
	}

	return line;
}

static char *getLine(neko_code *code) {
	return getLineByPosition(code, code->cursorPosition);
}

static void updateCursorX(neko_code *code) {
	code->cursorX = code->cursorPosition - getLine(code);
}

static s32 getLinesCount(neko_code *code) {
	char *text = code->code;
	s32 count = 0;

	while (*text) {
		if (*text++ == '\n') {
			count++;
		}
	}

	return count;
}

static char *getPrevLine(neko_code *code) {
	char *text = code->code;
	char *pos = code->cursorPosition;
	char *prevLine = text;
	char *line = text;

	while (text < pos) {
		if (*text++ == '\n') {
			prevLine = line;
			line = text;
		}
	}

	return prevLine;
}

static char *getNextLineByPosition(neko_code *code, char *pos) {
	while (*pos && *pos++ != '\n') {

	}

	return pos;
}

static char *getNextLine(neko_code *code) {
	return getNextLineByPosition(code, code->cursorPosition);
}

static s32 getLineSize(const char *line) {
	s32 size = 0;

	while (*line != '\n' && *line++) {
		size++;
	}

	return size;
}

static void moveCursorUp(neko *machine, neko_code *code) {
	char *prevLine = getPrevLine(code);
	size_t prevSize = getLineSize(prevLine);
	size_t size = code->cursorX;

	code->cursorPosition = prevLine + (prevSize > size ? size : prevSize);
}

static void moveCursorDown(neko *machine, neko_code *code) {
	char *nextLine = getNextLine(code);
	size_t nextSize = getLineSize(nextLine);
	size_t size = code->cursorX;

	code->cursorPosition = nextLine + (nextSize > size ? size : nextSize);
}

static void moveCursorLeft(neko *machine, neko_code *code) {
	if (code->cursorPosition > code->code) {
		code->cursorPosition--;
		updateCursorX(code);
	}
}

static void moveCursorRight(neko *machine, neko_code *code) {
	if (*code->cursorPosition) {
		code->cursorPosition++;
		updateCursorX(code);
	}
}

static void inputSymbol(neko *machine, neko_code *code, char sym, bool parse = true) {
	if (strlen(code->code) >= CODE_SIZE) {
		return;
	}

	char *pos = code->cursorPosition;
	memmove(pos + 1, pos, strlen(pos) + 1);
	*code->cursorPosition++ = sym;

	// history(code);

	updateCursorX(code);

	if (parse) {
		parseSyntax(machine, code);
	}
}


static void deleteChar(neko *machine, neko_code *code) {
	char *pos = code->cursorPosition;
	memmove(pos, pos + 1, strlen(pos));
	parseSyntax(machine, code);
}

static void backspaceChar(neko *machine, neko_code *code) {
	if (code->cursorPosition > code->code) {
		char *pos = --code->cursorPosition;
		memmove(pos, pos + 1, strlen(pos));
		parseSyntax(machine, code);
	}
}

static void insertNewLine(neko *machine, neko_code *code) {
	char *ptr = getLine(code);
	size_t size = 0;

	while (*ptr == ' ') {
		ptr++, size++;
	}

	if (ptr > code->cursorPosition) {
		size -= ptr - code->cursorPosition;
	}

	inputSymbol(machine, code, '\n', false);

	for (size_t i = 0; i < size + 1; i++) {
		inputSymbol(machine, code, ' ');
	}
}

static void drawToolBars(neko *machine, neko_code *code) {
	api::rectfill(machine, 0, 0, NEKO_W, 6, 1);
	api::rectfill(machine, 0, NEKO_H - 7, NEKO_W, NEKO_H, 1);

	s32 x = 0;
	s32 y = 0;

	const char *pointer = code->code;

	while (*pointer) {
		if (code->cursorPosition == pointer) {
			break;
		}

		if (*pointer == '\n') {
			x = 0;
			y++;
		} else {
			x++;
		}

		pointer++;
	}


	std::string lines = std::string("line ") + std::to_string(y + 1) + "/" + std::to_string(getLinesCount(code))
											+ " col " + std::to_string(x);
	api::print(machine, lines.c_str(), 1, NEKO_H - 6, 7);
	api::print(machine, "neko8", 1, 1, 7);
}

void neko_code::event(neko *machine, SDL_Event *event) {
	SDL_Keymod keymod = SDL_GetModState();

	switch (event->type) {
		case SDL_KEYDOWN:
			switch (event->key.keysym.sym) {
				case SDLK_LCTRL:
				case SDLK_RCTRL:
				case SDLK_LSHIFT:
				case SDLK_RSHIFT:
				case SDLK_LALT:
				case SDLK_RALT:
					return;
				case SDLK_UP:
					moveCursorUp(machine, this);
					break;
				case SDLK_DOWN:
					moveCursorDown(machine, this);
					break;
				case SDLK_LEFT:
					moveCursorLeft(machine, this);
					break;
				case SDLK_RIGHT:
					moveCursorRight(machine, this);
					break;
				case SDLK_DELETE:
					deleteChar(machine, this);
					break;
				case SDLK_RETURN:
					insertNewLine(machine, this);
				case SDLK_BACKSPACE:
					backspaceChar(machine, this);
					break;
			}

			this->forceDraw = true;
			break;
		case SDL_TEXTINPUT:
			if (strlen(event->text.text) == 1) {
				inputSymbol(machine, this, *event->text.text);
			}

			this->forceDraw = true;
			break;
	}
}

static void drawCursor(neko *machine, u32 x, u32 y) {
	api::rectfill(machine, x * 4, y * 6 + 7, x * 4 + 4, y * 6 + 12, 8);
}

static void renderCode(neko *machine, neko_code *code) {
	s32 start = 0; // 0 - code->cursorX;
	s32 x = start;
	s32 y = 0 - code->cursorY;

	char *pointer = code->code;
	byte *color = code->colors;

	int cx = -1;
	int cy = -1;

	while (*pointer) {
		if (pointer == code->cursorPosition) {
			cx = x;
			cy = y;
		}

		char ch = *pointer;
		byte c = *color;

		api::printChar(machine, ch, x * 4 + 1, y * 6 + 8, c);

		if (ch == '\n') {
			x = start;
			y += 1;
		} else {
			x += 1;
		}

		*pointer++;
		*color++;
	}

	if (cx == -1 || cy == -1) {
		cx = x;
		cy = y;
	}

	drawCursor(machine, cx, cy);
}

void neko_code::render(neko *machine) {
	if (this->forceDraw) {
		api::cls(machine, 2);

		renderCode(machine, this);
		drawToolBars(machine, this);
		this->forceDraw = false;
	}
}

void neko_code::onEdit(neko *machine) {
	parseSyntax(machine, this);
}