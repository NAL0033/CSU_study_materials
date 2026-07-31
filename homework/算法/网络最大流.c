#include <stdio.h>
#include <string.h>

#define MAXN 205
#define MAXM 5005
#define INF 1000000000000000000LL  // 1e18，避免溢出

typedef struct {
    long long val;  // 关键修改：容量可能超int范围
    int to;
    int next;
} Edge;

int head[MAXN], cur[MAXN], d[MAXN];
Edge edges[MAXM*2];
int q[MAXN*MAXN];
int n, m, s, t;
int idx = 0;

void add_edge(int a, int b, long long w) {  // 关键修改：参数w改为long long
    edges[idx].val = w;
    edges[idx].to = b;
    edges[idx].next = head[a];
    head[a] = idx++;
    
    edges[idx].val = 0;
    edges[idx].to = a;
    edges[idx].next = head[b];
    head[b] = idx++;
}

int bfs() {
    memset(d, 0, sizeof(d));
    int l = 0, r = 0;
    q[r++] = s;
    d[s] = 1;
    for(int i = 1; i <= n; i++) cur[i] = head[i];

    while(l < r) {
        int u = q[l++];
        for(int i = head[u]; i != -1; i = edges[i].next) {
            int v = edges[i].to;
            if(d[v] == 0 && edges[i].val > 0) {
                d[v] = d[u] + 1;
                q[r++] = v;
            }
        }
    }
    return d[t] != 0;
}

long long dfs(int u, long long flow) {  // 关键修改：参数和返回值改为long long
    if(u == t) return flow;
    for(int i = cur[u]; i != -1; i = edges[i].next) {
        cur[u] = i;
        int v = edges[i].to;
        if(d[v] == d[u]+1 && edges[i].val > 0) {
            long long minflow = dfs(v, flow < edges[i].val ? flow : edges[i].val);
            if(minflow > 0) {
                edges[i].val -= minflow;
                edges[i^1].val += minflow;
                return minflow;
            }
        }
    }
    return 0;
}

long long dinic() {  // 关键修改：返回值改为long long
    long long maxflow = 0, flow;
    while(bfs()) {
        while((flow = dfs(s, INF)) > 0) {
            maxflow += flow;
        }
    }
    return maxflow;
}

int main() {
    scanf("%d%d%d%d", &n, &m, &s, &t);
    memset(head, -1, sizeof(head));
    idx = 0;
    for(int i = 0; i < m; i++) {
        int u, v;
        long long w;  // 关键修改：w改为long long
        scanf("%d%d%lld", &u, &v, &w);  // %lld读取long long
        add_edge(u, v, w);
    }
    printf("%lld\n", dinic());  // %lld输出long long
    return 0;
}
