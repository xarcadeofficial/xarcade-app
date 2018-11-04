#define AST_LIST \
	X(expr_concat) \
	X(expr_isequal) \
	X(expr_notequal) \
	X(val_str) \
	X(val_int) \
	X(val_id) \
	X(val_expr) \
	X(val_arr) \

struct Ast {
	unsigned char type;
};

struct Ast_val : Ast {
	void *val_data;
	Ast_val() {
		val_data = nullptr;
	}
};

struct Ast_expr : Ast {
	void *expr_data;
	Ast_expr() {
		expr_data = nullptr;
	}
};

struct Ast_val_str : Ast_val {
	size_t len;
	char *str;
};

struct Ast_val_int : Ast_val {
	int val;
};

struct Ast_val_id : Ast_val {
	size_t len;
	char *str;
};

struct Ast_val_expr : Ast_val {
	struct Ast_expr *expr;
};

struct Ast_val_arr : Ast_val {
	struct Ast_val *arr, *idx;
};

struct Ast_expr_concat : Ast_expr {
	struct Ast_val *val;
	int c;
};

struct Ast_expr_isequal : Ast_expr {
	struct Ast_val *left, *right;
};

struct Ast_expr_notequal : Ast_expr {
	struct Ast_val *left, *right;
};

enum {
#define X(name) AST_##name,
AST_LIST
#undef X
};

