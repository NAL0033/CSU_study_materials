/*#include <stdio.h>
int main() {
	int arr[3000] = { 0 };
	int count = 0;
	for (int i = 3; i <=2200; i++) {
		for (int j = i-1; j >=1; j--) {
			int cnt = 0;
			if ((i * j) % (i + j) == 0)
			{
				++cnt;
				arr[i] = cnt;
			}
			count += cnt;
			arr[i] = count;
		}
	}
	int n;
	while (scanf("%d", &n)!=EOF) {
		printf("%d\n", arr[n]);
	}
}
*/
/*#include <stdio.h>
int main() {
	int T;
	while (scanf("%d", &T) != EOF) {
		while (T--) {
			int arr[12] = { 0,31,28,31,30,31,30,31,31,30,31,30};
			int y, m, d;
			scanf("%d-%d-%d", &y, &m, &d);
			int d1 = 0;
			for (int i = y; i < 2021; i++)
			{
				if ((i % 4 == 0 && i % 100 != 0) || i % 400 == 0) {
					d1 += 366;
				}
				else
				    d1 += 365;
			}
			int d2 = d;
			if (((y % 4 == 0) && (y % 100 != 0)) || y % 400 == 0)
			{
				arr[2] = 29;
			}
			for (int j = 1; j < m; j++) {
				d2 += arr[j];
			}
				printf("%d\n", d1 - d2 + 2);
		}
	}
}*/
/*#include <stdio.h>
#include <string.h>
#include <math.h>
int prime(int n) {
	if (n == 1)return 1;
	if (n == 2)return 0;
	for (int i = 2; i * i < n; i++) {
		if (n / i == 0) {
			return 1;//1则不是素数
			break;
		}
	}
	return 0;
}
int sum(int n) {
	int res = 0;
	while (n) {
		res += n % 10;
		n = n / 10;
	}
	return res;
}
int judge(int n) {
	while (n) {
		if (prime(n) == 0) {
			return 0;
		}
		n /= 10;
	}
	return 1;
}
int main() {
	char str[10003];
	int m;
	while (scanf("%s %d", &str,&m) != EOF) {
		int len = strlen(str);
		int arr[10003];
		int cnt = 0;
		for (int i = 0;i<len-m; i += m) {
			int sum = 0;
			for (int j = 0; j <m; j++) {
				sum += (str[i + j] - '0') * pow(10, m - j - 1);
			}
			arr[cnt++] = sum;
		}
		if (len % m != 0) {
			int c = len % m;
			int sumyu = 0;
			int c1 = --c;
			for (int i = len - c-1; i < len; i++) {
				if (c1 != 0)
					sumyu += (str[i] - '0') * pow(10, c1--);
				else
					sumyu += str[i]-'0';
			}
			arr[cnt++] = sumyu;
		}
		int type1[cnt], type2[cnt], type3[cnt], type4[cnt];
		int c1 = 0, c2 = 0, c3 = 0, c4 = 0;
		for (int i = 0; i < cnt; i++) {
			if (prime(arr[i])==0) {
				type1[c1++] = arr[i];
			}
			else if (prime(sum(arr[i])) == 0) {
				type2[c2++] = arr[i];
			}
			else if (judge(arr[i]) == 0) {
				type3[c3++] = arr[i];
			}
			else
				type4[c4++] = arr[i];
		}
		int max = c1 > c2 ? c1 : c2;
		max= max > c3 ? max : c3;
		max = max > c4 ? max : c4;
		int temp = max;
		int k,count=0;
		for (k = 1; k < max; k += 2) {
			temp -= k;
			count++;
			if (temp < 0) {
				break;
			}
		}
		int idx1 = 0, idx2 = 0, idx3 = 0, idx4 = 0;
		int row = 2 * count + 1;
		int col = 2 * count + 1;
		int mid = row / 2;
		int matrix[row][col];
		for (int i = 0; i < mid; i++) {
			for (int j = i+1; j < col-i; j++) {
				if (idx1 < c1)
					matrix[i][j] = type1[idx1++];
				else
					matrix[i][j] = 0;
			}
		}
		for (int i = 1; i < k; i++) {
			for (int j = 0; j < max; j++) {
				if (idx2 < c2) {
					matrix[i][j] = type2[idx2++];
				}
				else {
					matrix[i][j] = 0;
				}
			}
		}

		// 填充右三角区（3类）
		for (int i = 1; i < k; i++) {
			for (int j = k - max; j < k; j++) {
				if (idx3 < c3) {
					matrix[i][j] = type3[idx3++];
				}
				else {
					matrix[i][j] = 0;
				}
			}
		}

		// 填充下三角区（4类）
		for (int i = mid + 1; i < k; i++) {
			for (int j = k - i; j < i; j++) {
				if (idx4 < c4) {
					matrix[i][j] = type4[idx4++];
				}
				else {
					matrix[i][j] = 0;
				}
			}
		}
	}

		//打印
		for (int i = 0; i < row; i++) {
			for (int j = 0; j < col; j++) {
				if (i == j || i == col - j - 1) {
					printf("*");
				}
				else
					printf("%d", matrix[i][j]);
			}
			printf("\n");
		}
	}
	return 0;
}*/
/*#include <stdio.h>
#include <string.h>
#include <stdlib.h>
int main() {
	char str[10003];
	int m;
	while (scanf("%s %d", &str, &m) != EOF) {
		int len = strlen(str);
		int len1 = (len+m-1) / m;
		int* arr = (int*)malloc(sizeof(int) * len1);
		int cnt = 0;
		for (int i = 0; i < len1; i ++) {
			int start = i * m;
			int end = start + m;
			if (end >= len) {
				end = len;
			}
			int num = 0;
			for (int j = start; j < end; j++) {
				num = num * 10 + (str[j] - '0');
			}
			arr[cnt++] = num;
		}
		int class1[10000], c1 = 0;
		int class2[10000], c2 = 0;
		int class3[10000], c3 = 0;
		int class4[10000], c4 = 0;
		for (int i = 0; i < cnt; i++) {
			int x = arr[i];
			if (isprime(x)) {
				class1[c1++] = x;
			}
			else if (digitSumIsPrime(x)) {
				class2[c2++] = x;
			}
			else if (hasPrimeDigit(x)) {
				class3[c3++] = x;
			}
			else {
				class4[c4++] = x;
			}
		}
		// 创建矩阵并初始化为0
		int matrix[105][105];
		for (int i = 0; i < k; i++) {
			for (int j = 0; j < k; j++) {
				matrix[i][j] = 0;
			}
		}
		// 填充四个区域（按顺序）
		int idx1 = 0, idx2 = 0, idx3 = 0, idx4 = 0;
		// 找最小的奇数 k (3<=k<=101)
		int k = 3;
		while (k <= 101) {
			int upper = 0, left = 0, right = 0, lower = 0;
			for (int i = 0; i < k; i++) {
				for (int j = 0; j < k; j++) {
					if (i == j || i + j == k - 1) continue;
					if (i < j && i + j < k - 1) upper++;
					else if (i > j && i + j < k - 1) left++;
					else if (i < j && i + j > k - 1) right++;
					else if (i > j && i + j > k - 1) lower++;
				}
			}
			if (upper >= c1 && left >= c2 && right >= c3 && lower >= c4) {
				break;
			}
			k += 2; // 下一个奇数
		}
		// 上三角 (1类)
		for (int i = 0; i < k; i++) {
			for (int j = 0; j < k; j++) {
				if (i < j && i + j < k - 1) {
					if (idx1 < c1) {
						matrix[i][j] = class1[idx1++];
					}
					else {
						matrix[i][j] = 0;
					}
				}
			}
		}

		// 左三角 (2类)
		for (int i = 0; i < k; i++) {
			for (int j = 0; j < k; j++) {
				if (i > j && i + j < k - 1) {
					if (idx2 < c2) {
						matrix[i][j] = class2[idx2++];
					}
					else {
						matrix[i][j] = 0;
					}
				}
			}
		}

		// 右三角 (3类)
		for (int i = 0; i < k; i++) {
			for (int j = 0; j < k; j++) {
				if (i < j && i + j > k - 1) {
					if (idx3 < c3) {
						matrix[i][j] = class3[idx3++];
					}
					else {
						matrix[i][j] = 0;
					}
				}
			}
		}

		// 下三角 (4类)
		for (int i = 0; i < k; i++) {
			for (int j = 0; j < k; j++) {
				if (i > j && i + j > k - 1) {
					if (idx4 < c4) {
						matrix[i][j] = class4[idx4++];
					}
					else {
						matrix[i][j] = 0;
					}
				}
			}
		}

		// 输出矩阵
		for (int i = 0; i < k; i++) {
			for (int j = 0; j < k; j++) {
				if (i == j || i + j == k - 1) {
					printf("%5s", "*");
				}
				else {
					printf("%5d", matrix[i][j]);
				}
			}
			printf("\n");
		}
		free(arr);
	}
	return 0;
}*/
