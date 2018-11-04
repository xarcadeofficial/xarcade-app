%{
#include <stdio.h>
#include "ast.h"

enum {
TYPE_STR,
TYPE_INT,
TYPE_BOOL,
TYPE_FLOAT,
TYPE_OBJECT,
TYPE_ARRAY,
};

extern FILE *outfile;

int yyerror(const char *s);
int yylex();
char *val_string(size_t *len);
int val_int();

void Ast_print_val(Ast_val *, FILE*);
void Ast_print_expr(Ast_expr *, FILE*);
%}

%union{
	void *ptr;
	int int_val;
	struct {
		size_t len;
		char *str;
	} str;
	struct {
		int count;
		struct Ast_val_object_item *last;
	} val_object_items;
}

%start input

%token <int_val> T_lcbrace T_rcbrace T_rcbrace_lspace T_rangle T_tag T_attr
%token <int_bal> T_comma_rspace T_scolon_rspace
%token <int_val> T_space T_dot_space T_lparen T_rparen T_style
%token <int_val> T_lcbrace_if T_lcbrace_echo T_lcbrace_each T_lcbrace_map T_lcbrace_else T_lcbrace_return
%token <int_val> T_plus
%token <int_val> T_null T_true T_false
%token <int_val> T_str T_int T_bool T_float T_object T_array
%token <int_val> T_lbracket T_rbracket T_rangle_rcbrace
%token <int_val> T_equal_space T_isequal_space T_notequal_space T_dotequal_space T_plusequal_space T_plus_space
%token <int_val> T_lit_str T_lit_int T_id_func T_id T_id_native T_id_dot
%type <ptr> val val_null val_true val_false val_str val_int val_id val_id_dot val_id_func val_id_native val_only val_or_expr val_arr_idx val_object val_array val_object_item 
%type <val_object_items> val_object_items val_object_items_
%type <ptr> val_call val_call_native val_mcall_native val_field_native
%type <ptr> expr expr_concat expr_isequal expr_notequal expr_plusequal expr_or_val expr_dotequal expr_plus
%type <ptr> stmt_concat stmt_plus stmt_val_vals val_call_args val_call_args_
%type <int_val> type
%type <str> attr tag style

%%

input: stmts;

stmts: stmts_ | T_space stmts_;
stmts_: stmts_scolon | stmts_rcbrace T_space;

stmts_scolon: stmt_scolon T_scolon_rspace | stmts_scolon stmt_scolon T_scolon_rspace | stmts_rcbrace T_space stmt_scolon T_scolon_rspace;
stmts_rcbrace: stmt_rcbrace | stmts_scolon stmt_rcbrace | stmts_rcbrace T_space stmt_rcbrace;

stmt_rcbrace: stmt_tag | stmt_func | stmt_if | stmt_echo | stmt_return | stmt_each | stmt_map | stmt_else;

stmt_scolon: stmt_attr | stmt_style/* | stmt_expr*/ | stmt_val | stmt_concat | stmt_plus | stmt_str | stmt_set | stmt_let;

style: T_style {
$$.str = val_string(&$$.len);
};

stmt_concat: val T_dotequal_space val {
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, " += ");
Ast_print_val((Ast_val*)$3, outfile);
fprintf(outfile, ";\n");
$$ = $1;
} | stmt_concat T_dot_space val {
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, " += ");
Ast_print_val((Ast_val*)$3, outfile);
fprintf(outfile, ";\n");
$$ = $1;
};

stmt_plus: val T_plusequal_space val {
auto val2 = (Ast_val*)$3;
if(val2->type == AST_val_str) {
	yyerror("please use concatenate operator '.' on strings");
	exit(1);
}
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, " += ");
Ast_print_val(val2, outfile);
fprintf(outfile, ";\n");
$$ = $1;
} | stmt_plus T_plus_space val {
auto val2 = (Ast_val*)$3;
if(val2->type == AST_val_str) {
	yyerror("please use concatenate operator '.' on strings");
	exit(1);
}
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, " += ");
Ast_print_val(val2, outfile);
fprintf(outfile, ";\n");
$$ = $1;
};

stmt_style: style expr_or_val {
fprintf(outfile, ":`fw-style`(\"");
fwrite($1.str, 1, $1.len, outfile);
fprintf(outfile, "\", ");
Ast_print_expr((Ast_expr*)$2, outfile);
fprintf(outfile, ");\n");
};

