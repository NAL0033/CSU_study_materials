#include <stdio.h>
#include <string.h>

// 计算二进制数中1的个数
int count_bits(int x) {
    int res = 0;
    while (x) {
        res += x & 1;
        x >>= 1;
    }
    return res;
}

int main() {
    int n, K;
    scanf("%d%d", &n, &K);

    int state[200];   // 存储所有合法的行状态
    int cnt[200];     // 对应状态中监测器的数量（1的个数）
    int m = 0;        // 合法状态总数

    // 预处理：枚举所有行内合法状态（无相邻1）
    for (int s = 0; s < (1 << n); s++) {
        if ((s & (s << 1)) == 0) {
            state[m] = s;
            cnt[m] = count_bits(s);
            m++;
        }
    }

    // dp[i][j][k]：前i行共放j个监测器，第i行用第k个合法状态的方案数
    long long dp[10][82][200];
    memset(dp, 0, sizeof(dp));
    dp[0][0][0] = 1; // 初始状态：第0行（虚拟空行），0个监测器，状态全空

    for (int i = 1; i <= n; i++) {
        for (int j = 0; j <= K; j++) {
            // 枚举上一行的所有状态
            for (int prev_idx = 0; prev_idx < m; prev_idx++) {
                if (dp[i-1][j][prev_idx] == 0) continue;
                int sp = state[prev_idx];

                // 枚举当前行的所有状态
                for (int curr_idx = 0; curr_idx < m; curr_idx++) {
                    int sc = state[curr_idx];

                    // 检查八方向是否冲突
                    if ((sp & sc) != 0)         continue; // 同列冲突
                    if ((sp & (sc << 1)) != 0)  continue; // 左斜冲突
                    if (((sp << 1) & sc) != 0)  continue; // 右斜冲突

                    int total = j + cnt[curr_idx];
                    if (total > K) continue;
                    dp[i][total][curr_idx] += dp[i-1][j][prev_idx];
                }
            }
        }
    }

    // 统计第n行放满K个的所有方案
    long long ans = 0;
    for (int k = 0; k < m; k++) {
        ans += dp[n][K][k];
    }
    printf("%lld\n", ans);

    return 0;
}