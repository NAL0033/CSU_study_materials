#include <stdio.h>
#include <string.h>

int n, m;
int terrain[105];        // 每行的山地位掩码
int states[70];          // 预处理的行内合法状态
int cnt[70];             // 每个合法状态中1的个数
int total;               // 合法状态总数

// dp[j][k]: 上一行状态为states[j]，上上行状态为states[k]时的最大炮兵数
int dp[70][70];
int ndp[70][70];

int popcount(int x) {
    int c = 0;
    while (x) { c++; x &= x - 1; }
    return c;
}

int main() {
    char line[15];
    scanf("%d%d", &n, &m);

    for (int i = 0; i < n; i++) {
        scanf("%s", line);
        terrain[i] = 0;
        for (int j = 0; j < m; j++) {
            if (line[j] == 'H')
                terrain[i] |= (1 << j);
        }
    }

    // 预处理：找出所有行内不自相攻击的状态
    total = 0;
    for (int s = 0; s < (1 << m); s++) {
        if ((s & (s << 1)) == 0 && (s & (s << 2)) == 0) {
            states[total] = s;
            cnt[total] = popcount(s);
            total++;
        }
    }

    // 初始化dp为-1表示不可达
    memset(dp, -1, sizeof(dp));

    // 处理第0行：上一行和上上行都视为空(状态0，即states[0]=0)
    for (int j = 0; j < total; j++) {
        if ((states[j] & terrain[0]) == 0) {
            dp[j][0] = cnt[j];  // 上一行是j，上上行是0(空)
        }
    }

    // 逐行转移
    for (int i = 1; i < n; i++) {
        memset(ndp, -1, sizeof(ndp));
        for (int a = 0; a < total; a++) {
            // 当前行状态不能占山地
            if (states[a] & terrain[i]) continue;
            for (int b = 0; b < total; b++) {
                // 当前行和前一行不冲突
                if (states[a] & states[b]) continue;
                for (int c = 0; c < total; c++) {
                    // 当前行和前前行不冲突
                    if (states[a] & states[c]) continue;
                    if (dp[b][c] == -1) continue;
                    int val = dp[b][c] + cnt[a];
                    if (val > ndp[a][b])
                        ndp[a][b] = val;
                }
            }
        }
        memcpy(dp, ndp, sizeof(dp));
    }

    int ans = 0;
    for (int j = 0; j < total; j++)
        for (int k = 0; k < total; k++)
            if (dp[j][k] > ans)
                ans = dp[j][k];

    printf("%d\n", ans);
    return 0;
}