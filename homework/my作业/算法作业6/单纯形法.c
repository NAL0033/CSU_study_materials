#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define MAX_M 10
#define MAX_N 10
#define EPS 1e-9

void print_table(double T[MAX_M + 1][MAX_N + MAX_M + 2], int m, int n) {
    printf("\nTableau:\n");
    for (int i = 0; i <= m; i++) {
        for (int j = 0; j <= n + m; j++) printf("%8.3f ", T[i][j]);
        printf("\n");
    }
}

int main() {
    int m = 3, n = 2; // 例子: max 3x1+2x2
    double A[3][2] = { {1,1},{1,0},{0,1} };
    double b[3] = { 4,2,3 };
    double c[2] = { 3,2 };

    double T[MAX_M + 1][MAX_N + MAX_M + 2] = { 0 };
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) T[i][j] = A[i][j];
        T[i][n + i] = 1; // slack
        T[i][n + m] = b[i];
    }
    // 目标行
    for (int j = 0; j < n; j++) T[m][j] = -c[j];

    print_table(T, m, n);

    while (1) {
        // 找入基变量
        int pivot_col = -1;
        double max_sigma = 0;
        for (int j = 0; j < n + m; j++) {
            if (T[m][j] > max_sigma + EPS) {
                max_sigma = T[m][j];
                pivot_col = j;
            }
        }
        if (pivot_col == -1) break; // 最优

        // 比值检验
        int pivot_row = -1;
        double min_theta = 1e9;
        for (int i = 0; i < m; i++) {
            if (T[i][pivot_col] > EPS) {
                double theta = T[i][n + m] / T[i][pivot_col];
                if (theta < min_theta - EPS) {
                    min_theta = theta;
                    pivot_row = i;
                }
            }
        }
        if (pivot_row == -1) {
            printf("无界解！\n");
            return 0;
        }

        // 枢轴
        double pivot = T[pivot_row][pivot_col];
        for (int j = 0; j <= n + m; j++) T[pivot_row][j] /= pivot;

        for (int i = 0; i <= m; i++) {
            if (i == pivot_row) continue;
            double factor = T[i][pivot_col];
            for (int j = 0; j <= n + m; j++)
                T[i][j] -= factor * T[pivot_row][j];
        }

        print_table(T, m, n);
    }

    printf("\n最优解：\n");
    printf("Z = %.3f\n", T[m][n + m]);
    return 0;
}
