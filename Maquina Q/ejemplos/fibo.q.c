#include "Q.h" 
#define C R7    // cima de la pila 
#define B R6    // base del marco actual 
#define INI 0   // comienzo ejecución
#define FIN -2  // finaliza ejecución
BEGIN
L 2:    B=C;                    // comienza fibo; nueva base 
        C=C-16;                 // toma pila área actual (1 temporal) 
        R0=I(B+8);              // parámetro n 
        IF (R0<=1) GT(3);       // test n>1 invertido 
        R0=R0-1;                // n-1 
        I(C+8)=R0;              // pasa n-1 
        P(C+4)=B;               // guarda base actual 
        P(C)=4;                 // pasa "direccion" de retorno 
        GT(2);                  // llama fibo(n-1) 
L 4:    P(B-4)=R0;              // guarda resultado de fibo(n-1) 
        R0=I(B+8);              // parámetro n 
        R0=R0-2;                // n-2 
        I(C+8)=R0;              // pasa n-2 
        P(C+4)=B;               // guarda base actual 
        P(C)=5;                 // pasa "direccion" de retorno 
        GT(2);                  // llama fibo(n-2) 
L 5:    R1=I(B-4);              // recupera fibo(n-1) 
        R0=R1+R0;               // fibo(n-1)+fibo(n-2) 
L 3:    C=B;                    // libera area actual 
        B=P(C+4);               // recupera base anterior 
        R5=P(C);                // recupera direccion de retorno 
        GT(R5);                 // retorna 
L 6:    B=C;                    // comienza main; nueva base 
        C=C-16;                 // toma pila para llamadas
        R3=0;                   // R3 sera i (area actual "vacia") 
L 7:    IF (R3>30) GT(8);       // test i<=25 invertido 
STAT(0)
    STR(0x11ff6,"fibo(%i)=");   // U(0x11ff6)='f' .. U(0x11fff)='\0' (10 bytes) 
    STR(0x11ff2,"%i\n");        // U(0x11ff2)='%' .. U(0x11ff5)='\0' (4 bytes) 
CODE(0)
        R1=0x11ff6;             // pasa direccion de "fibo(%i)=" 
        R2=R3;                  // pasa i
        R0=9;                   // pasa direccion de retorno 
        GT(putf_);              // llamada a visualizacion (ver Qlib.c) 
L 9:    R1=0x11ff2;             // direccion de "%i\n" 
        P(C+12)=R1;             // salva dir. str.
        I(C+8)=R3;              // pasa i 
        P(C+4)=B;               // guarda base actual 
        P(C)=10;                // pasa direccion de retorno 
        GT(2);                  // llama fibo(i) 
L 10:   R2=R0;                  // parámetro: valor de fibo(i)
        R1=P(C+12);             // recup. parámetro: dir. str.        
        R0=11;                  // pasa direccion de retorno 
        GT(putf_);              // llamada a visualizacion 
L 11:   R3=R3+1;                // i++ 
        GT(7);                  // siguiente iteracion 
L 8:    C=B;                    // devuelve pila 
        B=P(C+4);               // recupera base anterior 
        R5=P(C);                // recupera direccion de retorno 
        GT(R5);                 // retorna 
L 0:    B=C;                    // comienza: inicializa base 
        GT(-1);                 // parada interactiva
        C=C-8;                  // toma pila para llamada 
        P(C+4)=B;               // guarda base actual 
        P(C)=1;                 // pasa direccion de retorno 
        GT(6);                  // llama a main 
L 1:    R0=0;                   // exito   
        GT(FIN);                // termina 
END