/*
stmt_expr: expr {
auto expr = (Ast_expr*)$1;
Ast_print_expr(expr, outfile);
fprintf(outfile, ";\n");
};
*/

stmt_val_vals: val_call_native | val_mcall_native | val_call;

stmt_val: stmt_val_vals {
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, ";\n");
};

tag: T_tag {
$$.str = val_string(&$$.len);
fprintf(outfile, ":`fw-tag-open`(\"");
fwrite($$.str, 1, $$.len, outfile);
fprintf(outfile, "\");\n");
};

stmt_tag_stmts: T_space stmts_scolon | T_space stmts_rcbrace T_space | %empty;
stmt_tag: tag stmt_tag_stmts T_rangle {
fprintf(outfile, ":`fw-tag-end`(false);\n");
} stmts_w_rcbrace {
fprintf(outfile, ":`fw-tag-close`(\"");
fwrite($1.str, 1, $1.len, outfile);
fprintf(outfile, "\");\n");
} | tag stmt_tag_stmts T_rangle_rcbrace {
fprintf(outfile, ":`fw-tag-end`(true);\n");
};

stmts_w_rcbrace: T_rcbrace | T_rcbrace_lspace | T_space stmts_scolon T_rcbrace | T_space stmts_rcbrace T_rcbrace_lspace;

stmts_w_rcbrace_nospace: T_rcbrace | stmts_scolon T_rcbrace | stmts_rcbrace T_rcbrace_lspace;

stmt_str: T_lit_str {
size_t len;
auto str = val_string(&len);
fprintf(outfile, ":`fw-echo`(\"");
fwrite(str, 1, len, outfile);
fprintf(outfile, "\");\n");
};

stmt_return: T_lcbrace_return T_space expr_or_val T_rcbrace {
fprintf(outfile, "return ");
Ast_print_expr((Ast_expr*)$3, outfile);
fprintf(outfile, ";\n");
};

stmt_let: T_plus val T_equal_space expr_or_val {
fprintf(outfile, "let ");
Ast_print_val((Ast_val*)$2, outfile);
fprintf(outfile, " = ");
Ast_print_expr((Ast_expr*)$4, outfile);
fprintf(outfile, ";\n");
};

stmt_set: val T_equal_space expr_or_val {
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, " = ");
Ast_print_expr((Ast_expr*)$3, outfile);
fprintf(outfile, ";\n");
};

stmt_echo: T_lcbrace_echo T_space stmt_echo_vals T_rcbrace;
stmt_echo_vals: val {
fprintf(outfile, ":`fw-echo`(");
Ast_print_val((Ast_val*)$1, outfile);
fprintf(outfile, ");\n");
} | stmt_echo_vals T_space val {
fprintf(outfile, ":`fw-echo`(");
Ast_print_val((Ast_val*)$3, outfile);
fprintf(outfile, ");\n");
};

stmt_func_args: %empty | stmt_func_args_ | stmt_func_args_ T_comma_rspace;
stmt_func_args_: val_id {
Ast_print_val((Ast_val*)$1, outfile);
} type | stmt_func_args_ T_comma_rspace val_id {
fprintf(outfile, ", ");
Ast_print_val((Ast_val*)$3, outfile);
} type;

stmt_func: T_lcbrace T_id_func T_lparen {
size_t len;
auto str = val_string(&len);
fprintf(outfile, "function :`");
fwrite(str, 1, len, outfile);
fprintf(outfile, "`(");
} stmt_func_args T_rparen {
fprintf(outfile, ") {\n");
} stmts_w_rcbrace {
fprintf(outfile, "}\n");
};

stmt_map: T_lcbrace_map T_space val_id T_equal_space val_or_expr T_scolon_rspace {
fprintf(outfile, "for(let ");
Ast_print_val((Ast_val*)$val_id, outfile);
fprintf(outfile, " in ");
Ast_print_val((Ast_val*)$val_or_expr, outfile);
fprintf(outfile, ") {\n");
} stmts_w_rcbrace_nospace {
fprintf(outfile, "}\n");
};

