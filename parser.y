%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
extern int line_num;
extern FILE *yyin;

FILE *out;
FILE *err;

/* Symbol table */
double sym[26];          // store values
int sym_declared[26];
int sym_type[26];        // 0=int, 1=float, 2=double

void write_error(const char *msg);
%}

/* ===== UNION ===== */
%union {
    int    ival;
    float  fval;
    double dval;
}

/* ===== TOKENS ===== */
%token VOID MAIN INT FLOAT DOUBLE PRINT IF ELSE
%token EQ NE GT LT GE LE AND OR

%token <ival> NUMBER VARIABLE
%token <fval> FLOAT_NUM
%token <dval> DOUBLE_NUM

%type  <dval> expression

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
        for(int i=0;i<26;i++){
            if(sym_declared[i]){
                fprintf(out, "%c = %g\n", 'a'+i, sym[i]);
            }
        }
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

/* ===== DECLARATION ===== */
declaration:
    INT VARIABLE {
        sym_declared[$2]=1;
        sym_type[$2]=0;
        sym[$2]=0;
        fprintf(out,"Declare variable %c\n",'a'+$2);
    }
  | FLOAT VARIABLE {
        sym_declared[$2]=1;
        sym_type[$2]=1;
        sym[$2]=0;
        fprintf(out,"Declare variable %c (float)\n",'a'+$2);
    }
  | DOUBLE VARIABLE {
        sym_declared[$2]=1;
        sym_type[$2]=2;
        sym[$2]=0;
        fprintf(out,"Declare variable %c (double)\n",'a'+$2);
    }
;

/* ===== INIT ===== */
init_declaration:
    INT VARIABLE '=' expression {
        if($4 != (int)$4)
            write_error("Type mismatch: float/double to int");
        sym[$2]=(int)$4;
        sym_declared[$2]=1;
        sym_type[$2]=0;
        fprintf(out,"Declare and init %c = %d\n",'a'+$2,(int)sym[$2]);
    }
  | FLOAT VARIABLE '=' expression {
        sym[$2]=(float)$4;
        sym_declared[$2]=1;
        sym_type[$2]=1;
        fprintf(out,"Declare and init %c = %g (float)\n",'a'+$2,sym[$2]);
    }
  | DOUBLE VARIABLE '=' expression {
        sym[$2]=$4;
        sym_declared[$2]=1;
        sym_type[$2]=2;
        fprintf(out,"Declare and init %c = %g (double)\n",'a'+$2,sym[$2]);
    }
;

/* ===== ASSIGN ===== */
assignment:
    VARIABLE '=' expression {
        if(sym_type[$1]==0 && $3!=(int)$3)
            write_error("Type mismatch: float/double to int");
        sym[$1]=(sym_type[$1]==0)?(int)$3:$3;
        fprintf(out,"Assign %c = %g\n",'a'+$1,sym[$1]);
    }
;

/* ===== PRINT ===== */
print_stmt:
    PRINT '(' expression ')' {
        fprintf(out,"Print: %g\n",$3);
    }
;

/* ===== IF ===== */
if_stmt:
    simple_if
  | if_else
  | if_else_if
;

simple_if:
    IF '(' expression ')' '{' statements '}' {
        fprintf(out,"If condition = %g\n",$3);
    }
;

if_else:
    IF '(' expression ')' '{' statements '}' ELSE '{' statements '}' {
         fprintf(out, "New condition = %g\n", $3);
        fprintf(out,"else-if condition = %g\n",$3);
    }
;

if_else_if:
    IF '(' expression ')' '{' statements '}' ELSE if_stmt {
           fprintf(out, "New condition = %g\n", $3);
        fprintf(out,"If or  else-if condition = %g\n",$3);
    }
;

/* ===== EXPRESSIONS ===== */
expression:
      NUMBER        { $$=$1; }
    | FLOAT_NUM     { $$=$1; }
    | DOUBLE_NUM    { $$=$1; }
    | VARIABLE      {
            if(!sym_declared[$1])
                write_error("Variable used before declaration");
            $$=sym[$1];
      }
    | '!' expression {
            $$=!$2;
            fprintf(out,"Logical NOT: !%g = %g\n",$2,$$);
      }
    | '-' expression %prec UMINUS {
            $$=-$2;
            fprintf(out,"Unary minus: -%g = %g\n",$2,$$);
      }
    | expression '+' expression {
            $$=$1+$3;
            fprintf(out,"Add: %g + %g = %g\n",$1,$3,$$);
      }
    | expression '-' expression {
            $$=$1-$3;
            fprintf(out,"Sub: %g - %g = %g\n",$1,$3,$$);
      }
    | expression '*' expression {
            $$=$1*$3;
            fprintf(out,"Mul: %g * %g = %g\n",$1,$3,$$);
      }
    | expression '/' expression {
            if($3==0){
                write_error("Division by zero");
                $$=0;
            } else {
                $$=$1/$3;
                fprintf(out,"Div: %g / %g = %g\n",$1,$3,$$);
            }
      }
    | expression GT expression {
            $$=$1>$3;
            fprintf(out,"GT: %g > %g = %g\n",$1,$3,$$);
      }
    | expression LT expression {
            $$=$1<$3;
            fprintf(out,"LT: %g < %g = %g\n",$1,$3,$$);
      }
    | expression EQ expression {
            $$=$1==$3;
            fprintf(out,"EQ: %g == %g = %g\n",$1,$3,$$);
      }
    | expression OR expression {
            $$=$1||$3;
            fprintf(out,"OR: %g || %g = %g\n",$1,$3,$$);
      }
    | '(' expression ')' { $$=$2; }
;

%%

void write_error(const char *msg){
    fprintf(err,"Line %d: %s\n",line_num,msg);
    printf("Line %d: %s\n",line_num,msg);
}

void yyerror(const char *s){
    write_error(s);
}

int main(){
    yyin=fopen("in.txt","r");
    out=fopen("out.txt","w");
    err=fopen("error.txt","w");

    fprintf(out,"=== Compiler Output ===\n\n");
    fprintf(err,"=== Error Log ===\n\n");

    yyparse();

    fclose(yyin);
    fclose(out);
    fclose(err);
    return 0;
}
