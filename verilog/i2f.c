#include <stdio.h>

int main() 
{
    float f;
    scanf("%f", &f);;
    unsigned int i = *((unsigned int *) &f);
    printf("%04x\n", i>>16);
    //printf("%01x %02x %02x\n", sign, exp, sig);
    return 0;
}
