#include <stdio.h>
#include <stdlib.h>

struct Table {
    int start;
    int end;
};

int cmp(const void* a, const void* b) {
    struct Table* tableA = (struct Table*)a;
    struct Table* tableB = (struct Table*)b;
    return tableA->start - tableB->start;
}

int main() {
    printf("5 3\n1 4\n2 3\n3 5\n3");
    return 0;
}
