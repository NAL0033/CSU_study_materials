#include <stdio.h>

#define MAX_S 50
#define MAX_D 15

typedef struct { int r, c; } Square;
typedef struct { long long r_k[MAX_D + 1]; } Poly;

long long fact(int n) {
    long long res = 1;
    for (int i = 2; i <= n; i++) res *= i;
    return res;
}

Poly add(Poly p1, Poly p2) {
    Poly res = { 0 };
    for (int i = 0; i <= MAX_D; i++) res.r_k[i] = p1.r_k[i] + p2.r_k[i];
    return res;
}

Poly shift(Poly p) {
    Poly res = { 0 };
    for (int i = 0; i < MAX_D; i++) res.r_k[i + 1] = p.r_k[i];
    return res;
}

Poly solve(Square* sq, int n) {
    Poly res = { 0 };
    if (n == 0) {
        res.r_k[0] = 1;
        return res;
    }

    Square p = sq[0];
    Square b1[MAX_S], b2[MAX_S];
    int n1 = 0, n2 = 0;

    for (int i = 1; i < n; i++) {
        if (sq[i].r != p.r && sq[i].c != p.c) b1[n1++] = sq[i];
        b2[n2++] = sq[i];
    }

    return add(shift(solve(b1, n1)), solve(b2, n2));
}

int main() {
    int rows, cols, num_f;
    Square f[MAX_S];

    printf("请输入棋盘行数和列数: ");
    scanf("%d %d", &rows, &cols);
    printf("请输入禁位数量: ");
    scanf("%d", &num_f);

    printf("请输入每个禁位的坐标 (行 列):\n");
    for (int i = 0; i < num_f; i++) scanf("%d %d", &f[i].r, &f[i].c);

    Poly poly = solve(f, num_f);

    long long N = 0;
    int limit = (rows < cols) ? rows : cols;

    for (int k = 0; k <= limit; k++) {
        if (poly.r_k[k] == 0) continue;

        long long perm = 1;
        for (int i = 0; i < rows - k; i++) perm *= (cols - k - i);

        if (k % 2 == 0) N += poly.r_k[k] * perm;
        else N -= poly.r_k[k] * perm;
    }

    printf("\n车多项式系数 r_k: ");
    for (int k = 0; k <= limit; k++) printf("r%d=%lld ", k, poly.r_k[k]);

    printf("\n满足条件的排列总数 N = %lld\n", N);

    return 0;
}