#include <stdio.h>
#include <stdlib.h>
int countLessOrEqual(int** arr, int m, int n, int mid) {
    int i = 0, j = n - 1, count = 0;
    while (i < m && j >= 0) {
        if (arr[i][j] <= mid) {
            count += j + 1; // 当前行左侧j+1个元素均符合
            i++; // 向下移一行
        }
        else {
            j--; // 向左移一列
        }
    }
    return count;
}
int findKthsmall(int** arr, int m, int n, int k) {
    int left = arr[0][0];
    int right = arr[m - 1][n - 1];
    while (left < right) {
        int mid = left + (right - left) / 2; // 避免溢出
        int cnt = countLessOrEqual(arr, m, n, mid);
        if (cnt < k) {
            left = mid + 1; // 第K小数在右侧
        }
        else {
            right = mid; // 第K小数在左侧（含mid）
        }
    }
    return left;
}
int main() {
    int m, n;
    printf("输入行数m与列数n\n");
    scanf("%d%d", &m, &n);
    int** arr = (int**)malloc(m * sizeof(int*));
    for (int i = 0; i < m; i++) {
        arr[i] = (int*)malloc(sizeof(int) * n);
    }
    printf("输入矩阵元素：\n");
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            scanf("%d", &arr[i][j]);
        }
    }
    int k;
    printf("输入要查找的k(第K小)");
    scanf("%d", &k);
    printf("二分法求第K小元素为：%d", findKthsmall(arr, m, n, k));
    for (int i = 0; i < m; i++)
            free(arr[i]);
    free(arr);
    return 0;
}