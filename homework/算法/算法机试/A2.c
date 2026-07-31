#include <stdio.h>

#define MAXN 805
#define MAXH 330
#define MOD 998244353

int c[MAXH];
int sum[MAXH];

/* 邻接表 */
int head[MAXN];
int to[MAXN * 5];
int next[MAXN * 5];

int cnt = 0;

long long dp1[MAXN];
long long dp2[MAXN];


/* 加边 */
void addEdge(int u, int v)
{
    to[cnt] = v;
    next[cnt] = head[u];
    head[u] = cnt;
    cnt++;
}


int main()
{
    int h, m, id;

    scanf("%d %d %d", &h, &m, &id);


    // 统计每层房间编号范围
    sum[0] = 0;

    for (int i = 1; i <= h; i++)
    {
        scanf("%d", &c[i]);
        sum[i] = sum[i-1] + c[i];
    }


    // 初始化邻接表
    for (int i = 0; i < MAXN; i++)
        head[i] = -1;


    // 输入通道
    for (int i = 0; i < m; i++)
    {
        int u, v;

        scanf("%d %d", &u, &v);

        addEdge(u, v);
    }


    int n = sum[h];


    /*
        第一遍DP:
        第1层 -> 每个点
    */


    // 第一层房间全部有一种起点方案
    for (int i = 1; i <= c[1]; i++)
    {
        dp1[i] = 1;
    }


    // 按编号从小到大转移
    for (int u = 1; u <= n; u++)
    {
        for (int e = head[u]; e != -1; e = next[e])
        {
            int v = to[e];
            dp1[v] += dp1[u];

            if (dp1[v] >= MOD)
                dp1[v] %= MOD;
        }
    }



    /*
        第二遍DP:
        每个点 -> 第h层
    */


    // 最后一层到终点的方法数为1
    for (int i = sum[h-1] + 1; i <= sum[h]; i++)
    {
        dp2[i] = 1;
    }


    // 因为只能向高层走
    // 所以编号大的先处理
    for (int u = n; u >= 1; u--)
    {
        for (int e = head[u]; e != -1; e = next[e])
        {
            int v = to[e];

            dp2[u] += dp2[v];

            if (dp2[u] >= MOD)
                dp2[u] %= MOD;
        }
    }



    long long ans;

    ans = (dp1[id] * dp2[id]) % MOD;


    printf("%lld\n", ans);


    return 0;
}