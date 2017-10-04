#ifndef neko_fs_hpp
#define neko_fs_hpp

#include <config.hpp>

#define FILENAME_MAX 256

typedef struct neko_fs {
	char dir[FILENAME_MAX];
	char working[FILENAME_MAX];
} neko_fs;

typedef struct neko;

namespace fs {
	// Create FS
	neko_fs *init(neko *machine);
	// Free fs
	void init(neko_fs *fs);
	// Checks, if file exists
	bool exists(neko *machine, char *name);
	// Writes data to file
	bool write(neko *machine, char *name, void *data, unsigned int size);
	// Reads data from file
	void *read(neko *machine, char *name);
}

#endif