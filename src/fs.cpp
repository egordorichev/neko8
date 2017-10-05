#include <neko.hpp>
#include <fs.hpp>

#include <SDL2/SDL.h>
#include <cstring>
#include <iostream>

#if !defined(__WINRT__) && !defined(__WINDOWS__)
#include <unistd.h>
#endif

#if defined(__WINRT__) || defined(__WINDOWS__)
#include <direct.h>
#endif

#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
#endif

#ifdef __ANDROID__
#include <sys/stat.h>
#endif

#define NEKO_PACKAGE "egordorichev"
#define NEKO_NAME "neko8"

namespace fs {


#if defined(__WINDOWS__) || defined(__WINRT__)
	#define UTF8ToString(S) (wchar_t *) SDL_iconv_string("UTF-16LE", "UTF-8", (char *)(S), SDL_strlen(S) + 1)
	#define StringToUTF8(S) SDL_iconv_string("UTF-8", "UTF-16LE", (char *)(S), (SDL_wcslen(S) + 1) * sizeof(wchar_t))
	#define NEKO_DIR _WDIR
	#define _dirent _wdirent
	#define _stat_struct _stat
	#define _opendir _wopendir
	#define _readdir _wreaddir
	#define _closedir _wclosedir
	#define _rmdir _wrmdir
	#define _stat _wstat
	#define _remove _wremove
	#define _fopen _wfopen
	#define _mkdir(name) _wmkdir(name)
	#define _system _wsystem
#else
	#define UTF8ToString(S) (S)
	#define StringToUTF8(S) (S)
	#define NEKO_DIR DIR
	#define _dirent dirent
	#define _stat_struct stat
	#define _opendir opendir
	#define _readdir readdir
	#define _closedir closedir
	#define _rmdir rmdir
	#define _stat stat
	#define _remove remove
	#define _fopen fopen
	#define _mkdir(name) mkdir(name, 0700)
	#define _system system
#endif

	neko_fs *init(neko *machine) {
		neko_fs *fs = new neko_fs;

#if defined(__EMSCRIPTEN__)
		strcpy(fs->dir, "/" NEKO_PACKAGE "/" NEKO_NAME "/");
#elif defined(__ANDROID__)
		strcpy(fs->dir, SDL_AndroidGetExternalStoragePath());
		const char AppFolder[] = "/" NEKO_NAME "/";
		strcat(fs->dir, AppFolder);
		mkdir(fs->dir, 0700);
#else
		char *path = SDL_GetPrefPath(NEKO_PACKAGE, NEKO_NAME);
		strcpy(fs->dir, path);
		SDL_free(path);
#endif

		std::cout << "Using " << fs->dir << " for saving\n";

		return fs;
	}

	void free(neko_fs *fs) {
		delete fs;
	}

	static const char *getFilePath(neko *machine, const char *name) {
		static char path[FILENAME_MAX] = { 0 };

		strcpy(path, machine->fs->dir);

		if (strlen(machine->fs->working)) {
			strcat(path, machine->fs->working);
			strcat(path, "/");
		}

		strcat(path, name);

#if defined(__WINDOWS__)
		// Replace '/' with '\\'
		char *ptr = path;

		while (*ptr) {
			if (*ptr == '/') {
				*ptr = '\\';
			}

			ptr++;
		}
#endif

		return path;
	}

	bool exists(neko *machine, char *name) {
		const char *path = getFilePath(machine, name);
		FILE *file = _fopen(UTF8ToString(path), UTF8ToString("rb"));

		if (file) {
			fclose(file);
			return true;
		}

		return false;
	}

	bool write(neko *machine, char *name, void *data, unsigned int size) {
		FILE *file = _fopen(UTF8ToString(name), UTF8ToString("wb"));

		if (file) {
			fwrite(data, 1, size, file);
			fclose(file);

#if defined(__EMSCRIPTEN__)
			EM_ASM(FS.syncfs(function(){}));
#endif

			return true;
		}

		return false;
	}

	void *read(neko *machine, char *name) {
		FILE *file = _fopen(UTF8ToString(name), UTF8ToString("rb"));
		void *buffer = NULL;

		if (file) {
			fseek(file, 0, SEEK_END);
			unsigned int size = ftell(file);
			fseek(file, 0, SEEK_SET);

			if((buffer = SDL_malloc(size)) && fread(buffer, size, 1, file)) {
				// Nice lil hack :P
			}

			fclose(file);
		}

		return buffer;
	}
}
