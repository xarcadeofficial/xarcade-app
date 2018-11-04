#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

int main(int argc, char **argv) {
	FILE *out = fopen(argv[1], "wb");
	char *strv[1024];
	int strl[1024];
	int strc = 0;
	int mask = 1 + 4 + 16;
	for(int i = 2; i < argc; i ++) {
		char *in;
		{
			FILE *f = fopen(argv[i], "rb");
			fseek(f, 0, SEEK_END);
			size_t len = ftell(f);
			in = (char*)malloc(len + 1);
			fseek(f, 0, SEEK_SET);
			fread(in, 1, len, f);
			in[len] = 0;
			fclose(f);
		}
		while(true) {
			auto c = *(in ++);
			if(c == 0) {
				break;
			} else if(c == ':' && isalnum(in[0])) {
				char str[128];
				int l = 1;
				str[0] = in[0];
				while(true) {
					c = *(++ in);
					if(isalnum(c) || c == '_' || c == '-') {
						str[l ++] = c;
					} else {
						break;
					}
				}
				if(c == '(') {
					if(in[1] == ':' && in[2] == ')') {
						in += 3;
					}
					str[l ++] = '(';
				}
				str[l] = 0;
				int i;
				for(i = strc - 1; i >= 0; i --) {
					if(strl[i] == l && memcmp(strv[i], str, l) == 0) {
						break;
					}
				}
				if(i == -1) {
					strl[strc] = l;
					auto s = strv[strc] = (char*)malloc(l + 1);
					memcpy(s, str, l + 1);
					fprintf(out, "X%dX", strc ^ mask);
					strc ++;
				} else {
					fprintf(out, "X%dX", i ^ mask);
				}
			} else {
				fputc(c, out);
			}
		}
	}
	fclose(out);
	return 0;
}
