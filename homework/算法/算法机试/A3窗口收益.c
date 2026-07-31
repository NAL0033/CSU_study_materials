#include <stdio.h>

#define MAXN 500005

typedef long long ll;

ll sum[MAXN];
int q[MAXN];

int main() {
    int n, m;
    scanf("%d%d", &n, &m);

    sum[0] = 0;
    for (int i = 1; i <= n; i++) {
        ll x;
        scanf("%lld", &x);
        sum[i] = sum[i - 1] + x;
    }

    int head = 0, tail = 0;
    q[tail++] = 0;

    ll ans = -(1LL << 60);

    for (int i = 1; i <= n; i++) {
        // 删除长度超过 m 的前缀
        while (head < tail && q[head] < i - m)
            head++;

        // 更新答案
        if (head < tail) {
            ll cur = sum[i] - sum[q[head]];
            if (cur > ans)
                ans = cur;
        }

        // 维护前缀和单调递增
        while (head < tail && sum[q[tail - 1]] >= sum[i])
            tail--;

        q[tail++] = i;
    }

    printf("%lld\n", ans);

    return 0;
}