%{
	#include "symbtab.h"
	#include "sintactico.tab.h"
	extern int yyerror(std::string mens);
	int numlin = 1;
%}

%option noyywrap

%%
(" "|"\t")+
\n {numlin++;}
"-" {return RESTA;}
"*" {return MULTIPLICACION;}
"/" {return DIVISION;}
"%" {return MODULO;}
"+" {return SUMA;}
":" {return RANGO;}
"<=" {return COMPARACIONMENORIGUAL;}
"<" {return COMPARACIONMENOR;}
">=" {return COMPARACIONMAYORIGUAL;}
">" {return COMPARACIONMAYOR;}
"==" {return COMPARACIONIGUALDAD;}
"=" {return ASIGNACION;}
"!=" {return COMPARACIONDESIGUALDAD;}
"!" {return NEGACIONLOGICA;}
"&&" {return ANDLOGICO;}
"||" {return ORLOGICO;}
"," {return SEPARADOR;}
"(" {return INICIO;}
")" {return FIN;}
"[" {return MATRIXINICIO;}
"]" {return MATRIXFIN;}
float {yylval.tipo = SYMB_FLOAT; return FLOAT;}
matrix {yylval.tipo = SYMB_MATRIX; return MATRIX;}
array {yylval.tipo = SYMB_ARRAY; return ARRAY;}
string {yylval.tipo = SYMB_STRING; return STRING;}
char {yylval.tipo = SYMB_CHAR; return CHAR;}
print {return PRINT;}
while {return WHILE;}
for {return FOR;}
if {return IF;}
main {return MAIN;}
\'([A-Z]|[a-z]|[0-9])\' {yylval.word = strdup(yytext); return CARACTER;}
\"(\\.|[^"])*\" {yylval.word = strdup(yytext); return PALABRA;}
[0-9]+ {yylval.real = atof(yytext); return NUMERO;}
[0-9]+"."[0-9]* {yylval.real = atof(yytext); return NUMERO;}
[a-z]([A-Z]|[a-z]|[0-9])* {yylval.word = strdup(yytext);return VARIABLE;}
[A-Z]([A-Z]|[a-z]|[0-9])* {yylval.word = strdup(yytext);return IDENTIFICADORFUNC;}

. {yyerror("Carácter no permitido");}
%%ZZ
