#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAXN 5005
#define MAXM 50005
#define INF 0x3f3f3f3f3f3f3f3fLL
typedef long long ll;
typedef struct {
    int to, next;
    ll cap, cost;
} Edge;
Edge edges[MAXM * 2 + 5];
int head[MAXN];
int idx;
int n, m, s, t;
ll dis[MAXN];
ll h[MAXN];
int pre[MAXN];
int pree[MAXN];
typedef struct {
    ll dist;
    int node;
} HeapNode;
HeapNode heap[MAXM * 10];
int heap_size;
void swap(HeapNode *a, HeapNode *b) {
    HeapNode tmp = *a;
    *a = *b;
    *b = tmp;
}
void push(ll dist, int node) {
    heap[++heap_size].dist = dist;
    heap[heap_size].node = node;

    int u = heap_size;

    while (u > 1) {
        int fa = u >> 1;
        if (heap[fa].dist <= heap[u].dist)
            break;
        swap(&heap[fa], &heap[u]);
        u = fa;
    }
}

HeapNode pop() {
    HeapNode res = heap[1];
    heap[1] = heap[heap_size--];
    int u = 1;
    while (1) {
        int l = u << 1;
        int r = l + 1;
        int smallest = u;

        if (l <= heap_size &&
            heap[l].dist < heap[smallest].dist)
            smallest = l;

        if (r <= heap_size &&
            heap[r].dist < heap[smallest].dist)
            smallest = r;

        if (smallest == u)
            break;

        swap(&heap[u], &heap[smallest]);

        u = smallest;
    }
    return res;
}

void add_edge(int u, int v, ll cap, ll cost) {
    edges[idx].to = v;
    edges[idx].cap = cap;
    edges[idx].cost = cost;
    edges[idx].next = head[u];
    head[u] = idx++;

    edges[idx].to = u;
    edges[idx].cap = 0;
    edges[idx].cost = -cost;
    edges[idx].next = head[v];
    head[v] = idx++;
}

int dijkstra() {
    static int vis[MAXN];
    for (int i = 1; i <= n; i++) {
        dis[i] = INF;
        vis[i] = 0;
    }
    dis[s] = 0;
    heap_size = 0;
    push(0, s);
    while (heap_size) {
        HeapNode cur = pop();
        int u = cur.node;
        if (vis[u])
            continue;
        vis[u] = 1;
        for (int i = head[u]; i != -1; i = edges[i].next) {
            if (edges[i].cap <= 0)
                continue;
            int v = edges[i].to;
            ll w = edges[i].cost + h[u] - h[v];
            if (dis[v] > dis[u] + w) {
                dis[v] = dis[u] + w;
                pre[v] = u;
                pree[v] = i;
                push(dis[v], v);
            }
        }
    }
    return dis[t] != INF;
}

void mcmf(ll *maxflow, ll *mincost) {
    *maxflow = 0;
    *mincost = 0;
    memset(h, 0, sizeof(h));
    while (dijkstra()) {
        for (int i = 1; i <= n; i++) {
            if (dis[i] < INF)
                h[i] += dis[i];
        }
        ll flow = INF;
        for (int u = t; u != s; u = pre[u]) {
            if (flow > edges[pree[u]].cap)
                flow = edges[pree[u]].cap;
        }
        *maxflow += flow;
        *mincost += flow * h[t];
        for (int u = t; u != s; u = pre[u]) {
            edges[pree[u]].cap -= flow;
            edges[pree[u] ^ 1].cap += flow;
        }
    }
}

int main() {
    memset(head, -1, sizeof(head));
    idx = 0;
    scanf("%d%d%d%d", &n, &m, &s, &t);
    while (m--) {
        int u, v;
        ll w, c;
        scanf("%d%d%lld%lld", &u, &v, &w, &c);
        add_edge(u, v, w, c);
    }
    ll maxflow, mincost;
    mcmf(&maxflow, &mincost);
    printf("%lld %lld\n", maxflow, mincost);

    return 0;
}
