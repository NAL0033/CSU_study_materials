#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
bool searchTarget(int** arr, int m, int n,int target) {
    int i = 0; int j = n - 1;
    while (i<=n&&j>=0) {
        if (arr[i][j] == target)
            return true;
        else if (arr[i][j] > target)
            j--;
        else
            i++;
    }
    return false;
}
/*int main() {
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
    int target;
    printf("taget:");
    scanf("%d", &target);
    if (searchTarget(arr,m,n,target))
        printf("找到了");
    else
        printf("没找到");
    for (int i = 0; i < m; i++) {
        free(arr[i]);
    }
    free(arr);
	return 0;
}*/