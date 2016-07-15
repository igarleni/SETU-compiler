%{
	#include "stdio.h"
	#include "symbtab.h"
	#include "stdlib.h"
	#include <string>
	#include <iostream>
	
	extern FILE *yyin;
	FILE *fout;
	extern int numlin;
	extern int yylex();
	extern char* yytext;
	int yydebug = 1;
	int yyerror(std::string mens);
	Symbtab tabla;
	unsigned int dirRetorno;
	int tempArraySize;
	
	//funciones para chequeos de tipos
	void checkSimpleAssignment(char* name, int tipo);
	void checkArrayAssignment(char* name, int tipo);
	void checkMatrixAssignment(char* name, int tipo);
	void checkExpressionTypes(int tipo1, int tipo2);
	void checkFloat(int tipo);
	void checkArray(char* name);
	void checkMatrix(char* name);
	void checkFor(char* name, int tipo1, int tipo2);
	void declare(char* name, int type);
	
	//funciones para generacion de codigo
	void generarCabecera();
	void crearEspacioEnPila(int type);

	void generarVariableEnPila(Symb *symbol);
	void obtenerDireccionAbsoluta(Symb * item);
	
	void asignarR6();
	void recuperarR6();

	#define gc(formato, params...) { \
		fprintf(fout, formato, ##params);\
	}
	
%}

%union {
	float real;
	char *word;
	int tipo;
	unsigned int direction;
}

%start main

%token <real> NUMERO
%token <word> PALABRA
%token <word> CARACTER
%token <word> VARIABLE
%token <word> IDENTIFICADORFUNC

%type <tipo> value
%type <tipo> expression
%type <tipo> types

%token ASIGNACION
%token RESTA
%token MULTIPLICACION
%token DIVISION
%token MODULO
%token SUMA
%token RANGO

%token <tipo> MATRIX
%token <tipo> ARRAY
%token <tipo> STRING
%token <tipo> FLOAT
%token <tipo> CHAR

%token COMPARACIONMENOR
%token COMPARACIONMENORIGUAL
%token COMPARACIONMAYOR
%token COMPARACIONMAYORIGUAL
%token COMPARACIONIGUALDAD
%token COMPARACIONDESIGUALDAD
%token NEGACIONLOGICA
%token ANDLOGICO
%token ORLOGICO

%token <word> MATRIXINICIO
%token SEPARADOR
%token <word> MATRIXFIN

%token INICIO
%token FIN

%token PRINT
%token WHILE
%token FOR
%token IF

%token MAIN

%%

main		: INICIO {generarCabecera();}
		  types VARIABLE
		  {
		  	tabla.addScope();
		  	declare($4, $3);
		  	generarVariableEnPila(tabla.symblook($4));
		  }
		  MAIN INICIO variables 
		  FIN statements FIN 
		  {
		  	tabla.quitScope();
		  	gc("\t\tGT(-2);\n");
		  }
		  functions { gc("END\n");}
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
		  {
		  	Symb *item = tabla.symblook($3);
		  	switch (item->type)
		  	{
		  		case SYMB_FLOAT:
		  			obtenerDireccionAbsoluta(item);
		  			tabla.functionLinks++;
		  			gc("\t\tRR1 = F(R1);\n");
		  			gc("\t\tR2 = 1;\n");
		  			gc("\t\tR0 = %i;\n", tabla.functionLinks);
		  			gc("\t\tGT(putf_);\n");
		  			gc("L %i:", tabla.functionLinks);
		  			break;
		  		case SYMB_CHAR:
		  			obtenerDireccionAbsoluta(item);
		  			tabla.functionLinks++;
		  			gc("\t\tR1 = U(R1);\n");
		  			gc("\t\tR2 = 2;\n");
		  			gc("\t\tR0 = %i;\n", tabla.functionLinks);
		  			gc("\t\tGT(putf_);\n");
		  			gc("L %i:", tabla.functionLinks);
		  			break;
		  		//case SYMB_STRING:
		  			//break;
		  		//case SYMB_ARRAY:
		  			//break;
		  		//case SYMB_MATRIX:
		  			//break;
		  		default:
		  			yyerror("Error al imprimir. Variable no declarada");
		  			break;
		  	}
		  }
