#include <stdio.h>
#include <string.h>

#define MAXN 200005
#define LOG 20
#define INF 2000000000  // 大于1e9的哨兵值
#define max(a,b) ((a) > (b) ? (a) : (b))
#define min(a,b) ((a) < (b) ? (a) : (b))

int A[MAXN], B[MAXN];
int pre0[MAXN];       // A中0的前缀和
int log_table[MAXN];

// A的ST表：最大正数、最小正数、最大负数、最小负数
int max_pos[LOG][MAXN];
int min_pos[LOG][MAXN];
int max_neg[LOG][MAXN];
int min_neg[LOG][MAXN];

// B的ST表：最大值、最小值
int max_b[LOG][MAXN];
int min_b[LOG][MAXN];

// 预处理log表
void init_log() {
    log_table[1] = 0;
    for (int i = 2; i < MAXN; i++) {
        log_table[i] = log_table[i / 2] + 1;
    }
}

// 构建A的ST表
void build_A(int n) {
    for (int i = 1; i <= n; i++) {
        if (A[i] > 0) {
            max_pos[0][i] = A[i];
            min_pos[0][i] = A[i];
            max_neg[0][i] = -INF;
            min_neg[0][i] = INF;
        } else if (A[i] < 0) {
            max_pos[0][i] = -INF;
            min_pos[0][i] = INF;
            max_neg[0][i] = A[i];
            min_neg[0][i] = A[i];
        } else {
            max_pos[0][i] = -INF;
            min_pos[0][i] = INF;
            max_neg[0][i] = -INF;
            min_neg[0][i] = INF;
        }
    }
    for (int k = 1; k < LOG; k++) {
        for (int i = 1; i + (1 << k) - 1 <= n; i++) {
            int mid = i + (1 << (k - 1));
            max_pos[k][i] = max(max_pos[k-1][i], max_pos[k-1][mid]);
            min_pos[k][i] = min(min_pos[k-1][i], min_pos[k-1][mid]);
            max_neg[k][i] = max(max_neg[k-1][i], max_neg[k-1][mid]);
            min_neg[k][i] = min(min_neg[k-1][i], min_neg[k-1][mid]);
        }
    }
}

// 查询A区间[l,r]的四个极值
void query_A(int l, int r, int *mp, int *mip, int *mn, int *minn) {
    int len = r - l + 1;
    int k = log_table[len];
    int right = r - (1 << k) + 1;
    *mp = max(max_pos[k][l], max_pos[k][right]);
    *mip = min(min_pos[k][l], min_pos[k][right]);
    *mn = max(max_neg[k][l], max_neg[k][right]);
    *minn = min(min_neg[k][l], min_neg[k][right]);
}

// 构建B的ST表
void build_B(int m) {
    for (int i = 1; i <= m; i++) {
        max_b[0][i] = B[i];
        min_b[0][i] = B[i];
    }
    for (int k = 1; k < LOG; k++) {
        for (int i = 1; i + (1 << k) - 1 <= m; i++) {
            int mid = i + (1 << (k - 1));
            max_b[k][i] = max(max_b[k-1][i], max_b[k-1][mid]);
            min_b[k][i] = min(min_b[k-1][i], min_b[k-1][mid]);
        }
    }
}

// 查询B区间[l,r]的最大值和最小值
void query_B(int l, int r, int *mb, int *mib) {
    int len = r - l + 1;
    int k = log_table[len];
    int right = r - (1 << k) + 1;
    *mb = max(max_b[k][l], max_b[k][right]);
    *mib = min(min_b[k][l], min_b[k][right]);
}

int main() {
    init_log();
    int n, m, q;
    scanf("%d%d%d", &n, &m, &q);
    
    for (int i = 1; i <= n; i++) {
        scanf("%d", &A[i]);
        pre0[i] = pre0[i-1] + (A[i] == 0 ? 1 : 0);
    }
    for (int i = 1; i <= m; i++) {
        scanf("%d", &B[i]);
    }
    
    build_A(n);
    build_B(m);
    
    while (q--) {
        int l1, r1, l2, r2;
        scanf("%d%d%d%d", &l1, &r1, &l2, &r2);
        
        int maxb, minb;
        query_B(l2, r2, &maxb, &minb);
        
        int maxp, minp, maxn, minn;
        query_A(l1, r1, &maxp, &minp, &maxn, &minn);
        
        long long ans = -1000000000000000000LL; // -1e18
        
        // 正数候选：最大正数*minB、最小正数*minB
        if (maxp > 0) {
            ans = max(ans, (long long)maxp * minb);
            ans = max(ans, (long long)minp * minb);
        }
        // 负数候选：最大负数*maxB、最小负数*maxB
        if (minn < 0) {
            ans = max(ans, (long long)maxn * maxb);
            ans = max(ans, (long long)minn * maxb);
        }
        // 0候选
        if (pre0[r1] - pre0[l1-1] > 0) {
            ans = max(ans, 0LL);
        }
        
        printf("%lld\n", ans);
    }
    
    return 0;
}