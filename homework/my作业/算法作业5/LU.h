#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define N 3
void printMatrix(double arr[N][N]) {
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			printf("%.4lf\t", arr[i][j]);
		}
		printf("\n");
	}
}
void swap(double arr[N][N],int row1,int row2) {//交换两行 
	for (int i = 0; i < N; i++) {
		double temp = arr[row1][i];
		arr[row1][i] = arr[row2][i];
		arr[row2][i] = temp;
	}
}
int LUcomp(double A[N][N], double L[N][N], double U[N][N], int pivot[N]) {
	for (int i = 0; i < N; i++) {
		pivot[i] = i;
	}
	for (int i = 0; i < N; i++) {//列
		int pivotrow = i;//主元
		for (int j = i + 1; j < N; j++) {//行
			if (fabs(A[j][i]) > fabs(A[pivotrow][i])) {
				pivotrow = j;
			}
		}
		if (pivotrow != i) {
			swap(A, pivotrow, i);//交换两行
			int temp = pivot[i];//记录置换
			pivot[i] = pivot[pivotrow];
			pivot[pivotrow] = temp;
		}
		if (A[i][i] == 0) {
			return 0;
		}
		for (int j = i + 1; j < N; j++) {//行
			L[j][i] = A[j][i] / A[i][i];
			for (int k = i; k < N; k++) {
				A[j][k] = A[j][k] - A[i][k] * L[j][i];
			}
		}	
	}
	for (int m = 0; m < N; m++) {//构造L和U矩阵
		for (int n = 0; n < N; n++) {
			if (n > m) {
				U[m][n] = A[m][n];
				L[m][n] = 0.0;
			}
			else if (n == m) {
				U[m][n] = A[m][n];
				L[m][n] = 1.0;
			}
			else {
				U[m][n] = 0;
			}
		}
	}
	return 1;
}
/*int main() {
	double A[N][N] = { {2,-1,1},{4,1,-1},{1,1,1} };
	double L[N][N] = { 0 },U[N][N] = { 0 };
	int pivot[N];
	if (LUcomp(A, L, U, pivot)) {
		printf("L的矩阵为：\n");
		printMatrix(L);
		printf("U的矩阵为：\n");
		printMatrix(U);
	}
	else {
		printf("矩阵不可逆");
	}
	return 0;
}*/