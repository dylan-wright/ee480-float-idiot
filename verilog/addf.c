#include <stdio.h>

int main()
{
    float xf,yf,zf;
    scanf("%f %f", &xf, &yf);
    zf = xf+yf;
    unsigned int xi = *((unsigned int *) &xf);
    unsigned int yi = *((unsigned int *) &yf);
    unsigned int zi = *((unsigned int *) &zf);
    printf("%04x %04x\n", xi>>16, yi>>16);
    printf("%04x\n", zi);
    return 0;
}
