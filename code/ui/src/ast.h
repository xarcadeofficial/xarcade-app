#define AST_LIST \
	X(expr_concat) \
	X(expr_isequal) \
	X(expr_notequal) \
	X(expr_plusequal) \
	X(expr_dotequal) \
	X(expr_val) \
	X(expr_plus) \
	X(val_object) \
	X(val_array) \
	X(val_str) \
	X(val_int) \
	X(val_id) \
	X(val_id_native) \
	X(val_id_dot) \
	X(val_id_func) \
	X(val_expr) \
	X(val_arr_idx) \
	X(val_null) \
	X(val_true) \
	X(val_false) \
	X(val_call_native) \
	X(val_mcall_native) \
	X(val_field_native) \
	X(val_call) \

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

struct Ast_val_null : Ast_val {
};

struct Ast_val_true : Ast_val {
};

struct Ast_val_false : Ast_val {
};

struct Ast_val_int : Ast_val {
	int val;
};

struct Ast_val_id : Ast_val {
	size_t len;
	char *str;
};

struct Ast_val_id_native : Ast_val {
	size_t len;
	char *str;
};

struct Ast_val_id_dot : Ast_val {
	size_t len;
	char *str;
};

struct Ast_val_id_func : Ast_val {
	size_t len;
	char *str;
};

struct Ast_val_call_native : Ast_val {
	struct Ast_val_id_native *func;
	struct Ast_call_args *args;
};

struct Ast_val_field_native : Ast_val {
	struct Ast_val *val;
	struct Ast_val_id_dot *field;
};

struct Ast_val_mcall_native : Ast_val {
	struct Ast_val *val;
	struct Ast_val_id_dot *func;
	struct Ast_call_args *args;
};

struct Ast_val_call : Ast_val {
	struct Ast_val_id_func *func;
	struct Ast_call_args *args;
};

struct Ast_val_expr : Ast_val {
	struct Ast_expr *expr;
};

struct Ast_val_object : Ast_val {
	int count;
	struct Ast_val_object_item *last;
};

struct Ast_val_object_item {
	size_t key_len;
	char *key_str;
	struct Ast_expr *expr;
	struct Ast_val_object_item *prev;
};

struct Ast_val_array : Ast_val {
};

struct Ast_val_arr_idx : Ast_val {
	struct Ast_val *arr;
	struct Ast_expr *idx;
};

struct Ast_expr_val : Ast_expr {
	struct Ast_val *val;
};

struct Ast_call_args : Ast_expr {
	struct Ast_expr *expr;
	int c;
};

struct Ast_expr_concat : Ast_expr {
	struct Ast_val *val;
	int c;
};

struct Ast_expr_plus : Ast_expr {
	struct Ast_val *val;
	int c;
};

struct Ast_expr_isequal : Ast_expr {
	struct Ast_val *left, *right;
};

struct Ast_expr_notequal : Ast_expr {
	struct Ast_val *left, *right;
};

struct Ast_expr_plusequal : Ast_expr {
	struct Ast_val *left, *right;
};

struct Ast_expr_dotequal : Ast_expr {
	struct Ast_val *left, *right;
};

enum {
#define X(name) AST_##name,
AST_LIST
#undef X
};

