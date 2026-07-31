#include <stdio.h>
#include <string.h>

long long dp[15][2][4][10][4];
int dig[15];
int len;

long long dfs(int pos, int lead, int limit, int has_tri, int state, int last, int consec) {
    // 处理完所有数位，判断是否合法
    if (pos == len) {
        return (has_tri && state != 3) ? 1 : 0;
    }
    // 记忆化：无约束且非前导零时直接返回缓存结果
    if (!limit && !lead && dp[pos][has_tri][state][last][consec] != -1) {
        return dp[pos][has_tri][state][last][consec];
    }

    int up = limit ? dig[pos] : 9;
    long long res = 0;

    for (int d = 0; d <= up; d++) {
        int new_lead = lead && (d == 0);
        int new_limit = limit && (d == up);

        if (new_lead) {
            // 仍然是前导零，保持初始状态
            res += dfs(pos + 1, new_lead, new_limit, 0, 0, 0, 0);
        } else {
            int new_has_tri = has_tri;
            int new_state = state;
            int new_last = d;
            int new_consec;

            if (lead) {
                // 第一个有效数字
                new_has_tri = 0;
                if (d == 4) {
                    new_state = 1;
                } else if (d == 8) {
                    new_state = 2;
                } else {
                    new_state = 0;
                }
                new_consec = 1;
            } else {
                // 更新连续长度
                if (d == last) {
                    new_consec = consec + 1;
                } else {
                    new_consec = 1;
                }
                // 标记是否出现三个连续相同数字
                new_has_tri = has_tri || (new_consec >= 3);

                // 更新4和8的状态
                if (state == 3) {
                    new_state = 3;
                } else if (d == 4) {
                    new_state = (state == 2) ? 3 : 1;
                } else if (d == 8) {
                    new_state = (state == 1) ? 3 : 2;
                } else {
                    new_state = state;
                }

                // 压缩连续长度：超过2的都按2算，减少状态数
                if (new_consec > 2) {
                    new_consec = 2;
                }
            }
            res += dfs(pos + 1, new_lead, new_limit, new_has_tri, new_state, new_last, new_consec);
        }
    }

    // 记忆化存储
    if (!limit && !lead) {
        dp[pos][has_tri][state][last][consec] = res;
    }
    return res;
}

long long solve(long long x) {
    // 小于100的数不可能有三个连续数字，直接返回0
    if (x < 100) return 0;

    len = 0;
    // 拆分数字为数位数组（低位在前）
    while (x > 0) {
        dig[len++] = x % 10;
        x /= 10;
    }
    // 反转数位数组，变为高位在前
    for (int i = 0, j = len - 1; i < j; i++, j--) {
        int temp = dig[i];
        dig[i] = dig[j];
        dig[j] = temp;
    }

    memset(dp, -1, sizeof(dp));
    return dfs(0, 1, 1, 0, 0, 0, 0);
}

int main() {
    long long L, R;
    scanf("%lld %lld", &L, &R);
    printf("%lld\n", solve(R) - solve(L - 1));
    return 0;
}
/*
#include <stdio.h>

// 判断一个数x是否合格
int is_valid(long long x) {
    int prev = -1;    // 记录上一位数字，初始设为-1（表示还没有上一位）
    int consec = 0;   // 当前数字连续出现的次数
    int has_tri = 0;  // 是否出现过三个连续相同数字
    int has4 = 0;     // 是否出现过数字4
    int has8 = 0;     // 是否出现过数字8

    // 逐位取出数字（从最低位到最高位）
    while (x > 0) {
        int d = x % 10; // 取出最后一位

        // 条件2：记录4和8是否出现
        if (d == 4) has4 = 1;
        if (d == 8) has8 = 1;

        // 条件1：判断连续相同数字
        if (d == prev) {
            consec++;
            if (consec >= 3) {
                has_tri = 1; // 出现了三个连续相同数字
            }
        } else {
            prev = d;   // 数字变了，更新上一位
            consec = 1; // 连续次数重置为1
        }

        x = x / 10; // 去掉最后一位
    }

    // 两个条件都满足才返回1：有三个连续 且 没有同时出现4和8
    return has_tri && !(has4 && has8);
}

int main() {
    long long L, R;
    scanf("%lld %lld", &L, &R);

    long long ans = 0;
    // 逐个枚举区间里的每个数
    for (long long i = L; i <= R; i++) {
        if (is_valid(i)) {
            ans++;
        }
    }

    printf("%lld\n", ans);
    return 0;
}*/