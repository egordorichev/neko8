#ifndef neko_console_hpp
#define neko_console_hpp

#include <string>

struct neko;

typedef struct neko_console {
	std::string input;
	bool forceDraw;
} neko_console;

namespace console {
	neko_console *init(neko *machine);
	void render(neko *machine);
	void clean(neko_console *console);
};

#endif