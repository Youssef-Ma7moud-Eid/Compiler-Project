%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);
extern FILE *yyin;
extern int line_num;

FILE *out;
FILE *err;
int sym[26];
int sym_declared[26];
int sym_type[26]; // 0=int, 1=float, 2=double

void write_error(const char *msg);
%}

%token VOID MAIN INT FLOAT DOUBLE PRINT IF ELSE
%token EQ NE GT LT GE LE AND OR
%token VARIABLE NUMBER FLOAT_NUM DOUBLE_NUM

%right '='
%left OR
%left AND
%left EQ NE
%left GT LT GE LE
%left '+' '-'
%left '*' '/'
%right '!' UMINUS

%%

program:
    VOID MAIN '(' ')' '{' statements '}'
    {
        fprintf(out, "\n=== Symbol Table ===\n");
        int has_vars = 0;
        for(int i = 0; i < 26; i++) {
            if(sym_declared[i]) {
                fprintf(out, "%c = %d\n", 'a' + i, sym[i]);
                has_vars = 1;
            }
        }
        if(!has_vars) fprintf(out, "No variables declared\n");
    }
;

statements:
    /* empty */
    | statements statement
;

statement:
    declaration ';'
    | init_declaration ';'
    | assignment ';'
    | print_stmt ';'
    | if_stmt
    | expression ';'
    | '{' statements '}'
;

declaration:
    INT VARIABLE 
    {
        sym[$2] = 0;
        sym_declared[$2] = 1;
        sym_type[$2] = 0;
        fprintf(out, "Declare variable %c\n", 'a' + $2);
    }
    | FLOAT VARIABLE 
    {
        sym[$2] = 0;
        sym_declared[$2] = 1;
        sym_type[$2] = 1;
        fprintf(out, "Declare variable %c (float)\n", 'a' + $2);
    }
    | DOUBLE VARIABLE 
    {
        sym[$2] = 0;
        sym_declared[$2] = 1;
        sym_type[$2] = 2;
        fprintf(out, "Declare variable %c (double)\n", 'a' + $2);
    }
;

init_declaration:
    INT VARIABLE '=' expression 
    {
        if($4 != (int)$4) {
            char msg[100];
            sprintf(msg, "Type mismatch: Cannot assign floating-point value to int variable '%c'", 'a' + $2);
            write_error(msg);
        }
        sym[$2] = (int)$4;
        sym_declared[$2] = 1;
        sym_type[$2] = 0;
        fprintf(out, "Declare and init %c = %d\n", 'a' + $2, sym[$2]);
    }
    | FLOAT VARIABLE '=' expression 
    {
        sym[$2] = $4;
        sym_declared[$2] = 1;
        sym_type[$2] = 1;
        fprintf(out, "Declare and init %c = %d (float)\n", 'a' + $2, sym[$2]);
    }
    | DOUBLE VARIABLE '=' expression 
    {
        sym[$2] = $4;
        sym_declared[$2] = 1;
        sym_type[$2] = 2;
        fprintf(out, "Declare and init %c = %d (double)\n", 'a' + $2, sym[$2]);
    }
;

assignment:
    VARIABLE '=' expression 
    {
        if(sym_declared[$1]) {
            if(sym_type[$1] == 0 && $3 != (int)$3) {
                char msg[100];
                sprintf(msg, "Type mismatch: Cannot assign floating-point value to int variable '%c'", 'a' + $1);
                write_error(msg);
            }
        }
        sym[$1] = $3;
        if(!sym_declared[$1]) {
            sym_declared[$1] = 1;
        }
        fprintf(out, "Assign %c = %d\n", 'a' + $1, $3);
    }
;

print_stmt:
    PRINT '(' expression ')' 
    {
        fprintf(out, "Print: %d\n", $3);
    }
;

if_stmt:
    simple_if
    | if_else
    | if_else_if
;

simple_if:
    IF '(' expression ')' '{' statements '}' 
    {
        fprintf(out, "If condition = %d\n", $3);
    }
;

if_else:
    IF '(' expression ')' '{' statements '}' ELSE '{' statements '}' 
    {
        fprintf(out, "If-else condition = %d\n", $3);
    }
;

if_else_if:
    IF '(' expression ')' '{' statements '}' ELSE if_stmt 
    {
        fprintf(out, "If-else-if condition = %d\n", $3);
    }
