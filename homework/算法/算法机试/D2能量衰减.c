#include <stdio.h>
#include <math.h>

#define MAXN 100005

long long sum[4 * MAXN];   // 区间和
long long max_val[4 * MAXN]; // 区间最大值
long long a[MAXN];

// 安全的整数开平方，保证向下取整正确，避免浮点数精度误差
long long sqrt_ll(long long x) {
    if (x == 0) return 0;
    long long res = (long long)sqrt(x);
    // 修正可能的误差
    while (res*res>x)res--;
    while ((res+1)*(res+1)<=x)res++;
    return res;
}

// 向上更新：合并左右子节点信息
void push_up(int node) {
    sum[node] = sum[node * 2] + sum[node * 2 + 1];
    max_val[node] = (max_val[node * 2] > max_val[node * 2 + 1]) ? max_val[node * 2] : max_val[node * 2 + 1];
}

// 构建线段树
void build(int node, int l, int r) {
    if (l == r) {
        sum[node] = a[l];
        max_val[node] = a[l];
        return;
    }
    int mid = (l + r) / 2;
    build(node * 2, l, mid);
    build(node * 2 + 1, mid + 1, r);
    push_up(node);
}

// 区间开平方
void update(int node, int l, int r, int ul, int ur) {
    // 区间无交集
    if (ur < l || ul > r) {
        return;
    }
    // 正确剪枝：区间最大值不超过1，开平方不会变，直接跳过
    if (max_val[node] <= 1) {
        return;
    }
    // 叶子节点，直接修改
    if (l == r) {
        long long val = sqrt_ll(sum[node]);
        sum[node] = val;
        max_val[node] = val;
        return;
    }
    int mid = (l + r) / 2;
    update(node * 2, l, mid, ul, ur);
    update(node * 2 + 1, mid + 1, r, ul, ur);
    push_up(node);
}

// 区间求和
long long query(int node, int l, int r, int ql, int qr) {
    if (qr < l || ql > r) {
        return 0;
    }
    if (ql <= l && r <= qr) {
        return sum[node];
    }
    int mid = (l + r) / 2;
    return query(node * 2, l, mid, ql, qr) + query(node * 2 + 1, mid + 1, r, ql, qr);
}

int main() {
    int n;
    scanf("%d", &n);
    for (int i = 1; i <= n; i++) {
        scanf("%lld", &a[i]);
    }
    build(1, 1, n);

    int m;
    scanf("%d", &m);
    while (m--) {
        int op, l, r;
        scanf("%d%d%d", &op, &l, &r);
        // 交换端点
        if (l > r) {
            int temp = l;
            l = r;
            r = temp;
        }
        if (op == 0) {
            update(1, 1, n, l, r);
        } else {
            printf("%lld\n", query(1, 1, n, l, r));
        }
    }
    return 0;
}
