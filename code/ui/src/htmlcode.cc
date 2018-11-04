#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "htmlcode.tab.hh"

#define TOKENS \
X(lcbrace) \
X(rcbrace) \
X(rcbrace_lspace) \
X(rangle) \
X(tag) \
X(attr) \
X(scolon_rspace) \
X(space) \
X(dot_space) \
X(lparen) \
X(rparen) \
X(id) \
X(str) \
X(int) \
X(style) \
X(lcbrace_if) \
X(lcbrace_echo) \
X(lcbrace_each) \
X(equal_space) \
X(isequal_space) \
X(notequal_space) \
X(lbracket) \
X(rbracket) \
X(rangle_rcbrace) \
X(lcbrace_else) \

#define X(name) OUT_##name,
enum {
OUT_EOF,
TOKENS
};
#undef X

char *input;
char *values;
int yylex2() {
	switch(*input ++) {
	#define X(name) case OUT_##name: return T_##name;
	TOKENS
	}
	return 0;
}

char *val_string(size_t *outlen) {
	auto len = *outlen = *(values ++);
	auto ret = values;
	values = values + len;
	return ret;
}

int val_int() {
	return *(values ++);
}

int yylex() {
	int r = yylex2();
	return r;
}

#define OUT(name) *(output ++) = OUT_##name;
#define VALstring(YYBEGIN, len, lenval) \
		size_t len = lenval; \
		*(outval ++) = len; \
		memcpy(outval, YYBEGIN, len); \
		outval += len; \

int main(int argc, char **argv) {
	auto output = (char*)malloc(1024 * 1024);
	auto outval = (char*)malloc(1024 * 1024);
	values = outval;
	input = output;
	char *YYCURSOR;
	{
		FILE *f = fopen(argv[1], "rb");
		fseek(f, 0, SEEK_END);
		size_t len = ftell(f);
		YYCURSOR = (char*)malloc(len + 1);
		fseek(f, 0, SEEK_SET);
		fread(YYCURSOR, 1, len, f);
		YYCURSOR[len] = 0;
		fclose(f);
	}
	char *YYMARKER;
	while(true) {
		char *YYBEGIN = YYCURSOR;
	/*!re2c
re2c:define:YYCTYPE = char;
re2c:yyfill:enable = 0;

space = (" " | "\t" | "\n")+;
"\x00" { goto jmp_end; }
"{<" [a-z]+ { goto jmp_tag_open; }
space "}" { goto jmp_rcbrace_lspace; }
"}" { goto jmp_rcbrace; }
[a-zA-Z0-9_-]+ "=" { goto jmp_attr; }
[a-zA-Z][a-zA-Z0-9_-]* { goto jmp_id; }
"{if(" { goto jmp_lcbrace_if; }
"{echo" { goto jmp_lcbrace_echo; }
"{each" { goto jmp_lcbrace_each; }
"{else" { goto jmp_lcbrace_else; }
space { goto jmp_space; }
space "." space { goto jmp_dot_space; }
";" space { goto jmp_scolon_rspace; }
">" { goto jmp_rangle; }
">}" { goto jmp_rangle_rcbrace; }
"(" { goto jmp_lparen; }
")" { goto jmp_rparen; }
"\"" [^"]* "\"" { goto jmp_str; }
[a-z-] [a-zA-Z0-9_-]* ": " { goto jmp_style; }
space "=" space { goto jmp_equal_space; }
space "==" space { goto jmp_isequal_space; }
space "!=" space { goto jmp_notequal_space; }
"[" { goto jmp_lbracket; }
"]" { goto jmp_rbracket; }
("0" | [1-9] [0-9]*) { goto jmp_int; }
* { goto jmp_err; }
	 */
jmp_end:
		break;
jmp_rangle_rcbrace:
		{
			OUT(rangle_rcbrace);
			continue;
		}
jmp_lbracket:
		{
			OUT(lbracket);
			continue;
		}
jmp_rbracket:
		{
			OUT(rbracket);
			continue;
		}
jmp_equal_space:
		{
			OUT(equal_space);
			continue;
		}
jmp_int:
		{
			OUT(int);
			*(outval ++) = YYBEGIN[0] - '0';
			continue;
		}
jmp_isequal_space:
		{
			OUT(isequal_space);
			continue;
		}
jmp_notequal_space:
		{
			OUT(notequal_space);
			continue;
		}
jmp_lcbrace_if:
		{
			OUT(lcbrace_if);
			continue;
		}
jmp_lcbrace_echo:
		{
			OUT(lcbrace_echo);
			continue;
		}
jmp_lcbrace_else:
		{
			OUT(lcbrace_else);
			continue;
		}
jmp_lcbrace_each:
		{
			OUT(lcbrace_each);
			continue;
		}
jmp_style:
		{
			OUT(style);
			VALstring(YYBEGIN, len, YYCURSOR - YYBEGIN - 2);
			continue;
		}
jmp_str:
		{
			OUT(str);
			VALstring(YYBEGIN + 1, len, YYCURSOR - YYBEGIN - 2);
			continue;
		}
jmp_id:
		{
			OUT(id);
			VALstring(YYBEGIN, len, YYCURSOR - YYBEGIN);
			continue;
		}
jmp_lparen:
		OUT(lparen);
		continue;
jmp_rparen:
		OUT(rparen);
		continue;
jmp_dot_space:
		OUT(dot_space);
		continue;
jmp_space:
		OUT(space);
		continue;
jmp_scolon_rspace:
		OUT(scolon_rspace);
		continue;
jmp_rangle:
		OUT(rangle);
		continue;
jmp_attr:
		{
			OUT(attr);
			VALstring(YYBEGIN, len, YYCURSOR - YYBEGIN - 1);
			continue;
		}
jmp_tag_open:
		{
			OUT(tag);
			VALstring(YYBEGIN + 2, len, YYCURSOR - YYBEGIN - 2);
			continue;
		}
jmp_rcbrace_lspace:
		OUT(rcbrace_lspace);
		continue;
jmp_rcbrace:
		OUT(rcbrace);
		continue;
	}
	*(output ++) = 0;
	yyparse();
	return 0;

jmp_err:
	fprintf(stdout, "lex err\n");
	return 1;
}
