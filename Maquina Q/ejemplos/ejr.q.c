#include "Q.h"             
BEGIN
L 0:    R7=R7-40;
        R0 = 0;             
        R1 = 1;
L 1:    R2 = 4 * R0;        
        I(R2+R7) = R1;         
        R0 = R0 + 1;        
        R1 = R1 * R0;       
        IF (R0 < 10) GT(1); 
        GT(-1);            
        GT(-2);            
END                       
