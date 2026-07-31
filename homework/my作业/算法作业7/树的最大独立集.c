#include <stdio.h>
#include <string.h>
#define MAXN 100005   // 最大结点数
// 邻接表存树
int head[MAXN];
int to[2 * MAXN];       // 边的终点
int nxt[2 * MAXN];      // 下一条边的编号
int idx = 0;          // 边计数器
int w[MAXN];    // 每个结点的利润
int dp[MAXN][2]; // dp[u][0], dp[u][1]
int N;
// 添加一条无向边 u - v
void add_edge(int u, int v) {
    to[idx] = v;
    nxt[idx] = head[u];
    head[u] = idx;
    idx++;
}
void dfs(int u, int parent) {
    // 初始化：如果选 u，至少得到自己的利润；不选 u，初始为 0
    dp[u][1] = w[u];
    dp[u][0] = 0;
    // 遍历所有邻居 v
    for (int e = head[u]; e != -1; e = nxt[e]) {
        int v = to[e];
        if (v == parent) continue; // 防止走回去
        dfs(v, u); // 先计算子树 v 的 dp
        // 不选 u
        if (dp[v][0] > dp[v][1])
            dp[u][0] += dp[v][0];
        else
            dp[u][0] += dp[v][1];
        // 选 u
        dp[u][1] += dp[v][0];
    }
}
int main() {
    // 初始化 head 数组为 -1
    memset(head, -1, sizeof(head));
    printf("请输入结点个数：");
    scanf("%d", &N);
    printf("请按顺序输入结点利润：");
    for (int i = 1; i <= N; i++) {
        scanf("%d", &w[i]);   // 利润，可以都输 1 表示“利润相同”
    }
    printf("请输入边：\n");
    for (int i = 0; i < N - 1; i++) {
        int u, v;
        scanf("%d %d", &u, &v);
        add_edge(u, v);
        add_edge(v, u);
    }
    // 以 1 号结点为根做 DFS
    dfs(1, 0);
    int ans = dp[1][0] > dp[1][1] ? dp[1][0] : dp[1][1];
    printf("最大利润：d\n", ans);
    return 0;
}
