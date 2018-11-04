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
X(id_func) \
X(id_native) \
X(id_dot) \
X(str) \
X(int) \
X(bool) \
X(float) \
X(lit_str) \
X(lit_int) \
X(style) \
X(lcbrace_if) \
X(lcbrace_echo) \
X(lcbrace_each) \
X(lcbrace_map) \
X(equal_space) \
X(isequal_space) \
X(notequal_space) \
X(plusequal_space) \
X(plus_space) \
X(dotequal_space) \
X(lbracket) \
X(rbracket) \
X(rangle_rcbrace) \
X(lcbrace_else) \
X(lcbrace_return) \
X(plus) \
X(object) \
X(array) \
X(null) \
X(true) \
X(false) \
X(comma_rspace) \

#define X(name) OUT_##name,
enum {
OUT_EOF,
TOKENS
};
#undef X

int current_line;
int current_col;

char *input;
char *values;
int yylex2() {
	int line = *(input ++);
	int col = *(input ++);
	if(line == 0) {
		current_col += col;
	} else {
		current_line += line;
		current_col = col;
	}
	switch(*input ++) {
	#define X(name) case OUT_##name: return T_##name;
	TOKENS
	}
	return 0;
}

int yyerror(const char *s)
{
	fprintf(stderr, "%d:%d: %s\n", current_line, current_col, s);
	exit(1);
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

FILE *outfile;

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
		YYCURSOR = (char*)malloc(len + 16);
		fseek(f, 0, SEEK_SET);
		fread(YYCURSOR, 1, len, f);
		memset(YYCURSOR + len, 0, 16);
		fclose(f);
	}
	char *YYMARKER;
	int line_old = 0;
	int col_old = 0;
	int line = 1;
	int col = 1;
	char *YYBEGIN = YYCURSOR;
	while(true) {
		// scan for begin to cursor
		{
			while(YYBEGIN < YYCURSOR) {
				if(*(YYBEGIN ++) == '\n') {
					line ++;
					col = 1;
				} else {
					col ++;
				}
			}
			if(line == line_old) {
				*(output ++) = 0;
				*(output ++) = col - col_old;
			} else {
				*(output ++) = line - line_old;
				*(output ++) = col;
			}
			line_old = line;
			col_old = col;
		}
	/*!re2c
re2c:define:YYCTYPE = char;
re2c:yyfill:enable = 0;

space = (" " | "\t" | "\n")+;
"\x00" { goto jmp_end; }
"{<" [a-z]+ { goto jmp_tag_open; }
space "}" { goto jmp_rcbrace_lspace; }
"{" { goto jmp_lcbrace; }
"}" { goto jmp_rcbrace; }
[a-zA-Z0-9_-]+ "=" { goto jmp_attr; }
[a-zA-Z][a-zA-Z0-9_-]* { goto jmp_id; }
":" [a-zA-Z0-9][a-zA-Z0-9_-]* { goto jmp_id_func; }
"{if(" { goto jmp_lcbrace_if; }
"{echo" { goto jmp_lcbrace_echo; }
"{each" { goto jmp_lcbrace_each; }
"{map" { goto jmp_lcbrace_map; }
"{else" { goto jmp_lcbrace_else; }
"{return" { goto jmp_lcbrace_return; }
space { goto jmp_space; }
space "." space { goto jmp_dot_space; }
";" space { goto jmp_scolon_rspace; }
">" { goto jmp_rangle; }
">}" { goto jmp_rangle_rcbrace; }
"(" { goto jmp_lparen; }
")" { goto jmp_rparen; }
"+" { goto jmp_plus; }
"\"" { goto jmp_lit_str; }
"`object" { goto jmp_object; }
"`array" { goto jmp_array; }
"`null" { goto jmp_null; }
"`true" { goto jmp_true; }
"`false" { goto jmp_false; }
"`str" { goto jmp_str; }
"`int" { goto jmp_int; }
"`bool" { goto jmp_bool; }
"`float" { goto jmp_float; }
[a-z-] [a-zA-Z0-9_-]* ": " { goto jmp_style; }
space "=" space { goto jmp_equal_space; }
space "==" space { goto jmp_isequal_space; }
space "!=" space { goto jmp_notequal_space; }
space "+=" space { goto jmp_plusequal_space; }
space ".=" space { goto jmp_dotequal_space; }
space "+" space { goto jmp_plus_space; }
"[" { goto jmp_lbracket; }
"]" { goto jmp_rbracket; }
"," space { goto jmp_comma_rspace; }
("0" | [1-9] [0-9]*) { goto jmp_lit_int; }
"~" [a-zA-Z_]+ { goto jmp_id_native; }
"." [a-zA-Z_]+ { goto jmp_id_dot; }
* { goto jmp_err; }
	 */
jmp_end:
		break;

jmp_comma_rspace: { OUT(comma_rspace); continue; }

jmp_object: { OUT(object); continue; }
jmp_array: { OUT(array); continue; }
jmp_str: { OUT(str); continue; }
jmp_int: { OUT(int); continue; }
jmp_bool: { OUT(bool); continue; }
jmp_float: { OUT(float); continue; }

jmp_null: { OUT(null); continue; }
jmp_true: { OUT(true); continue; }
jmp_false: { OUT(false); continue; }
jmp_plus: { OUT(plus); continue; }

jmp_rangle_rcbrace: { OUT(rangle_rcbrace); continue; }
jmp_lbracket: { OUT(lbracket); continue; }
jmp_rbracket: { OUT(rbracket); continue; }
jmp_equal_space: { OUT(equal_space); continue; }
jmp_lit_int:
		{
			OUT(lit_int);
			*(outval ++) = YYBEGIN[0] - '0';
			continue;
		}

jmp_plus_space: { OUT(plus_space); continue; }

jmp_isequal_space: { OUT(isequal_space); continue; }
jmp_notequal_space: { OUT(notequal_space); continue; }
jmp_plusequal_space: { OUT(plusequal_space); continue; }
jmp_dotequal_space: { OUT(dotequal_space); continue; }

jmp_lcbrace: { OUT(lcbrace); continue; }
jmp_lcbrace_if: { OUT(lcbrace_if); continue; }
jmp_lcbrace_echo: { OUT(lcbrace_echo); continue; }
jmp_lcbrace_return: { OUT(lcbrace_return); continue; }
jmp_lcbrace_else: { OUT(lcbrace_else); continue; }
jmp_lcbrace_each: { OUT(lcbrace_each); continue; }
jmp_lcbrace_map: { OUT(lcbrace_map); continue; }

jmp_style:
		{
			OUT(style);
			VALstring(YYBEGIN, len, YYCURSOR - YYBEGIN - 2);
			continue;
		}
jmp_lit_str:
		{
			OUT(lit_str);
			auto outlen = outval ++;
			while(true) {
				auto c = *(YYCURSOR ++);
				// fprintf(stderr, "%c\n", c);
				if(c == '\0') {
					goto jmp_err;
				} else if(c == '"') {
					break;
				} else if(c == '\\') {
					*(outval ++) = c;
					*(outval ++) = *(YYCURSOR ++);
				} else {
					*(outval ++) = c;
				}
			}
			*(outlen) = YYCURSOR - YYBEGIN - 2;
			// fprintf(stderr, "break %c\n", *YYCURSOR);
			continue;
		}
jmp_id_func:
		{
			OUT(id_func);
			VALstring(YYBEGIN + 1, len, YYCURSOR - YYBEGIN - 1);
			continue;
		}
jmp_id_native:
		{
			OUT(id_native);
			VALstring(YYBEGIN + 1, len, YYCURSOR - YYBEGIN - 1);
			continue;
		}
jmp_id_dot:
		{
			OUT(id_dot);
			VALstring(YYBEGIN + 1, len, YYCURSOR - YYBEGIN - 1);
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
	outfile = fopen(argv[2], "wb");
	yyparse();
	fclose(outfile);
	return 0;

jmp_err:
	fprintf(stderr, "%d:%d: lex err\n", line, col);
	return 1;
}
