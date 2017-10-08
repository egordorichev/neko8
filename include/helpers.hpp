#include <string.h>

namespace helper {
	char *concat(const char *w1, const char *w2) {
		char *result = new char[strlen(w1) + strlen(w2)];
		strcpy(result, w1);
		strcat(result, w2);
		return result;
	}
}