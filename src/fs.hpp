#ifndef neko_fs_hpp
#define neko_fs_hpp

#include <config.hpp>

typedef struct neko_fs {

} neko_fs;

typedef struct neko;

namespace fs {
	neko_fs *init(neko *machine);
}

#endif