stmt_each: T_lcbrace_each T_space val_id T_equal_space val_or_expr T_scolon_rspace {
fprintf(outfile, "for(let :`v` = ");
Ast_print_val((Ast_val*)$val_or_expr, outfile);
fprintf(outfile, ", :`c` = :`v`.length, :`i` = 0; :`i` < :`c`; :`i` ++) {\nlet ");
Ast_print_val((Ast_val*)$val_id, outfile);
fprintf(outfile, " = :`v`[:`i`];\n");
} stmts_w_rcbrace_nospace {
fprintf(outfile, "}\n");
};

stmt_if: T_lcbrace_if expr_or_val T_rparen {
fprintf(outfile, "if(");
Ast_print_expr((Ast_expr*)$2, outfile);
fprintf(outfile, ") {\n");
} stmts_w_rcbrace {
fprintf(outfile, "}\n");
};

stmt_else: T_lcbrace_else T_space {
fprintf(outfile, "else {\n");
} stmts_w_rcbrace_nospace {
fprintf(outfile, "}\n");
};

attr: T_attr {
$$.str = val_string(&$$.len);
};

attr_vals: attr_val | attr_vals T_space {
fprintf(outfile, " + ");
} attr_val;

attr_val: val {
auto v = (Ast_val*)$1;
Ast_print_val(v, outfile);
} | val_id_func val_str {
auto func = (Ast_val_id_func*)$1;
auto str = (Ast_val_str*)$2;
fputs("\":`", outfile);
fwrite(func->str, 1, func->len, outfile);
fputs("`", outfile);
fwrite(str->str, 1, str->len, outfile);
fputs("\"", outfile);
};

stmt_attr: attr T_space {
fprintf(outfile, ":`fw-attr`(\"");
fwrite($1.str, 1, $1.len, outfile);
fprintf(outfile, "\", \"\" + ");
} attr_vals {
fprintf(outfile, ");\n");
};

expr: expr_concat | expr_isequal | expr_notequal | expr_plusequal | expr_dotequal | expr_plus;

expr_isequal: val T_isequal_space val {
auto ast = new Ast_expr_isequal;
ast->type = AST_expr_isequal;
ast->left = (Ast_val*)$1;
ast->right = (Ast_val*)$3;
$$ = ast;
};

expr_notequal: val T_notequal_space val {
auto ast = new Ast_expr_notequal;
ast->type = AST_expr_notequal;
ast->left = (Ast_val*)$1;
ast->right = (Ast_val*)$3;
$$ = ast;
};

expr_plusequal: val T_plusequal_space val {
auto ast = new Ast_expr_plusequal;
ast->type = AST_expr_plusequal;
ast->left = (Ast_val*)$1;
ast->right = (Ast_val*)$3;
$$ = ast;
};

expr_dotequal: val T_dotequal_space val {
auto ast = new Ast_expr_dotequal;
ast->type = AST_expr_dotequal;
ast->left = (Ast_val*)$1;
ast->right = (Ast_val*)$3;
$$ = ast;
};

expr_concat: val T_dot_space val {
auto ast = new Ast_expr_concat;
ast->type = AST_expr_concat;
auto val1 = (Ast_val*)$1;
val1->val_data = nullptr;
auto val2 = (Ast_val*)$3;
val2->val_data = $1;
ast->val = val2;
ast->c = 2;
$$ = ast;
} | expr_concat T_dot_space val {
auto ast = (Ast_expr_concat*)$1;
auto val2 = (Ast_val*)$3;
val2->val_data = ast->val;
ast->val = val2;
ast->c ++;
$$ = ast;
};

expr_plus: val T_plus_space val {
auto val1 = (Ast_val*)$1;
auto val2 = (Ast_val*)$3;
if(val1->type == AST_val_str || val2->type == AST_val_str) {
	yyerror("please use concatenate operator '.' on strings");
	exit(1);
}
auto ast = new Ast_expr_plus;
ast->type = AST_expr_plus;
val1->val_data = nullptr;
val2->val_data = $1;
ast->val = val2;
ast->c = 2;
$$ = ast;
} | expr_plus T_plus_space val {
auto val2 = (Ast_val*)$3;
if(val2->type == AST_val_str) {
	yyerror("please use concatenate operator '.' on strings");
	exit(1);
}
auto ast = (Ast_expr_plus*)$1;
val2->val_data = ast->val;
ast->val = val2;
ast->c ++;
$$ = ast;
};

