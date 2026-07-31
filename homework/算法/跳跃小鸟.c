#include <stdio.h>
#include <limits.h>

#define MAX_N 100005
#define MAX_Q 1005

int main() {
    int n;
    scanf("%d", &n);

    int d[MAX_N];
    for(int i=1; i<=n; i++) {
        scanf("%d", &d[i]);
    }

    int q;
    scanf("%d", &q);

    int k[MAX_Q];
    for(int i=1; i<=q; i++) {
        scanf("%d", &k[i]);
    }

    // 每只鸟计算最小劳累值
    for(int b=1; b<=q; b++) {
        int dp[MAX_N];
        for(int i=1; i<=n; i++) dp[i] = INT_MAX;
        dp[1] = 0;  // 从第1棵树开始

        for(int i=1; i<=n; i++) {
            for(int j=1; j<=k[b]; j++) {
                if(i+j > n) break;
                int cost = (d[i+j] >= d[i]) ? 1 : 0;
                if(dp[i+j] > dp[i] + cost) {
                    dp[i+j] = dp[i] + cost;
                }
            }
        }

        printf("%d\n", dp[n]);
    }

    return 0;
}