;
assignment	: VARIABLE 
		{
			Symb* item = tabla.symblook($1);
			if (item->type == SYMB_UNDEFINED)
			{
				item->type = SYMB_FLOAT;
				generarVariableEnPila(item);
			}
		} 
		  ASIGNACION expression 
		{
			checkSimpleAssignment($1, $4);
			Symb* item = tabla.symblook($1);
			obtenerDireccionAbsoluta(item);//obtiene la direccion de la variable y la guarda en R1
			//asignamos el valor de la cima de la pila al registro
			switch (item->type)
			{
				case SYMB_FLOAT:
					gc("\t\tRR1 = F(R7);\n");
					gc("\t\tF(R1) = RR1;\n");
					break;
				case SYMB_CHAR:
					gc("\t\tR5 = U(R7);\n");
					gc("\t\tU(R1) = R5;\n");
					break;
				case SYMB_STRING:
					if (tempArraySize != item->arraySize) yyerror("Error al asignar. Tamaños diferentes");
					for (int i = 0; i < item->arraySize; i++){
						gc("\t\tR5 = U(R7 + %i);\n",i);
						gc("\t\tU(R1 + %i) = R5;\n", i);
					}
					break;
				case SYMB_ARRAY:
					if (tempArraySize != item->arraySize) yyerror("Error al asignar. Tamaños diferentes");
					for (int i = 0; i < item->arraySize; i++)
					{
						tempArraySize = item->arraySize * 4;
						gc("\t\tRR1 = F(R7 + %i);\n", tempArraySize);
						gc("\t\tF(R1 + %i) = RR1;\n", tempArraySize);
					}
					break;
				//case SYMB_MATRIX:
					//break;
				
				default:
					yyerror("Error en asignacion al leer variable. Indefinido.");
					break;
			}
			//limpiamos la pila, moviendo la cima a la ultima variable creada
			gc("\t\tR7 = R6 - %u;\n",tabla.relativeDirR6); 
		} 
		| VARIABLE INICIO value
		  {
		  	checkFloat($3);
		  	gc("\t\tR3 = F(R7);\n");
		  	gc("\t\tR7 = R7 + 4;\n");
		  }
		  FIN ASIGNACION expression
		{
			checkArrayAssignment($1,$7);
			Symb* item = tabla.symblook($1);
			obtenerDireccionAbsoluta(item);//obtiene la direccion de la variable y la guarda en R1
			//asignamos el valor de la cima de la pila al registro
			if ($7 == SYMB_FLOAT)
			{
				gc("\t\tR3 = R3 * 4;\n");
				gc("\t\tRR1 = F(R7);\n");
				gc("\t\tF(R1 + R3) = RR1;\n");
			}
			else
			{
				gc("\t\tR5 = U(R7);\n");
				gc("\t\tU(R1 + R3) = R5;\n");
			}
			
			gc("\t\tR7 = R6 - %u;\n",tabla.relativeDirR6); 
		}
		//| VARIABLE INICIO value SEPARADOR value FIN ASIGNACION expression {checkMatrixAssignment($1,$8);}
;
declaration	: VARIABLE MATRIXINICIO NUMERO MATRIXFIN 
		  {
		  	tempArraySize = $3;
		  	declare($1, SYMB_ARRAY);
		  	generarVariableEnPila(tabla.symblook($1));
		  }
		| VARIABLE CHAR 
		{
			declare($1, SYMB_CHAR);
			generarVariableEnPila(tabla.symblook($1));
		}
		| VARIABLE STRING MATRIXINICIO NUMERO MATRIXFIN 
		  {
		  	tempArraySize = $4;
		  	declare($1, SYMB_STRING);
		  	generarVariableEnPila(tabla.symblook($1));
		  }
		//| VARIABLE MATRIXINICIO NUMERO SEPARADOR NUMERO MATRIXFIN {declare($1, SYMB_MATRIX);}