val_or_expr: val | expr {
auto ast = new Ast_val_expr;
ast->type = AST_val_expr;
ast->expr = (Ast_expr*)$1;
$$ = ast;
};

expr_or_val: expr | val {
auto ast = new Ast_expr_val;
ast->type = AST_expr_val;
ast->val = (Ast_val*)$1;
$$ = ast;
};

val_only: val_id | val_id_native | val_str | val_int | val_array | val_object | val_arr_idx | val_null | val_true | val_false | val_call_native | val_mcall_native | val_call | val_field_native;

val_call_args: %empty {
$$ = nullptr;
} | val_call_args_ | val_call_args_ T_comma_rspace;
val_call_args_: expr_or_val {
auto ast = new Ast_call_args;
ast->type = AST_expr_concat;
auto val1 = (Ast_expr*)$1;
val1->expr_data = nullptr;
ast->expr = val1;
ast->c = 1;
$$ = ast;
} | val_call_args_ T_comma_rspace expr_or_val {
auto ast = (Ast_call_args*)$1;
auto val2 = (Ast_expr*)$3;
val2->expr_data = ast->expr;
ast->expr = val2;
ast->c ++;
$$ = ast;
};
/*
expr_concat: val T_dot_space val {
auto ast = new Ast_expr_concat;
ast->type = AST_expr_concat;
auto val1 = (Ast_val*)$1;
val1->val_data = nullptr;
auto val2 = (Ast_val*)$3;
val2->val_data = $1;
ast->val = val2;
ast->c = 2;
$$ = ast;
} | expr_concat T_dot_space val {
auto ast = (Ast_expr_concat*)$1;
auto val2 = (Ast_val*)$3;
val2->val_data = ast->val;
ast->val = val2;
ast->c ++;
$$ = ast;
};
*/

val_call_native: val_id_native T_lparen val_call_args T_rparen {
auto ast = new Ast_val_call_native;
ast->type = AST_val_call_native;
ast->func = (Ast_val_id_native*)$1;
ast->args = (Ast_call_args*)$3;
$$ = ast;
};

val_call: val_id_func T_lparen val_call_args T_rparen {
auto ast = new Ast_val_call;
ast->type = AST_val_call;
ast->func = (Ast_val_id_func*)$1;
$$ = ast;
};

val_mcall_native: val val_id_dot T_lparen val_call_args T_rparen {
auto ast = new Ast_val_mcall_native;
ast->type = AST_val_mcall_native;
ast->val = (Ast_val*)$1;
ast->func = (Ast_val_id_dot*)$2;
ast->args = (Ast_call_args*)$4;
$$ = ast;
};

val_field_native: val val_id_native {
auto ast = new Ast_val_field_native;
ast->type = AST_val_field_native;
ast->val = (Ast_val*)$1;
ast->field = (Ast_val_id_dot*)$2;
$$ = ast;
};

type: T_str {
	$$ = TYPE_STR;
} | T_int {
	$$ = TYPE_INT;
} | T_bool {
	$$ = TYPE_BOOL;
} | T_float {
	$$ = TYPE_FLOAT;
} | T_object {
	$$ = TYPE_OBJECT;
} | T_array {
	$$ = TYPE_ARRAY;
};

val_array: T_array T_lparen T_rparen {
auto ast = new Ast_val_array;
ast->type = AST_val_array;
$$ = ast;
};

val_object_items: %empty {
	$$.count = 0;
	$$.last = nullptr;
} | val_object_items_ | val_object_items_ T_comma_rspace;
val_object_items_: val_object_item {
	auto item = (Ast_val_object_item*)$1;
	item->prev = nullptr;
	$$.count = 1;
	$$.last = item;
} | val_object_items_ T_comma_rspace val_object_item {
	auto item = (Ast_val_object_item*)$3;
	item->prev = $1.last;
	$$.count = $1.count + 1;
	$$.last = item;
};

val_object_item: style expr_or_val {
auto item = new Ast_val_object_item;
item->key_len = $1.len;
item->key_str = $1.str;
item->expr = (Ast_expr*)$2;
$$ = item;
};

val_object: T_object T_lparen val_object_items T_rparen {
auto ast = new Ast_val_object;
ast->type = AST_val_object;
ast->count = $3.count;
ast->last = $3.last;
$$ = ast;
};

