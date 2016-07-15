/* Nano-compilador a Q ejemplo para GII-PL -- Jose Fortes 2016-02-09 v0.3

Para un programas fuente src.en como:

int n; 
int f;
n = 5;
f = 1;
while (n>0) {
  f = f * n;
  print(f); 
  n = n-1;
}

Usado: ejnano src.en obj.q.c
Genera:

#include "Q.h"
BEGIN
STAT(0)
	STR(0x11ffc,"%i\n");
CODE(0)
L 0:	R6=R7;
	R7=R7-8;
	R0=5;
	I(R6-4)=R0;
	R0=1;
	I(R6-8)=R0;
L 1:	R0=I(R6-4);
	R1=0;
	R0=R0>R1;
	IF(!R0) GT(2);
	R0=I(R6-8);
	R1=I(R6-4);
	R0=R0*R1;
	I(R6-8)=R0;
	R0=I(R6-8);
	R2=R0;
	R0=3;
	R1=0x11ffc;
	GT(putf_);
L 3:	R0=I(R6-4);
	R1=1;
	R0=R0-R1;
	I(R6-4)=R0;
	GT(1);
L 2:	GT(-2);
END

Que, ejecutado como: iq.c obj.q.c 
Produce:

5
20
60
120
120

 */

char dbg=1;

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *fte, *obj;

// tabla de simbolos
#define MAXV 11
struct {
  char id;
  int loc;
} var[MAXV];
int nv;
int top;

int dmp() {
  int i;
  for (i=0;i<nv;i++) printf(" %d:%c",var[i].loc,var[i].id);
  printf("\n");
}

int ins(char id) { 
  if (nv<MAXV) {
    top -= 4;
    var[nv].id=id;    
    var[nv].loc=top;
    nv++; 
    return 1;
  } else return 0;
}

int loc(char id) {
  int i;
  for (i=0;i<nv;i++)
    if (var[i].id==id) return var[i].loc;
  return 0;
}

char c; 
char *car = "{}();+-*/<>"; // mismo orden:
enum simb {
  ABRELLAVE, CIERRALLAVE, ABREPAR, CIERRAPAR, PYCOMA, MAS, MENOS, POR, DIVIS, MENOR, MAYOR,
  FIN, IGUAL, ASIGN, NUM, ID, INT, WHILE, PRINT
};
//           0   4     10
char *res = "int$while$print$"; 
#define RESL 7
enum simb s;

void error(int n) {
  switch (n) {
    default: 
      fprintf(obj, "\nerror de compilacion %d\n", n);
      printf("\nerror de compilacion %d\n", n);
      printf("%i\n", s);
  }
  exit(n);
}

void sigc() {
  c = fgetc(fte);
  if (dbg) printf("%c", c);
}

char id;
int num;

// lexico
enum simb sigs() {
  int i;
  char *p;
  while (c==' ' || c=='\t' || c=='\n' || c=='\r') sigc();
  char pal[RESL];
  for (i=0;c>='a' && c<='z';i++) {
    if (i>=RESL-2) error(201); // palabra muy larga
    pal[i] = c;
    sigc();
  }
  if (i>1) {
    pal[i++]='$'; pal[i]=0;
    p = strstr(res, pal); 
    if (p==NULL) error(202); // no encontrada
    switch (p-res) {
    case 0: return s = INT;
    case 4: return s = WHILE;
    case 10: return s = PRINT;
    }
  }
  if (i==1) { id = pal[0]; return s = ID; } 
  num = 0;
  for (i=0;c>='0' && c<='9';i++) { num = 10*num+c-'0'; sigc(); }  
  if (i>0) return s = NUM;
  if (c=='=') {
    sigc();
    if (c=='=') { sigc(); return s = IGUAL; }
    return s = ASIGN;
  }
  if (c==EOF) return s = FIN;
  p = strchr(car, c);
  if (p==NULL) error(203); // caracter no valido
  sigc();
  return s = (enum simb)(p-car); // simbolos 1a linea definicion simb
}

int et = 0;
int etiq() { return ++et; }

#define MAXR 5
char regoc[MAXR];

void libreg(int i) { regoc[i]=0; }
int ocreg() { 
  int i;
  for (i=0;i<MAXR && regoc[i];i++);
  if (i<MAXR) {
    regoc[i]=1; 
    return i;
  } else error(2001); // insuficientes registros
}

