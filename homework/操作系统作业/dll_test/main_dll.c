#include <stdio.h>

__declspec(dllimport)
int add(int, int);

int main() {
    printf("dynamic link result = %d\n", add(3, 4));
    return 0;
}