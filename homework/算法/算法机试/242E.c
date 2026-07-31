// 题目描述
// 你得到了一个序列 a，其中包含 n 个元素 a1,a2,⋯,an。
// 你需要执行 m 个操作，分为两种：

// 1 l r：求 al∼ar 的和。
// 2 l r x：将 al∼ar 异或上 x。
// 输入描述
// 第一行，一个正整数 n，表示序列长度。

// 第二行，n 个非负整数 a1,a2,⋯,an。

// 第三行，一个正整数 m，表示操作个数。

// 接下来 m 行，每行 3 或 4 个正整数，表示一个操作。

// 输出描述
// 对每个操作 1，输出一行一个整数表示答案。

// 输入样例
// 5
// 4 10 3 13 7
// 8
// 1 2 4
// 2 1 3 3
// 1 2 4
// 1 3 3
// 2 2 5 5
// 1 1 5
// 2 1 2 10
// 1 2 3
// 6
// 4 7 4 0 7 3
// 5
// 2 2 3 8
// 1 1 5
// 2 3 5 1
// 2 4 5 6
// 1 2 3

// 输出样例
// 26
// 22
// 0
// 34
// 11
// 38
// 28

// 提示
// 1≤n≤105

// 1≤m≤5x105

// 1≤ai≤105

// 1≤x≤106

// 在 C++ 和 Java 中，异或符号为 ^，在 Pascal 中为 xor。

#include <stdio.h>
#include <string.h>

#define MAXN 100000
#define BITS 20
#define NODE_SIZE (4 * MAXN + 5)

int cnt[NODE_SIZE][BITS];
long long sum[NODE_SIZE];
int lazy[NODE_SIZE];
int a[MAXN + 5];

// 快速读入
int readint() {
    int x = 0;
    int c;
    while (1) {
        c = getchar();
        if (c == EOF) return -1;
        if (c >= '0' && c <= '9') break;
    }
    while (c >= '0' && c <= '9') {
        x = x * 10 + (c - '0');
        c = getchar();
    }
    return x;
}

// 合并孩子信息到父节点
void push_up(int node) {
    int left = node << 1;
    int right = left | 1;
    for (int i = 0; i < BITS; ++i) {
        cnt[node][i] = cnt[left][i] + cnt[right][i];
    }
    sum[node] = sum[left] + sum[right];
}

// 对节点 node 管辖的长度为 len 的区间整体异或 x
void apply(int node, int len, int x) {
    int t = x;
    while (t) {
        int lsb = t & -t;
        // 计算最低位 1 的位置
        int bit = 0;
        while (!(lsb & (1 << bit))) ++bit;  // 等价于内置 __builtin_ctz
        int c = cnt[node][bit];
        cnt[node][bit] = len - c;
        sum[node] += (long long)(len - 2 * c) << bit;
        t ^= lsb;
    }
    lazy[node] ^= x;
}

// 下传懒标记
void push_down(int node, int l, int r) {
    if (lazy[node]) {
        int mid = (l + r) >> 1;
        int left = node << 1;
        int right = left | 1;
        apply(left, mid - l + 1, lazy[node]);
        apply(right, r - mid, lazy[node]);
        lazy[node] = 0;
    }
}

// 建树
void build(int node, int l, int r) {
    lazy[node] = 0;
    if (l == r) {
        int val = a[l];
        sum[node] = val;
        for (int i = 0; i < BITS; ++i) {
            cnt[node][i] = (val >> i) & 1;
        }
        return;
    }
    int mid = (l + r) >> 1;
    int left = node << 1;
    int right = left | 1;
    build(left, l, mid);
    build(right, mid + 1, r);
    push_up(node);
}

// 区间异或更新
void update(int node, int l, int r, int ql, int qr, int x) {
    if (ql <= l && r <= qr) {
        apply(node, r - l + 1, x);
        return;
    }
    push_down(node, l, r);
    int mid = (l + r) >> 1;
    int left = node << 1;
    int right = left | 1;
    if (ql <= mid) update(left, l, mid, ql, qr, x);
    if (qr > mid) update(right, mid + 1, r, ql, qr, x);
    push_up(node);
}

// 区间求和查询
long long query(int node, int l, int r, int ql, int qr) {
    if (ql <= l && r <= qr) return sum[node];
    push_down(node, l, r);
    int mid = (l + r) >> 1;
    long long res = 0;
    if (ql <= mid) res += query(node << 1, l, mid, ql, qr);
    if (qr > mid) res += query((node << 1) | 1, mid + 1, r, ql, qr);
    return res;
}

int main() {
    int n;
    while ((n = readint()) != -1) {
        for (int i = 1; i <= n; ++i) a[i] = readint();
        int m = readint();
        
        // 初始化线段树（build 会覆盖 sum 和 cnt，但为了安全清一下 lazy）
        memset(lazy, 0, sizeof(lazy));
        build(1, 1, n);
        
        for (int i = 0; i < m; ++i) {
            int op = readint();
            if (op == 1) {
                int l = readint(), r = readint();
                printf("%lld\n", query(1, 1, n, l, r));
            } else {
                int l = readint(), r = readint(), x = readint();
                update(1, 1, n, l, r, x);
            }
        }
    }
    return 0;
}