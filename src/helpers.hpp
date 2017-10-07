#include <string.h>

namespace helper{

	char* concat(char* w1, char* w2){
		char* result = w1;
		strcat(result, w2);
		return result;
	}

}