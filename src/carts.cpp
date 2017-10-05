#include <neko.hpp>
#include <api.hpp>

#include <iostream>
#include <sstream>
#include <zlib.h>

#define COMPRESSED_CODE_MAX_SIZE 16384

namespace carts {
	neko_carts *init(neko *machine) {
		neko_carts *carts = new neko_carts;

		carts->loaded = carts::createNew(machine);

		return carts;
	}

	void render(neko *machine) {
		carts::triggerCallback(machine, "_update");
		carts::triggerCallback(machine, "_draw");
	}

	void triggerCallback(neko *machine, const char *name) {
		/* if (machine->state == STATE_RUNNING_CART) {
			auto callback = machine->carts->loaded->env[name];
			if (callback != sol::nil) {
				try {
					callback();

				} catch (sol::error error) {
					machine->state = STATE_CONSOLE;
					std::cout << error.what() << "\n";
					// TODO: output the error in the console
				}
			}
		}*/
	}

	neko_cart *createNew(neko *machine) {
		neko_cart *cart = new neko_cart;

		cart->code = (char *) "-- test ls ls lsl";

		// Create safe lua sandbox
		// cart->lua = sol::state();
		// cart->lua.open_libraries();
		// cart->env = sol::environment(cart->lua, sol::create);

		// Add API
		// TODO: define it :D

		return cart;
	}

	void run(neko *machine) {
		machine->prevState = machine->state;
		machine->state = STATE_RUNNING_CART;
		//machine->carts->loaded->lua.script(machine->carts->loaded->code, machine->carts->loaded->env);

		//if (machine->carts->loaded->env["_draw"] == sol::nil && machine->carts->loaded->env["_update"] == sol::nil) {
		//	machine->state = machine->prevState;
		//}
	}

	char *compressString(char *str) {
		char *res = (char *) malloc(COMPRESSED_CODE_MAX_SIZE * sizeof(char));

		z_stream defstream;
		defstream.zalloc = Z_NULL;
		defstream.zfree = Z_NULL;
		defstream.opaque = Z_NULL;
		defstream.avail_in = (uInt) strlen(str) + 1;
		defstream.next_in = (Bytef *) str;
		defstream.avail_out = (uInt) COMPRESSED_CODE_MAX_SIZE;
		defstream.next_out = (Bytef *)res;

		deflateInit(&defstream, Z_BEST_COMPRESSION);
		deflate(&defstream, Z_FINISH);
		deflateEnd(&defstream);

		return res;
	}

	char *decompressString(char *str)	{
		char *res = (char *) malloc(CODE_SIZE * sizeof(char));

		z_stream infstream;
		infstream.zalloc = Z_NULL;
		infstream.zfree = Z_NULL;
		infstream.opaque = Z_NULL;
		infstream.avail_in = (uInt)((char *) 0 - str);
		infstream.next_in = (Bytef *)str;
		infstream.avail_out = (uInt)sizeof(res);
		infstream.next_out = (Bytef *)res;

		inflateInit(&infstream);
		inflate(&infstream, Z_NO_FLUSH);
		inflateEnd(&infstream);

		return res;
	}

	void load(neko *machine, char *name) {
		ram::reset(machine);

		char *data = fs::read(machine, name);

		if (data == nullptr) {
			return;
		}

		memseta(machine, 0x0, (byte *) data, CART_SIZE);

		// Decompress code
		byte *compressed = memgeta(machine, CODE_START, COMPRESSED_CODE_MAX_SIZE);
		char *decompressed = decompressString((char *) compressed);

		machine->carts->loaded->code = decompressed;

		free(compressed);
	}

	void save(neko *machine, char *name) {
		// Compress code
		char *code = machine->carts->loaded->code;
		char *compressed = compressString(code);

		// Copy it to memory
		memseta(machine, CODE_START, (byte *) compressed, COMPRESSED_CODE_MAX_SIZE);

		// Write out cart data
		byte *data = memgeta(machine, 0x0, CART_SIZE);

		fs::write(machine, name, (char *) data, RAM_SIZE);
		free(compressed);
		free(data);
	}

	void clean(neko_carts *carts) {
		delete carts;
	}
}
