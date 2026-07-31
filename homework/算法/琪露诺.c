#include <stdio.h>

#define MAXN 200005
#define INF -1000000000

int N, L, R;
int A[MAXN];
int dp[MAXN];
int q[MAXN];
int l=0,r=0;
int head = 0, tail = 0;
int main() {
    scanf("%d %d %d", &N, &L, &R);
    for (int i = 0; i <= N; i++) {
        scanf("%d", &A[i]);
    }
    for (int i = 0; i <= N; i++) {
        dp[i] = INF;
    }
    dp[0] = 0;
    for (int i = L; i <= N; i++) {
        int add=i-L;
        while(l<r&&dp[q[r-1]]<=dp[add]){
        	r--;
		}
		q[r]=add;
		r++;
		while(l<r&&q[l]<i-R){
			l++;
		}
		dp[i]=dp[q[l]]+A[i];
    }
    int ans = INF;
    for (int i = N - R + 1; i <= N; i++) {
        if (i >= 0 && dp[i] > ans) {
            ans = dp[i];
        }
    }
    printf("%d\n", ans);
    return 0;
}