int expr(); // definicion recursiva

int fact() {
  int r;
  switch (s) {
  case NUM: 
    r = ocreg();
    fprintf(obj, "\tR%d=%d;\n", r, num);
    break;
  case ID:;
    int l = loc(id);
    if (l==0) error(1203);
    r = ocreg();
    fprintf(obj, "\tR%d=I(R6%d);\n", r, l);
    break;
  case ABREPAR:
    sigs();
    r = expr();
    if (s!=CIERRAPAR) error(1202);
    break;
  default: error(1201);
  }
  sigs();
  return r;
}

int term() {
  int ri = fact();
  while (s==POR || s==DIVIS) {
    int op = (int)s;
    sigs();
    int rd = fact();
    fprintf(obj, "\tR%d=R%d%cR%d;\n", ri, ri, car[op], rd);
    libreg(rd);
  }
  return ri;
}

int arit() {
  int ri = term();
  while (s==MAS || s==MENOS) {
    int op = (int)s;
    sigs();
    int rd = term();
    fprintf(obj, "\tR%d=R%d%cR%d;\n", ri, ri, car[op], rd);
    libreg(rd);
  }
  return ri;
}

int expr() {
  int ri = arit();
  if (s==MENOR || s==MAYOR || s==IGUAL) {
    enum simb op = s;
    sigs();
    int rd = arit();
    if (s==IGUAL) fprintf(obj, "\tR%d=R%d==R%d;\n", ri, ri, rd);
    else fprintf(obj, "\tR%d=R%d%cR%d;\n", ri, ri, car[(int)op], rd);
    libreg(rd);
  }
  return ri;
}

void instr() {
  int r;
  switch (s) {
  case ID:;
    int l = loc(id);
    if (l==0) error(1009);
    if (sigs()!=ASIGN) error(1001);
    sigs();
    r = expr();
    if (s!=PYCOMA) error(1002);
    fprintf(obj, "\tI(R6%d)=R%d;\n", l, r);
    libreg(r);
    sigs();
    return;
  case PRINT:
    if (sigs()!=ABREPAR) error(1003);
    sigs();
    r = expr();
    if (s!=CIERRAPAR) error(1004);
    if (sigs()!=PYCOMA) error(1005);
    int e = etiq();
    fprintf(obj, "\
\tR2=R%d;\n\
\tR0=%d;\n\
\tR1=0x11ffc;\n\
\tGT(putf_);\n\
L %d:", r, e, e);
    libreg(r);
    sigs();
    return;
  case WHILE:;
    int ec = etiq(), eb = etiq();
    fprintf(obj, "L %d:", ec);
    if (sigs()!=ABREPAR) error(1006);
    sigs();
    r = expr();
    if (s!=CIERRAPAR) error(1007);
    fprintf(obj, "\tIF(!R%d) GT(%d);\n", r, eb);
    libreg(r);
    sigs();
    instr();
    fprintf(obj, "\tGT(%d);\nL %d:", ec, eb);
    return;
  case ABRELLAVE:
    sigs();
    while (s!=CIERRALLAVE) instr();
    sigs(); 
    return;    
  default: error(1008); // se espera instruccion
  }
}

void decl() {
  if (s!=INT) error(1101);
  if (sigs()!=ID) error(1102);
  if (!ins(id)) error(1104); 
  if (sigs()!=PYCOMA) error(1103);
  sigs();
}

void programa() {
  fprintf(obj, "\
#include \"Q.h\"\n\
BEGIN\n\
STAT(0)\n\
\tSTR(0x11ffc,\"%%i\\n\");\n\
CODE(0)\n");  
  while (s==INT) decl();
  fprintf(obj, "L 0:\tR6=R7;\n\tR7=R7%d;\n", top);
  while (s!=FIN) instr();
  fprintf(obj, "\tGT(-2);\nEND\n");
}

int main(int argc, char *argv[]) { 
  fte = fopen(argv[1], "r");
  obj = fopen(argv[2], "w");
  nv = 0;
  top = 0;
  sigc();
  sigs(); 
  programa();
  fclose(fte);
  fclose(obj);
  if (dbg) dmp();
  return 0;
}
