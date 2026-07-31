#include <stdio.h>
#include <stdlib.h>

#define MAXN 200005

long long s[MAXN];    // 前缀和
long long val[MAXN];  // val[j] = s[j] + lst[j]，转移条件 val[j] <= s[i]
long long lst[MAXN];  // 前j个划分的最后一段和
__int128 dp[MAXN];    // 前i个的最小平方和
int sta[MAXN];        // 单调栈，存索引，对应val递增

// 输出__int128，printf不直接支持
void print(__int128 x) {
    if (x == 0) {
        printf("0\n");
        return;
    }
    int stk[50], top = 0;
    while (x > 0) {
        stk[top++] = x % 10;
        x /= 10;
    }
    for (int i = top - 1; i >= 0; i--) {
        printf("%d", stk[i]);
    }
    printf("\n");
}

int main() {
    int n, type;
    scanf("%d%d", &n, &type);
    s[0] = 0;
    for (int i = 1; i <= n; i++) {
        long long a;
        scanf("%lld", &a);
        s[i] = s[i-1] + a;
    }

    int top = 0;
    sta[0] = 0;
    val[0] = 0;
    dp[0] = 0;
    lst[0] = 0;

    for (int i = 1; i <= n; i++) {
        // 二分查找最大的j，满足val[j] <= s[i]
        int left = 0, right = top;
        int k = 0;
        while (left <= right) {
            int mid = (left + right) / 2;
            if (val[sta[mid]] <= s[i]) {
                k = mid;
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        int j = sta[k];
        long long diff = s[i] - s[j];
        dp[i] = dp[j] + (__int128)diff * diff;
        lst[i] = diff;
        val[i] = s[i] + lst[i];

        // 维护单调栈：弹出所有val >= 当前val的元素，保证递增
        while (top >= 0 && val[sta[top]] >= val[i]) {
            top--;
        }
        sta[++top] = i;
    }

    print(dp[n]);
    return 0;
}