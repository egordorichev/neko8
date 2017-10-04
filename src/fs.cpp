#include <fs.hpp>

namespace fs {
	neko_fs *init(neko *machine) {
		neko_fs *fs = new neko_fs;

		return fs;
	}
};