;
expression	: IDENTIFICADORFUNC 
		{
			/////////////////////////////////////////////////////////////////////////////////////////
			/////   SALIDA = R6previo | dirRetorno | variableEntrada |variableEntrada | ...    //////
			/////////////////////////////////////////////////////////////////////////////////////////
			
			//reservamos espacio para meter R6 actual luego
			gc("\t\tR7 = R7 - 4;\n");
			gc("\t\tR4 = R7;\n"); //guardamos la direccion donde va a estar R6
			//añadimos a la pila la direccion L de retorno
			tabla.functionLinks++;
			gc("\t\tR7 = R7 - 4;\n");
			dirRetorno = tabla.functionLinks;
			gc("\t\tP(R7) = %u;\n", dirRetorno);
		} 
		  INICIO values FIN 
		{
			$$ = SYMB_FUNCTION;
			declare($1, SYMB_FUNCTION);
			//actualizamos R6
			gc("\t\tP(R4) = R6;\n");
			gc("\t\tR6 = R4;\n");
			//con "values" ya se genera el código para poner en la pila las variables de salida.
			//ponemos el salto L a donde tiene que retornar y llamamos a la funcion
			gc("\t\tGT(%u);\n", tabla.symblook($1)->functionLink);
			gc("L %u:", dirRetorno);
		}
		| value 
		| value SUMA value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			gc("\t\tRR1 = RR1 + RR2;\n");
			gc ("\t\tR7 = R7 + 4;\n");
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value RESTA value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			gc("\t\tRR1 = RR1 - RR2;\n");
			gc ("\t\tR7 = R7 + 4;\n");
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value MULTIPLICACION value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			gc("\t\tRR1 = RR1 * RR2;\n");
			gc ("\t\tR7 = R7 + 4;\n");
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value DIVISION value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			gc("\t\tRR1 = RR1 / RR2;\n");
			gc ("\t\tR7 = R7 + 4;\n");
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value MODULO value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			gc("\t\tRR1 = RR1 %c RR2;\n", 37);
			gc ("\t\tR7 = R7 + 4;\n");
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value COMPARACIONIGUALDAD value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 == RR2) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value COMPARACIONDESIGUALDAD value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 != RR2) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value COMPARACIONMAYOR value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 > RR2) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value COMPARACIONMAYORIGUAL value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 >= RR2) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));			
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value COMPARACIONMENOR value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 < RR2) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value COMPARACIONMENORIGUAL value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 <= RR2) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| NEGACIONLOGICA value 
		{
			checkFloat($2);
			$$ = $2;
			
			gc("\t\tRR1 = F(R7);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 < 1) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tF(R7) = RR1;\n", tabla.functionLinks);
		}
		| value ANDLOGICO value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 < 1) GT(%u);\n", tabla.functionLinks);
			gc("\t\tIF (RR2 < 1) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 1;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);
			
			gc("L %u:\t\tRR1 = 0;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
		| value ORLOGICO value 
		{
			checkExpressionTypes($1,$3);
			$$ = $3;
			
			gc("\t\tRR2 = F(R7);\n");
			gc("\t\tRR1 = F(R7 + 4);\n");
			tabla.functionLinks++;
			gc("\t\tIF (RR1 >= 1) GT(%u);\n", tabla.functionLinks);
			gc("\t\tIF (RR2 >= 1) GT(%u);\n", tabla.functionLinks);
			gc("\t\tRR1 = 0;\n");
			tabla.functionLinks++;
			gc("\t\tGT(%u);\n", tabla.functionLinks);

			gc("L %u:\t\tRR1 = 1;\n", (tabla.functionLinks - 1));
			gc("L %u:\t\tR7 = R7 + 4;\n", tabla.functionLinks);
			gc ("\t\tF(R7) = RR1;\n");
		}
;
value		: NUMERO
		{
			$$ = SYMB_FLOAT;
			crearEspacioEnPila(SYMB_FLOAT);
			gc("\t\tF(R7) = %f;\n", $1);
		}
		| VARIABLE MATRIXINICIO value
		  {
		  	checkFloat($3);
		  	gc("\t\tR2 = F(R7);\n");
		  	gc("\t\tR7 = R7 + 4;\n");
		  }
		  MATRIXFIN 
			{
				checkArray($1);
				Symb* item = tabla.symblook($1);
				if (item->type == SYMB_ARRAY)
				{
					$$ = SYMB_FLOAT;
					crearEspacioEnPila(SYMB_FLOAT);
					obtenerDireccionAbsoluta(item);
					gc("\t\tR2 = R2 * 4;\n");
					gc("\t\tRR1 = F(R1 + R2);\n");
					gc("\t\tF(R7) = RR1;\n");
				}
				else
				{
					$$ = SYMB_CHAR;
					crearEspacioEnPila(SYMB_CHAR);
					obtenerDireccionAbsoluta(item);
					gc("\t\tR5 = U(R1 + R2);\n");
					gc("\t\tU(R7) = R5;\n");
				}
			}
		| VARIABLE 
		{
			Symb * item = tabla.symblook($1);
			if (item->type == SYMB_UNDEFINED)
				yyerror("Error, variable no declarada.");
			$$ = item->type;
			switch (item->type)
			{
				case SYMB_FLOAT:
					crearEspacioEnPila(item->type);
					obtenerDireccionAbsoluta(item);
					gc("\t\tR5 = F(R1);\n");
					gc("\t\tF(R7) = R5;\n");
					break;
				case SYMB_CHAR:
					crearEspacioEnPila(item->type);
					obtenerDireccionAbsoluta(item);
					gc("\t\tR5 = U(R1);\n");
					gc("\t\tU(R7) = R5;\n");
					break;
				case SYMB_STRING:
					tempArraySize = item->arraySize;
					crearEspacioEnPila(item->type);
					obtenerDireccionAbsoluta(item);
					for (int i = 0; i < tempArraySize; i++)
					{
						gc("\t\tR5 = U(R1 + %i);\n", i);
						gc("\t\tU(R7 + %i) = R5;\n", i);
					}
					break;
				case SYMB_ARRAY:
					tempArraySize = item->arraySize;
					crearEspacioEnPila(item->type);
					obtenerDireccionAbsoluta(item);
					int directionRelative;
					for (int i = 0; i < tempArraySize; i++){
						directionRelative = i * 4;
						gc("\t\tRR1 = F(R1 + %i);\n", directionRelative);
						gc("\t\tF(R7 + %i) = RR1;\n", directionRelative);
					}
					break;
				//case SYMB_MATRIX:
					//break;
				
				default:
					yyerror("Error al leer variable. Indefinido.");
					break;
			}
		}
		| PALABRA
		{
			$$ = SYMB_STRING;
			std::string st($1);
			tempArraySize = st.size();
			int alineacion = tempArraySize;
			while (alineacion % 4 != 0) alineacion++;
			gc("\t\tR7 = R7 - %i;\n", alineacion);
			for(int i = 0; i<tempArraySize;i++)
			{
				gc("\t\tU(R7 + %i) = '%c';\n",i , st[i]);
			}
		}
		| CARACTER 
		{
			$$ = SYMB_CHAR;
			std::string st($1);
			gc("\t\tR7 = R7 - 4;\n");
			gc("\t\tU(R7) = '%c';\n",st[1]);
			
		}
		//| VARIABLE MATRIXINICIO value SEPARADOR value MATRIXFIN {checkMatrix($1);$$ = SYMB_FLOAT;}
		| INICIO expression FIN {$$ = $2;}
;
values		:
		| values value
;
function	: types VARIABLE IDENTIFICADORFUNC 
		  {
		  	declare($3, SYMB_FUNCTION);
		  	tabla.addScope();
		  	//guardamos el posible tamaño de tempArraySize de la variable de retorno para usarla luego
		  	$<real>$ = tempArraySize; 
			/////////////////////////////////////////////////////////////////////////////////////////
			/////   ENTRADA = R6previo | dirRetorno | variableEntrada |variableEntrada | ...   //////
			/////////////////////////////////////////////////////////////////////////////////////////

			//ponemos el cabezal de la pila en la zona donde están las variables de entrada
			gc("L %u:\t\tR7 = R6 - 4;\n", tabla.symblook($3)->functionLink);
			tabla.relativeDirR6 += 4;
			//ahora en "variables" se asignarán las variables de entrada a la entrada
		  }
		  INICIO variables 
		  {
			//se mete la variable de retorno despues de las de entrada
			tempArraySize = $<real>4; 
			declare($2, $1);
		  	generarVariableEnPila(tabla.symblook($2));
		  } 
		  FIN statements
		  {
		  	//guardar R6 antiguo
		  	gc("\t\tR4 = P(R6);\n");

		  	//guardar direccion de retorno
			gc("\t\tR2 = P(R6 - 4);\n");
			//movemos la cima de la pila al estado deseado para retornar (vacía y con el resultado en la pila)
		  	gc("\t\tR7 = R6 + 4;\n");
		  	//copiar variable resultado en la cima de la pila (su direccion es relativa a R6 + item-dir)
		  	Symb *item = tabla.symblook($2);
		  	obtenerDireccionAbsoluta(item);
		  	int alineamiento;
		  	switch (item->type)
		  	{
		  		case SYMB_FLOAT:
		  			gc("\t\tR7 = R7 - 4;\n");
		  			gc("\t\tRR = F(R1);\n");
					gc("\t\tF(R7) = RR1;\n");
					break;
				case SYMB_CHAR:
					gc("\t\tR7 = R7 - 4;\n");
					gc("\t\tR5 = U(R1);\n");
					gc("\t\tU(R7) = R5;\n");
					break;
				case SYMB_STRING:
					alineamiento = item->arraySize;
					while ((alineamiento % 4) != 0) alineamiento++;
					gc("\t\tR7 = R7 - %i;\n", alineamiento);
					for (int i = 0; i < item->arraySize; i++)
					{
						gc("\t\tR5 = U(R1 + %i);\n", i);
						gc("\t\tU(R7 + %i) = R5;\n", i);
					}
					break;
				case SYMB_ARRAY:
					alineamiento = item->arraySize * 4;
					gc("\t\tR7 = R7 - %i;\n", alineamiento);
					int directionRelative;
					for (int i = 0; i < item->arraySize; i++)
					{
						directionRelative = i * 4;
						gc("\t\tRR1 = F(R1 + %i);\n", directionRelative);
						gc("\t\tF(R7 + %i) = RR1;\n", directionRelative);
					}
					break;
				//case SYMB_MATRIX:
					//break;
				default:
					yyerror("Error en function. Variable de retorno errónea.");
					break;
		  	}
		  	//recuperamos R6 del nivel superior
			gc("\t\tR6 = R4;\n");
			gc("\t\tGT(R2);\n");
		  	
		  	tabla.quitScope();
		  }
;
types		: FLOAT
		| CHAR
		| ARRAY MATRIXINICIO NUMERO MATRIXFIN {tempArraySize = $3;}
		| STRING MATRIXINICIO NUMERO MATRIXFIN {tempArraySize = $3;}
		//| MATRIX MATRIXINICIO NUMERO SEPARADOR NUMERO MATRIXFIN
;
variables	:
		| variables types VARIABLE 
		{
			declare($3, $2);
			generarVariableEnPila(tabla.symblook($3));
		}
;
bucle_for	: INICIO FOR VARIABLE 
		  {
		  	tabla.addScope();
		  	gc("\t\tR7 = R7 - 4;\n"); //reservamos un espacio para el "valor de comprobación"
		  	asignarR6(); //generamos un nuevo R6
		  	declare($3, SYMB_FLOAT);

		  	generarVariableEnPila(tabla.symblook($3));
		  	tabla.functionLinks++;
		  	$<direction>$ = tabla.functionLinks; //direccion de salida
		  }
		  value 
		  {
		  	checkFloat($5);
		  	obtenerDireccionAbsoluta(tabla.symblook($3)); //mete en R1 la direccion de la variable
		  	gc("\t\tR5 = F(R7);\n");
		  	gc("\t\tR5 = R5 - 1;\n");
		  	gc("\t\tF(R1) = R5;\n");
		  	gc("\t\tR7 = R7 + 4;\n");//limpiamos la pila de restos de cálculos
		  }
		  RANGO value 
		  {
		  	tabla.functionLinks++;
		  	$<direction>$ = tabla.functionLinks; //direccion de comprobacion
		  	checkFloat($8);
		  	gc("\t\tRR1 = F(R7);\n");
		  	gc("\t\tF(R6 + 4) = RR1;\n"); //guardamos el "valor de comprobacion"
		  	gc("\t\tR7 = R7 + 4;\n"); //limpiamos la pila de "value"
		  	gc("L %u:",tabla.functionLinks);
		  	obtenerDireccionAbsoluta(tabla.symblook($3)); //metemos en R1 la direccion de la variable a comprobar
		  	gc("\t\tRR1 = F(R1);\n");
		  	gc("\t\tRR2 = F(R6 + 4);\n");
		  	gc("\t\tIF (RR1 >= RR2) GT(%u);\n",$<direction>4);
		  	gc("\t\tRR1 = RR1 + 1;\n");
		  	gc("\t\tF(R1) = RR1;\n");
		  }
		  FIN statements
		  {
		  	gc("\t\tGT(%u);\n", $<direction>9);
		  	gc("L %u:",$<direction>4);
		  	recuperarR6();
		  	tabla.quitScope();
		  	gc("\t\tR7 = R7 + 4;\n");
		  }
;
bucle_while	: INICIO WHILE INICIO 
		  {
		  	tabla.addScope();
		  	asignarR6();
		  	tabla.functionLinks++;
		  	$<direction>$ = tabla.functionLinks; //dirección de comprobación
		  	gc("L %u:", tabla.functionLinks);
		  }
		  expression
		  {
		  	checkFloat($5);
			tabla.functionLinks++;
		  	$<direction>$ = tabla.functionLinks; //dirección de salida
		  	gc("\t\tRR1 = F(R7);\n");
		  	gc("\t\tIF (RR1 == 0) GT(%u);\n", tabla.functionLinks);
		  }
		  FIN FIN statements
		  {
		  	gc("\t\tGT(%u);\n", $<direction>4);
		  	gc("L %u:", $<direction>6);
		  	tabla.quitScope();
		  	recuperarR6();
		  }
;
cond_if		: INICIO
		  {
		  	tabla.addScope();
		  	asignarR6();
		  	tabla.functionLinks++;
		  	$<direction>$ = tabla.functionLinks; //dirección de salida
		  }
		  IF INICIO expression
		  {
		  	checkFloat($5);
		  	tabla.functionLinks++;
		  	$<direction>$ = tabla.functionLinks; //dirección de else
		  	gc("\t\tRR1 = F(R7);\n");
		  	gc("\t\tIF(RR1 == 0) GT(%u);\n",tabla.functionLinks);
		  }
		  FIN FIN INICIO
		  {
		  	gc("\t\tR7 = R7 + 4;\n");
		  }
		  statements FIN INICIO
		  {
		  	gc("\t\tGT(%u);\n",$<direction>2);
		  	gc("L %u:\t\tR7 = R7 + 4;\n",$<direction>6);
		  }
		  statements FIN
		  {
		  	gc("L %u:", $<direction>2);
		  	recuperarR6();
		  	tabla.quitScope();
		  }
;
%%

///////////////////////////////////
/////FUNCIONES PARA GENERACION/////
///////////DE CODIGO///////////////
///////////////////////////////////

//genera una variable en la pila en caso de que no esté creada ya. Guarda la dirección relativa a R6 en la tabla de simbolos
//la pila sólo puede tener variables guardadas (sin restos de ejecución de otro código) para que se cumpla "relativeDirR6 = R7 - R6"
void generarVariableEnPila(Symb *symbol)
{
	if (symbol->dir == 0)
	{
		int alineamiento;
		switch (symbol->type)
		{
			case SYMB_FLOAT:
				tabla.relativeDirR6 += 4;
				gc("\t\tR7 = R7 - 4;\n"); //alineamos y reservamos para guardar
				symbol->dir = tabla.relativeDirR6;
				break;
			case SYMB_CHAR:
				tabla.relativeDirR6 += 4;
				gc("\t\tR7 = R7 - 4;\n"); //alineamos y reservamos para guardar
				symbol->dir = tabla.relativeDirR6;
				break;
			case SYMB_STRING:
				alineamiento = tempArraySize;
				while ((alineamiento % 4) != 0) alineamiento++;
				tabla.relativeDirR6 += alineamiento;
				gc("\t\tR7 = R7 - %i;\n",alineamiento); //alineamos y reservamos para guardar
				symbol->dir = tabla.relativeDirR6;
				break;
			case SYMB_ARRAY:
				alineamiento = tempArraySize * 4;
				tabla.relativeDirR6 += alineamiento;
				gc("\t\tR7 = R7 - %i;\n",alineamiento); //alineamos y reservamos para guardar
				symbol->dir = tabla.relativeDirR6;
				break;
			//case SYMB_MATRIX:
				//break;
			default:
				yyerror("Intentando meter en pila. Error, variable no declarada.");
				break; 
		}
	}
}

//crea un espacio vacío en la pila e incrementa el puntero, según el tipo, para su posterior uso
void crearEspacioEnPila(int type)
{
	int alineamiento;
		switch (type)
		{
			case SYMB_FLOAT:
				gc("\t\tR7 = R7 - 4;\n"); //alineamos y reservamos
				break;
			case SYMB_CHAR:
				gc("\t\tR7 = R7 - 4;\n"); //alineamos y reservamos
				break;
			case SYMB_STRING:
				alineamiento = tempArraySize;
				while ((alineamiento % 4) != 0) alineamiento++;
				gc("\t\tR7 = R7 - %i;\n",alineamiento); //alineamos y reservamos
				break;
			case SYMB_ARRAY:
				alineamiento = tempArraySize * 4;
				gc("\t\tR7 = R7 - %i;\n",alineamiento); //alineamos y reservamos
				break;
			//case SYMB_MATRIX:
				//break;
			default:
				yyerror("Intentando reservar en pila. Error, tipo erróneo.");
				break; 
		}
}

//obtiene la direccion absoluta y la guarda en el registro R1 para su posterior uso
void obtenerDireccionAbsoluta(Symb * item)
{
	//Numero de saltos de R6 que hay que dar
	int numSaltos = tabla.actualScope - item->scope;

	gc("\t\tR1 = R6;\n");
	for (int i = 0; i < numSaltos; i++)
	{
		gc("\t\tR1 = P(R1);\n");
	}
	//aumentamos la dirección con la referencia a la dirección relativa
	gc("\t\tR1 = R1 - %u;\n", item->dir); 
}

void asignarR6()
{
	gc("\t\tR7 = R7 - 4;\n");
	gc("\t\tP(R7) = R6;\n");
	gc("\t\tR6 = R7;\n");
}

void recuperarR6()
{
	gc("\t\tR7 = R6;\n");
	gc("\t\tR6 = P(R7);\n");
	gc("\t\tR7 = R7 + 4;\n");
}

//cabecera para el MAIN
void generarCabecera()
{
	gc("#include \"Q.h\" \n");
	gc("BEGIN\n");
	gc("L 0:\t\tR6 = R7;\n");
}

///////////////////////////////////
//////FUNCIONES PARA CHEQUEOS//////
///////////////////////////////////

void checkSimpleAssignment(char* name, int tipo)
{
	Symb *item = tabla.symblook(name);
	if (tipo != SYMB_FUNCTION)
	{
		if (item->type != tipo){
			yyerror("Error de tipos al asignar");
		}
	}
}

void checkArrayAssignment(char* name, int tipo)
{
	Symb* item = tabla.symblook(name);
	if (item->type == SYMB_ARRAY)
	{
		if (tipo != SYMB_FLOAT)
			yyerror("Error de tipos al asignar");
	}
	else if (item->type == SYMB_STRING)
	{
		if (tipo != SYMB_CHAR)
			yyerror("Error de tipos al asignar");
	}
	else
		yyerror("Error de tipos al asignar");	
	
}

void checkMatrixAssignment(char* name, int tipo)
{
	if (tabla.symblook(name)->type == SYMB_MATRIX)
	{
		if (tipo != SYMB_FLOAT)
			yyerror("Error de tipos al asignar");
	}
	else
		yyerror("Error de tipos al asignar");
}

void checkExpressionTypes(int tipo1, int tipo2)
{
	if((tipo1 != SYMB_FLOAT) || (tipo2 != SYMB_FLOAT))
		yyerror("Error de tipos, intentando operar con un valor no numerico.");
}

void checkFloat(int tipo)
{
	if(tipo != SYMB_FLOAT)
		yyerror("Error de tipos, el valor debe ser numérico.");
}

void checkArray(char* name)
{
	if((tabla.symblook(name)->type != SYMB_STRING) && (tabla.symblook(name)->type != SYMB_ARRAY))
		yyerror("Error de tipos, el valor debe ser array o string.");
}

void checkMatrix(char* name)
{
	if(tabla.symblook(name)->type != SYMB_MATRIX)
		yyerror("Error de tipos, el valor debe ser matrix.");
}

void checkFor(char* name, int tipo1, int tipo2)
{
	checkSimpleAssignment(name,SYMB_FLOAT);
	checkExpressionTypes(tipo1,tipo2);
}

void declare(char* name, int type)
{
	if (type == SYMB_FUNCTION)
		tabla.addFunction(name);
	else
	{
		Symb* item = tabla.symblook(name);
		if(item->type != SYMB_UNDEFINED && item->type != type)
			yyerror("Error, variable ya declarada.");
		else
		{
			item->type = type;
			if (type == SYMB_ARRAY || type == SYMB_STRING)
				item->arraySize = tempArraySize;
		}
	}
}

///////////////////////////////////
/////////MAIN Y YYERROR////////////
///////////////////////////////////

int main(int argc, char* argv[])
{
	fout = fopen("./Qcode.txt","w");
	if(fout == NULL)
		yyerror("Fichero de salida no abierto");
	printf("Inicia el parser... \n");
	if (argc>1)
		yyin = fopen(argv[1], "r");
	yyparse();
	fclose(fout);
	printf("Parser terminado, código Q en \"Qcode.txt\" generado. \n");
}

int yyerror(std::string mens)
{
	std::cout << "Error en linea " << numlin << ": " << mens << "\nyytext--> " << yytext << "\n";
	exit(0);
	return 0;
}

