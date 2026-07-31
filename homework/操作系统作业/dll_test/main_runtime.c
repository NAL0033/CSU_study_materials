#include <windows.h>
#include <stdio.h>

int main() {
    HMODULE h = LoadLibraryA("add.dll");

    if (h == NULL) {
        printf("LoadLibrary failed\n");
        return 1;
    }

    int (*add)(int, int);
    add = (int (*)(int, int))GetProcAddress(h, "add");

    if (add == NULL) {
        printf("GetProcAddress failed\n");
        FreeLibrary(h);
        return 1;
    }

    printf("runtime dynamic link result = %d\n", add(5, 6));

    FreeLibrary(h);
    return 0;
}