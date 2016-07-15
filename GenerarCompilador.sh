#!/bin/bash
clear
rm "compiladorSetu"
rm "sintactico.tab.c"
rm "sintactico.output"
rm "sintactico.tab.h"
rm "lex.yy.c"
bison -v -d sintactico.y
flex lexico.l
g++ -o compiladorSetu sintactico.tab.c lex.yy.c symbtab.cpp
chmod +x compiladorSetu

