#include <stdio.h>
#include <string.h>

#define MAXS 512

long long dp[10][100][82];

int state[100];     // 所有合法状态
int num[100];       // 每个状态放几个监测器
int tot = 0;

int main()
{
    int n, K;
    scanf("%d%d", &n, &K);

    int limit = 1 << n;

    // 枚举所有合法状态
    for (int s = 0; s < limit; s++)
    {
        if ((s & (s << 1)) == 0)
        {
            state[tot] = s;
            num[tot] = __builtin_popcount(s);
            tot++;
        }
    }

    memset(dp, 0, sizeof(dp));

    // 初始化第一行
    for (int i = 0; i < tot; i++)
    {
        if (num[i] <= K)
            dp[1][i][num[i]] = 1;
    }

    // DP
    for (int row = 2; row <= n; row++)
    {
        for (int cur = 0; cur < tot; cur++)
        {
            for (int pre = 0; pre < tot; pre++)
            {
                int a = state[cur];
                int b = state[pre];

                // 两行兼容
                if ((a & b) == 0 &&
                    ((a << 1) & b) == 0 &&
                    ((a >> 1) & b) == 0)
                {
                    for(int k=cnt[cur];k<=K;k++){
                        dp[row][cur][k]+=dp[row-1][pre][k-cnt[cur]];
                    }
                }
            }
        }
    }

    long long ans = 0;

    if (n == 1)
    {
        for (int i = 0; i < tot; i++)
            ans += dp[1][i][K];
    }
    else
    {
        for (int i = 0; i < tot; i++)
            ans += dp[n][i][K];
    }

    printf("%lld\n", ans);

    return 0;
}