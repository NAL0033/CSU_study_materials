/*#include <stdio.h>
#include <stdlib.h>
int* mergeTwoArr(int* arr1, int size1, int* arr2, int size2) {
    int* merged = (int*)malloc((size1 + size2) * sizeof(int));
    int i = 0; int j = 0; int idx = 0;
    while (i < size1 && j < size2) {
        merged[idx++] = arr1[i] < arr2[j] ? arr1[i++] : arr2[j++];
    }
    while (i < size1) 
        merged[idx++] = arr1[i++];
    while (j < size2) 
        merged[idx++] = arr2[j++];
    return merged;
}//合并两数组
int* findKthsmall(int** arr, int m, int n, int k) {
    int* merged = (int*)malloc(n * sizeof(int));
    int mergedSize = n;
    for (int i = 0; i < n; i++)
        merged[i] = arr[0][i];//初始合并第一行
    for (int i = 1; i < m; i++) {//逐行合并
        int* temp = mergeTwoArr(merged, mergedSize, arr[i], n);
        free(merged);
        merged = temp;
        mergedSize += n;
        if (mergedSize > k) {//优化：若合并后数组元素>K,可提前截取
            int* tempK = (int*)malloc(k * sizeof(int));
            for (int j = 0; j < k; j++) 
                tempK[j] = merged[j];
            free(merged);
            merged = tempK;
            mergedSize = k;
        }
    }
    int result = merged[k - 1];
    free(merged);
    return result;
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
    printf("归并法求第K小元素为：%d, findKthsmall(arr, m, n, k));
    for (int i = 0; i < m; i++) 
        free(arr[i]);
    free(arr);
    return 0;
}*/