%{
	#include "stdio.h"
	#include "symbtab.h"
	#include "stdlib.h"
	
	extern FILE *yyin;
	extern int numlin;
	extern int yylex();
	extern char* yytext;
	int yydebug = 1;
	int yyerror(char *mens);
	Symbtab tabla;
	int temptype;
	Symb* tempvar;
	
%}

%union {
	float real;
	char *word;
	int tipo;
}

%start main

%token <word> NUMERO
%token <word> PALABRA
%token <word> CARACTER
%token <word> VARIABLE
%token <word> IDENTIFICADORFUNC


%token ASIGNACION
%token RESTA
%token MULTIPLICACION
%token DIVISION
%token MODULO
%token SUMA
%token RANGO

%token MATRIX
%token ARRAY
%token STRING
%token FLOAT
%token CHAR

%token COMPARACIONMENOR
%token COMPARACIONMENORIGUAL
%token COMPARACIONMAYOR
%token COMPARACIONMAYORIGUAL
%token COMPARACIONIGUALDAD
%token COMPARACIONDESIGUALDAD
%token NEGACIONLOGICA
%token ANDLOGICO
%token ORLOGICO

%token MATRIXINICIO
%token SEPARADOR
%token MATRIXFIN

%token INICIO
%token FIN

%token WHILE
%token FOR
%token IF

%token MAIN

%%

main		: INICIO types VARIABLE MAIN INICIO variables FIN statements FIN functions
;
functions	:
		| functions INICIO function FIN
;
statements	:
		| statements statement
;
statement	: INICIO assignment FIN
		| INICIO declaration FIN
		| INICIO bucle_for FIN
		| INICIO bucle_while FIN
		| INICIO cond_if FIN
		| INICIO print FIN
;
print		: PRINT INICIO VARIABLE FIN
;
assignment	: VARIABLE ASIGNACION expression
		| VARIABLE INICIO value FIN ASIGNACION expression
		//| VARIABLE INICIO value SEPARADOR value FIN ASIGNACION expression
;
declaration	: VARIABLE MATRIXINICIO NUMERO MATRIXFIN
		| VARIABLE CHAR
		| VARIABLE STRING MATRIXINICIO NUMERO MATRIXFIN
		//| VARIABLE MATRIXINICIO NUMERO SEPARADOR NUMERO MATRIXFIN
;
expression	: IDENTIFICADORFUNC INICIO values FIN
		| value 
		| value SUMA value
		| value RESTA value
		| value MULTIPLICACION value
		| value DIVISION value
		| value MODULO value
		| value COMPARACIONIGUALDAD value
		| value COMPARACIONDESIGUALDAD value
		| value COMPARACIONMAYOR value
		| value COMPARACIONMAYORIGUAL value
		| value COMPARACIONMENOR value
		| value COMPARACIONMENORIGUAL value
		| NEGACIONLOGICA value
		| value ANDLOGICO value
		| value ORLOGICO value
;
value		: NUMERO
		| VARIABLE MATRIXINICIO value MATRIXFIN
		//| VARIABLE MATRIXINICIO value SEPARADOR value MATRIXFIN
		| VARIABLE
		| PALABRA
		| CARACTER
		| INICIO expression FIN
;
values		:
		| values value
;
function	: types VARIABLE IDENTIFICADORFUNC INICIO variables FIN statements
;
types		: FLOAT
		| CHAR
		| ARRAY MATRIXINICIO NUMERO MATRIXFIN
		| STRING MATRIXINICIO NUMERO MATRIXFIN
		//| MATRIX MATRIXINICIO NUMERO SEPARADOR NUMERO MATRIXFIN
;
variables	:
		| variables types VARIABLE
;
bucle_for	: INICIO FOR VARIABLE value RANGO value
		  FIN statements
;
bucle_while	: INICIO WHILE INICIO expression FIN FIN statements
;
cond_if		: INICIO IF INICIO expression FIN FIN INICIO statements FIN INICIO statements FIN
;
%%
int main(int argc, char* argv[])
{
	printf("hola");
	if (argc>1)
		yyin = fopen(argv[1], "r");
	yyparse();
}

int yyerror(char *mens)
{
	printf("Error en linea %i: %s, yytext--> %s \n", numlin, mens, yytext);
	exit(0);
	return 0;
}

