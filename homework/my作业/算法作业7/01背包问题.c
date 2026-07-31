#include <stdio.h>
#include <stdlib.h>
int maxw(int n, int m) {
	return n > m ? n : m;
}
/*int main() {
	int n;
	printf("请输入魔卡数量：");
	scanf_s("%d", &n);
	int* arr = (int*)malloc(sizeof(int) * (n+1));
	int sum = 0;
	printf("请输入魔卡价值：");
		for (int i = 1; i <= n; i++) {
			scanf_s("%d", &arr[i]);
			sum += arr[i];
	}
		int T = (int)(sum / 2);//使目标尽量接近sum/2
		int* dp = (int*)malloc(sizeof(int) * (T + 1));
		for (int j = 0; j <= T; j++) {//初始化dp数组
			dp[j] = 0;
		}
		for (int i = 1; i <= n; i++) {
			for (int j = T; j >= arr[i]; j--) {
				dp[j] = maxw(dp[j], dp[j - arr[i]] + arr[i]);
			}
		}
		int S1 = dp[T];
		int S2 = sum - S1;
		int diff = sum - (S1 + S2);
		printf("ChildA:%d\n", S1);
		printf("ChildB:%d\n", S2);
		printf("Difference:%d\n", diff);
		free(arr);
		free(dp);
		return 0;
}*/