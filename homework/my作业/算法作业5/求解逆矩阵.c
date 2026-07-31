#include "LU.h"
int inverseLU(double* A[N][N], double inv[N][N]) {
	double L[N][N] = { 0 }, U[N][N] = { 0 };
	int pivot[N];
	LUcomp(A, L, U, pivot);
	for (int col = 0; col < N; col++) {
		double y[N] = { 0 }, x[N] = { 0 }, e[N] = { 0 };
		e[col] = 1;
		for (int i = 0; i < N; i++) {//Ly=E，解y
			double sum = 0;
			for (int j = 0; j < i; j++) {
				sum += L[i][j] * y[j];
			}
			y[i] = e[i] - sum;
		}
		for (int i = N - 1; i >= 0; i--) {//Ux=y,解x
			double sum = 0;
			for (int j = i + 1; j < N; j++) {
				sum += U[i][j] * x[j];
			}
			x[i] = (y[i] - sum) / U[i][i];//把列向量x代入
		}
		for (int i = 0; i < N; i++) {
			inv[i][col] = x[i];
		}
	}
}
int main() {
	double A[N][N] = { {2,-1,0},{1,2,1},{3,0,1} };
	double inv[N][N];
	printf("LU 分解法 A ^ -1\n");
	if (inverseLU(A, inv))
		printMatrix(inv);
	else
		printf("矩阵不可逆");
	return 0;
}