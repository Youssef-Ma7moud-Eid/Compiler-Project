%{
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"
extern YYSTYPE yylval;

int line_num = 1;
void scanner_error(const char *msg);
%}

%%

"void"       { return VOID; }
"main"       { return MAIN; }
"int"        { return INT; }
"print"      { return PRINT; }
"if"         { return IF; }
"else"       { return ELSE; }

"=="         { return EQ; }
"!="         { return NE; }
">="         { return GE; }
"<="         { return LE; }
">"          { return GT; }
"<"          { return LT; }
"&&"         { return AND; }
"||"         { return OR; }

[a-z] {
    yylval = *yytext - 'a';
    return VARIABLE;
}

[0-9]+ {
    yylval = atoi(yytext);
    return NUMBER;
}

[-+*/=();{}!] {
    return *yytext;
}

";"          { return ';'; }

[ \t]+       { /* ignore spaces and tabs */ }
\n           { line_num++; }
"//".*       { /* ignore comments */ }

.            {
    scanner_error("Unknown character");
    return -1;
}

%%

void scanner_error(const char *msg) {
    FILE *err = fopen("error.txt", "a");
    if(err) {
        fprintf(err, "Line %d: Scanner Error - %s '%s'\n", line_num, msg, yytext);
        fclose(err);
    }
    printf("Line %d: Scanner Error - %s '%s'\n", line_num, msg, yytext);
}

int yywrap() {
    return 1;
}