val_arr_idx: val T_lbracket expr_or_val T_rbracket {
auto ast = new Ast_val_arr_idx;
ast->type = AST_val_arr_idx;
ast->arr = (Ast_val*)$val;
ast->idx = (Ast_expr*)$expr_or_val;
$$ = ast;
};

val: val_only | T_lparen expr T_rparen {
auto ast = new Ast_val_expr;
ast->type = AST_val_expr;
ast->expr = (Ast_expr*)$2;
$$ = ast;
};

val_id: T_id {
auto ast = new Ast_val_id;
ast->type = AST_val_id;
ast->str = val_string(&ast->len);
$$ = ast;
};

val_id_native: T_id_native {
auto ast = new Ast_val_id_native;
ast->type = AST_val_id_native;
ast->str = val_string(&ast->len);
$$ = ast;
};

val_id_func: T_id_func {
auto ast = new Ast_val_id_func;
ast->type = AST_val_id_func;
ast->str = val_string(&ast->len);
$$ = ast;
};

val_id_dot: T_id_dot {
auto ast = new Ast_val_id_dot;
ast->type = AST_val_id_dot;
ast->str = val_string(&ast->len);
$$ = ast;
};

val_str: T_lit_str {
auto ast = new Ast_val_str;
ast->type = AST_val_str;
ast->str = val_string(&ast->len);
$$ = ast;
};

val_int: T_lit_int {
auto ast = new Ast_val_int;
ast->type = AST_val_int;
ast->val = val_int();
$$ = ast;
};

val_null: T_null {
auto ast = new Ast_val_null;
ast->type = AST_val_null;
$$ = ast;
};

val_true: T_true {
auto ast = new Ast_val_true;
ast->type = AST_val_true;
$$ = ast;
};

val_false: T_false {
auto ast = new Ast_val_false;
ast->type = AST_val_false;
$$ = ast;
};

%%

void Ast_print_expr(Ast_expr *expr, FILE *out) {
	switch(expr->type) {
	case AST_expr_plus: {
		auto e = (Ast_expr_plus*)expr;
		short c = e->c;
		short i = c;
		Ast_val *vv[c];
		auto v = e->val;
		do {
			vv[-- i] = v;
			v = (Ast_val*)v->val_data;
		} while(v);
		Ast_print_val(vv[0], out);
		for(i = 1; i < c; i ++) {
			fputs(" + ", out);
			Ast_print_val(vv[i], out);
		}
		break;
	}
	case AST_expr_concat: {
		auto e = (Ast_expr_concat*)expr;
		short c = e->c;
		short i = c;
		Ast_val *vv[c];
		auto v = e->val;
		do {
			vv[-- i] = v;
			v = (Ast_val*)v->val_data;
		} while(v);
		fputs(":`fw-concat`(", out);
		Ast_print_val(vv[0], out);
		for(i = 1; i < c; i ++) {
			fputs(", ", out);
			Ast_print_val(vv[i], out);
		}
		fputs(")", out);
		break;
	}
	case AST_expr_val: {
		auto e = (Ast_expr_val*)expr;
		Ast_print_val(e->val, out);
		break;
	}
	case AST_expr_isequal: {
		auto e = (Ast_expr_isequal*)expr;
		Ast_print_val(e->left, out);
		fputs(" == ", out);
		Ast_print_val(e->right, out);
		break;
	}
	case AST_expr_notequal: {
		auto e = (Ast_expr_notequal*)expr;
		Ast_print_val(e->left, out);
		fputs(" != ", out);
		Ast_print_val(e->right, out);
		break;
	}
	case AST_expr_plusequal: {
		auto e = (Ast_expr_notequal*)expr;
		Ast_print_val(e->left, out);
		fputs(" += ", out);
		Ast_print_val(e->right, out);
		break;
	}
	}
}