;

expression:
    NUMBER 
    { 
        $$ = $1; 
    }
    | FLOAT_NUM
    { 
        $$ = $1; 
    }
    | DOUBLE_NUM
    { 
        $$ = $1; 
    }
    | VARIABLE 
    { 
        if(!sym_declared[$1]) {
            char msg[100];
            sprintf(msg, "Variable '%c' used before declaration", 'a' + $1);
            write_error(msg);
            sym_declared[$1] = 1;
            sym[$1] = 0;
        }
        $$ = sym[$1]; 
    }
    | '!' expression 
    { 
        $$ = !$2; 
        fprintf(out, "Logical NOT: !%d = %d\n", $2, $$); 
    }
    | '-' expression %prec UMINUS
    { 
        $$ = -$2; 
        fprintf(out, "Unary minus: -%d = %d\n", $2, $$); 
    }
    | expression '+' expression 
    { 
        $$ = $1 + $3; 
        fprintf(out, "Add: %d + %d = %d\n", $1, $3, $$); 
    }
    | expression '-' expression 
    { 
        $$ = $1 - $3; 
        fprintf(out, "Sub: %d - %d = %d\n", $1, $3, $$); 
    }
    | expression '*' expression 
    { 
        $$ = $1 * $3; 
        fprintf(out, "Mul: %d * %d = %d\n", $1, $3, $$); 
    }
    | expression '/' expression 
    { 
        if($3 != 0) {
            $$ = $1 / $3;
            fprintf(out, "Div: %d / %d = %d\n", $1, $3, $$);
        } else {
            write_error("Division by zero");
            $$ = 0;
        }
    }
    | expression GT expression 
    { 
        $$ = $1 > $3; 
        fprintf(out, "GT: %d > %d = %d\n", $1, $3, $$); 
    }
    | expression LT expression 
    { 
        $$ = $1 < $3; 
        fprintf(out, "LT: %d < %d = %d\n", $1, $3, $$); 
    }
    | expression GE expression 
    { 
        $$ = $1 >= $3; 
        fprintf(out, "GE: %d >= %d = %d\n", $1, $3, $$); 
    }
    | expression LE expression 
    { 
        $$ = $1 <= $3; 
        fprintf(out, "LE: %d <= %d = %d\n", $1, $3, $$); 
    }
    | expression EQ expression 
    { 
        $$ = $1 == $3; 
        fprintf(out, "EQ: %d == %d = %d\n", $1, $3, $$); 
    }
    | expression NE expression 
    { 
        $$ = $1 != $3; 
        fprintf(out, "NE: %d != %d = %d\n", $1, $3, $$); 
    }
    | expression AND expression 
    { 
        $$ = $1 && $3; 
        fprintf(out, "AND: %d && %d = %d\n", $1, $3, $$); 
    }
    | expression OR expression 
    { 
        $$ = $1 || $3; 
        fprintf(out, "OR: %d || %d = %d\n", $1, $3, $$); 
    }
    | '(' expression ')' 
    { 
        $$ = $2; 
    }
;

%%

void write_error(const char *msg) {
    if(err) {
        fprintf(err, "Line %d: %s\n", line_num, msg);
    }
    printf("Line %d: %s\n", line_num, msg);
}

void yyerror(const char *s) {
    write_error(s);
}

int main() {
    for(int i = 0; i < 26; i++) {
        sym_declared[i] = 0;
        sym[i] = 0;
        sym_type[i] = 0;
    }
    
    yyin = fopen("in.txt", "r");
    out = fopen("out.txt", "w");
    err = fopen("error.txt", "w");
    
    if(!yyin) {
        printf("Error: Cannot open input file in.txt\n");
        return 1;
    }
    if(!out) {
        printf("Error: Cannot open output file out.txt\n");
        return 1;
    }
    if(!err) {
        printf("Error: Cannot open error file error.txt\n");
        return 1;
    }
    
    fprintf(out, "=== Compiler Output ===\n\n");
    fprintf(err, "=== Error Log ===\n\n");
    
    yyparse();
    
    fclose(yyin);
    fclose(out);
    fclose(err);
    
    printf("\nCompilation completed.\n");
    printf("Output written to: out.txt\n");
    printf("Errors written to: error.txt\n");
    
    return 0;
}