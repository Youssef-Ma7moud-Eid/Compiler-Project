%{
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"

int line_num = 1;
void scanner_error(const char *msg);
%}

%%

"void"      { return VOID; }
"main"      { return MAIN; }
"int"       { return INT; }
"float"     { return FLOAT; }
"double"    { return DOUBLE; }
"print"     { return PRINT; }
"if"        { return IF; }
"else"      { return ELSE; }

"=="        { return EQ; }
"!="        { return NE; }
">="        { return GE; }
"<="        { return LE; }
">"         { return GT; }
"<"         { return LT; }
"&&"        { return AND; }
"||"        { return OR; }

[a-z] {
    yylval.ival = *yytext - 'a';
    return VARIABLE;
}

[0-9]+\.[0-9]+[fF] {
    yylval.fval = (float)atof(yytext);
    return FLOAT_NUM;
}

[0-9]+\.[0-9]+ {
    yylval.dval = atof(yytext);
    return DOUBLE_NUM;
}

[0-9]+ {
    yylval.ival = atoi(yytext);
    return NUMBER;
}

[-+*/=();{}!] {
    return *yytext;
}

[ \t]+    { /* ignore spaces */ }
\n        { line_num++; }
"//".*    { /* ignore comments */ }

. {
    scanner_error("Unknown character");
}

%%

void scanner_error(const char *msg) {
    printf("Line %d: Scanner error: %s (%s)\n", line_num, msg, yytext);
}

int yywrap() {
    return 1;
}