void Ast_print_val(Ast_val *val, FILE *out) {
	switch(val->type) {
	case AST_val_field_native: {
		auto v = (Ast_val_field_native*)val;
		Ast_print_val(v->val, out);
		fputs(".", out);
		Ast_print_val(v->field, out);
		break;
	}
	case AST_val_mcall_native: {
		auto v = (Ast_val_mcall_native*)val;
		Ast_print_val(v->val, out);
		Ast_print_val(v->func, out);
		if(v->args == nullptr) {
			fputs("()", out);
		} else {
			auto e = v->args;
			short c = e->c;
			short i = c;
			Ast_expr *vv[c];
			auto v = e->expr;
			do {
				vv[-- i] = v;
				v = (Ast_expr*)v->expr_data;
			} while(v);
			fputs("(", out);
			Ast_print_expr(vv[0], out);
			for(i = 1; i < c; i ++) {
				fputs(", ", out);
				Ast_print_expr(vv[i], out);
			}
			fputs(")", out);
		}
		break;
	}
	case AST_val_call_native: {
		auto v = (Ast_val_call_native*)val;
		Ast_print_val(v->func, out);
		if(v->args == nullptr) {
			fputs("()", out);
		} else {
			auto e = v->args;
			short c = e->c;
			short i = c;
			Ast_expr *vv[c];
			auto v = e->expr;
			do {
				vv[-- i] = v;
				v = (Ast_expr*)v->expr_data;
			} while(v);
			fputs("(", out);
			Ast_print_expr(vv[0], out);
			for(i = 1; i < c; i ++) {
				fputs(", ", out);
				Ast_print_expr(vv[i], out);
			}
			fputs(")", out);
		}
		break;
	}
	case AST_val_call: {
		auto v = (Ast_val_call*)val;
		Ast_print_val(v->func, out);
		if(v->args == nullptr) {
			fputs("()", out);
		} else {
			auto e = v->args;
			short c = e->c;
			short i = c;
			Ast_expr *vv[c];
			auto v = e->expr;
			do {
				vv[-- i] = v;
				v = (Ast_expr*)v->expr_data;
			} while(v);
			fputs("(", out);
			Ast_print_expr(vv[0], out);
			for(i = 1; i < c; i ++) {
				fputs(", ", out);
				Ast_print_expr(vv[i], out);
			}
			fputs(")", out);
		}
		break;
	}
	case AST_val_id_dot: {
		auto v = (Ast_val_id*)val;
		fputs(".", out);
		fwrite(v->str, 1, v->len, out);
		break;
	}
	case AST_val_id_func: {
		auto v = (Ast_val_id*)val;
		fputs(":`", out);
		fwrite(v->str, 1, v->len, out);
		fputs("`", out);
		break;
	}
	case AST_val_id: {
		auto v = (Ast_val_id*)val;
		fputs(":`", out);
		fwrite(v->str, 1, v->len, out);
		fputs("`", out);
		break;
	}
	case AST_val_id_native: {
		auto v = (Ast_val_id_native*)val;
		fwrite(v->str, 1, v->len, out);
		break;
	}
	case AST_val_expr: {
		auto v = (Ast_val_expr*)val;
		fputs("(", out);
		Ast_print_expr(v->expr, out);
		fputs(")", out);
		break;
	}
	case AST_val_str: {
		auto v = (Ast_val_str*)val;
		fputs("\"", out);
		fwrite(v->str, 1, v->len, out);
		fputs("\"", out);
		break;
	}
	case AST_val_int: {
		auto v = (Ast_val_int*)val;
		fprintf(out, "%d", v->val);
		break;
	}
	case AST_val_arr_idx: {
		auto v = (Ast_val_arr_idx*)val;
		Ast_print_val(v->arr, outfile);
		fprintf(outfile, "[");
		Ast_print_expr(v->idx, outfile);
		fprintf(outfile, "]");
		break;
	}
	case AST_val_object: {
		auto v = (Ast_val_object*)val;
		if(v->last == nullptr) {
			fputs("{}", out);
		} else {
			fputs("{", out);
			int ic = v->count;
			Ast_val_object_item *iv[ic];
			auto item = v->last;
			int i = 0;
			while(item) {
				iv[i ++] = item;
				item = item->prev;
			}
			for(i = 0; i < ic; i ++) {
				item = iv[i];
				fwrite(item->key_str, 1, item->key_len, outfile);
				fputs(": ", out);
				Ast_print_expr(item->expr, outfile);
			}
			fputs("}", out);
		}
		break;
	}
	case AST_val_array: {
		fputs("[]", out);
		break;
	}
	case AST_val_null: {
		fputs("null", out);
		break;
	}
	case AST_val_true: {
		fputs("true", out);
		break;
	}
	case AST_val_false: {
		fputs("false", out);
		break;
	}
	}
}
