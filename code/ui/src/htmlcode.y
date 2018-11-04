%{
#include <stdio.h>
#include "ast.h"

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
}

%start input

%token <int_val> T_lcbrace T_rcbrace T_rcbrace_lspace T_rangle T_tag T_attr T_scolon_rspace
%token <int_val> T_space T_id T_dot_space T_lparen T_rparen T_style T_lcbrace_if T_lcbrace_echo T_lcbrace_each T_lbracket T_rbracket T_rangle_rcbrace T_lcbrace_else
%token <int_val> T_equal_space T_isequal_space T_notequal_space
%token <int_val> T_str T_int
%type <ptr> val_str val_int val_id val expr val_only val_or_expr val_arr
%type <ptr> expr_concat expr_isequal expr_notequal
%type <str> attr tag style

%%

input: stmts;

stmts: stmts_ | T_space stmts_;
stmts_: stmts_scolon | stmts_rcbrace T_space;

stmts_scolon: stmt_scolon T_scolon_rspace | stmts_scolon stmt_scolon T_scolon_rspace | stmts_rcbrace T_space stmt_scolon T_scolon_rspace;
stmts_rcbrace: stmt_rcbrace | stmts_scolon stmt_rcbrace | stmts_rcbrace T_space stmt_rcbrace;

stmt_rcbrace: stmt_tag | stmt_if | stmt_echo | stmt_each | stmt_else;

stmt_scolon: stmt_attr | stmt_style | stmt_expr | stmt_str;

style: T_style {
$$.str = val_string(&$$.len);
};

stmt_style: style val_or_expr {
fprintf(stdout, ":fw-style(\"");
fwrite($1.str, 1, $1.len, stdout);
fprintf(stdout, "\", ");
Ast_print_val((Ast_val*)$2, stdout);
fprintf(stdout, ");\n");
};

stmt_expr: expr {
auto expr = (Ast_expr*)$1;
Ast_print_expr(expr, stdout);
fprintf(stdout, ";\n");
};

tag: T_tag {
$$.str = val_string(&$$.len);
fprintf(stdout, ":fw-tag-open(\"");
fwrite($$.str, 1, $$.len, stdout);
fprintf(stdout, "\");\n");
};

stmt_tag_stmts: T_space stmts_scolon | T_space stmts_rcbrace T_space | %empty;
stmt_tag: tag stmt_tag_stmts T_rangle {
fprintf(stdout, ":fw-tag-end(false);\n");
} stmts_w_rcbrace {
fprintf(stdout, ":fw-tag-close(\"");
fwrite($1.str, 1, $1.len, stdout);
fprintf(stdout, "\");\n");
} | tag stmt_tag_stmts T_rangle_rcbrace {
fprintf(stdout, ":fw-tag-end(true);\n");
};

stmts_w_rcbrace: T_rcbrace | T_rcbrace_lspace | T_space stmts_scolon T_rcbrace | T_space stmts_rcbrace T_rcbrace_lspace;

stmts_w_rcbrace_nospace: T_rcbrace | stmts_scolon T_rcbrace | stmts_rcbrace T_rcbrace_lspace;

stmt_str: T_str {
size_t len;
auto str = val_string(&len);
fprintf(stdout, ":fw-echo(\"");
fwrite(str, 1, len, stdout);
fprintf(stdout, "\");\n");
};

stmt_echo: T_lcbrace_echo T_space stmt_echo_vals T_rcbrace;
stmt_echo_vals: val {
fprintf(stdout, ":fw-echo(");
Ast_print_val((Ast_val*)$1, stdout);
fprintf(stdout, ");\n");
} | stmt_echo_vals T_space val {
fprintf(stdout, ":fw-echo(");
Ast_print_val((Ast_val*)$3, stdout);
fprintf(stdout, ");\n");
};

stmt_each: T_lcbrace_each T_space val_id T_equal_space val_or_expr T_scolon_rspace {
fprintf(stdout, "for(let :v = ");
Ast_print_val((Ast_val*)$val_or_expr, stdout);
fprintf(stdout, ", :c = :v.length, :i = 0; :i < :c; :i ++) {\nlet ");
Ast_print_val((Ast_val*)$val_id, stdout);
fprintf(stdout, " = :v[:i];\n");
} stmts_w_rcbrace_nospace {
fprintf(stdout, "}\n");
};

stmt_if: T_lcbrace_if val_or_expr T_rparen {
fprintf(stdout, "if(");
Ast_print_val((Ast_val*)$2, stdout);
fprintf(stdout, ") {\n");
} stmts_w_rcbrace {
fprintf(stdout, "}\n");
};

stmt_else: T_lcbrace_else T_space {
fprintf(stdout, "else {\n");
} stmts_w_rcbrace_nospace {
fprintf(stdout, "}\n");
};

attr: T_attr {
$$.str = val_string(&$$.len);
};

stmt_attr: attr T_space val_or_expr {
fprintf(stdout, ":fw-attr(\"");
fwrite($1.str, 1, $1.len, stdout);
fprintf(stdout, "\", ");
Ast_print_val((Ast_val*)$3, stdout);
fprintf(stdout, ");\n");
};

expr: expr_concat | expr_isequal | expr_notequal;

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

val_or_expr: val | expr {
auto ast = new Ast_val_expr;
ast->type = AST_val_expr;
ast->expr = (Ast_expr*)$1;
$$ = ast;
};

val_only: val_id | val_str | val_int | val_arr;

val_arr: val T_lbracket val_or_expr T_rbracket {
auto ast = new Ast_val_arr;
ast->type = AST_val_arr;
ast->arr = (Ast_val*)$val;
ast->idx = (Ast_val*)$val_or_expr;
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

val_str: T_str {
auto ast = new Ast_val_str;
ast->type = AST_val_str;
ast->str = val_string(&ast->len);
$$ = ast;
};

val_int: T_int {
auto ast = new Ast_val_int;
ast->type = AST_val_int;
ast->val = val_int();
$$ = ast;
};

%%

void Ast_print_expr(Ast_expr *expr, FILE *out) {
	switch(expr->type) {
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
		fputs(":fw-concat(", out);
		Ast_print_val(vv[0], out);
		for(i = 1; i < c; i ++) {
			fputs(", ", out);
			Ast_print_val(vv[i], out);
		}
		fputs(")", out);
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
	}
}

void Ast_print_val(Ast_val *val, FILE *out) {
	switch(val->type) {
	case AST_val_id: {
		auto v = (Ast_val_id*)val;
		fputs(":", out);
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
	case AST_val_arr: {
		auto v = (Ast_val_arr*)val;
		Ast_print_val(v->arr, stdout);
		fprintf(stdout, "[");
		Ast_print_val(v->idx, stdout);
		fprintf(stdout, "]");
		break;
	}
	}
}

int yyerror(const char *s)
{
	fprintf(stderr, "parse err\n");
	exit(1);
}
