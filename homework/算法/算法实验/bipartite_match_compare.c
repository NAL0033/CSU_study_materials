#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#if defined(_WIN32)
#include <windows.h>
static double now_seconds(void) {
    LARGE_INTEGER freq, counter;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&counter);
    return (double)counter.QuadPart / (double)freq.QuadPart;
}
#else
static double now_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}
#endif

typedef struct {
    int n;
    int m;
    int *head;
    int *to;
    int *next;
    int idx;
} BiGraph;

static uint64_t rng_next(uint64_t *s) {
    uint64_t x = *s;
    x ^= x << 7;
    x ^= x >> 9;
    *s = x;
    return x;
}

static void die_if(int cond, const char *msg) {
    if (cond) {
        fprintf(stderr, "%s\n", msg);
        exit(EXIT_FAILURE);
    }
}

static BiGraph *create_bigraph(int n, int avg_degree, uint64_t seed) {
    long long max_edges_ll = 1LL * n * avg_degree;
    die_if(max_edges_ll > 2147480000LL, "too many edges");

    int max_edges = (int)max_edges_ll;
    BiGraph *g = (BiGraph *)calloc(1, sizeof(BiGraph));
    die_if(!g, "malloc graph failed");

    g->n = n;
    g->m = max_edges;
    g->idx = 0;
    g->head = (int *)malloc(sizeof(int) * n);
    g->to = (int *)malloc(sizeof(int) * max_edges);
    g->next = (int *)malloc(sizeof(int) * max_edges);

    die_if(!g->head || !g->to || !g->next, "malloc bigraph arrays failed");

    for (int i = 0; i < n; ++i) {
        g->head[i] = -1;
    }

    uint64_t state = seed ? seed : 88172645463393265ULL;

    for (int u = 0; u < n; ++u) {
        for (int k = 0; k < avg_degree; ++k) {
            int v = (int)(rng_next(&state) % (uint64_t)n);
            int id = g->idx++;
            g->to[id] = v;
            g->next[id] = g->head[u];
            g->head[u] = id;
        }
    }

    return g;
}

static void free_bigraph(BiGraph *g) {
    if (!g) return;
    free(g->head);
    free(g->to);
    free(g->next);
    free(g);
}

/* 算法1：匈牙利算法，也称 Kuhn 增广路算法 */
static int kuhn_dfs(const BiGraph *g, int u, int *match_right, int *vis, int stamp) {
    for (int e = g->head[u]; e != -1; e = g->next[e]) {
        int v = g->to[e];

        if (vis[v] == stamp) {
            continue;
        }

        vis[v] = stamp;

        if (match_right[v] == -1 ||
            kuhn_dfs(g, match_right[v], match_right, vis, stamp)) {
            match_right[v] = u;
            return 1;
        }
    }

    return 0;
}

static int hungarian_kuhn(const BiGraph *g) {
    int n = g->n;
    int *match_right = (int *)malloc(sizeof(int) * n);
    int *vis = (int *)calloc(n, sizeof(int));

    die_if(!match_right || !vis, "malloc hungarian arrays failed");

    for (int i = 0; i < n; ++i) {
        match_right[i] = -1;
    }

    int ans = 0;

    for (int u = 0; u < n; ++u) {
        if (kuhn_dfs(g, u, match_right, vis, u + 1)) {
            ++ans;
        }
    }

    free(match_right);
    free(vis);

    return ans;
}

/* 算法2：最大流方法，这里使用 Dinic 算法 */
typedef struct {
    int to;
    int cap;
    int next;
} FEdge;

typedef struct {
    int N;
    int S;
    int T;
    int *head;
    int *level;
    int *cur;
    int *q;
    FEdge *edges;
    int idx;
    int max_edges;
} FlowGraph;

static FlowGraph *create_flowgraph(int n_vertices, int max_directed_edges) {
    FlowGraph *f = (FlowGraph *)calloc(1, sizeof(FlowGraph));
    die_if(!f, "malloc flowgraph failed");

    f->N = n_vertices;
    f->max_edges = max_directed_edges;
    f->idx = 0;

    f->head = (int *)malloc(sizeof(int) * n_vertices);
    f->level = (int *)malloc(sizeof(int) * n_vertices);
    f->cur = (int *)malloc(sizeof(int) * n_vertices);
    f->q = (int *)malloc(sizeof(int) * n_vertices);
    f->edges = (FEdge *)malloc(sizeof(FEdge) * max_directed_edges);

    die_if(!f->head || !f->level || !f->cur || !f->q || !f->edges,
           "malloc flow arrays failed");

    for (int i = 0; i < n_vertices; ++i) {
        f->head[i] = -1;
    }

    return f;
}

static void flow_add_edge(FlowGraph *f, int u, int v, int c) {
    die_if(f->idx + 2 > f->max_edges, "flow edge buffer overflow");

    f->edges[f->idx] = (FEdge){v, c, f->head[u]};
    f->head[u] = f->idx++;

    f->edges[f->idx] = (FEdge){u, 0, f->head[v]};
    f->head[v] = f->idx++;
}

static void free_flowgraph(FlowGraph *f) {
    if (!f) return;
    free(f->head);
    free(f->level);
    free(f->cur);
    free(f->q);
    free(f->edges);
    free(f);
}

static int dinic_bfs(FlowGraph *f) {
    for (int i = 0; i < f->N; ++i) {
        f->level[i] = -1;
    }

    int front = 0, back = 0;
    f->level[f->S] = 0;
    f->q[back++] = f->S;

    while (front < back) {
        int u = f->q[front++];

        for (int e = f->head[u]; e != -1; e = f->edges[e].next) {
            int v = f->edges[e].to;

            if (f->edges[e].cap > 0 && f->level[v] < 0) {
                f->level[v] = f->level[u] + 1;

                if (v == f->T) {
                    return 1;
                }

                f->q[back++] = v;
            }
        }
    }

    return f->level[f->T] >= 0;
}

static int dinic_dfs(FlowGraph *f, int u, int pushed) {
    if (u == f->T || pushed == 0) {
        return pushed;
    }

    for (int *pe = &f->cur[u]; *pe != -1; *pe = f->edges[*pe].next) {
        int e = *pe;
        int v = f->edges[e].to;

        if (f->edges[e].cap > 0 && f->level[v] == f->level[u] + 1) {
            int tr = dinic_dfs(
                f,
                v,
                pushed < f->edges[e].cap ? pushed : f->edges[e].cap
            );

            if (tr > 0) {
                f->edges[e].cap -= tr;
                f->edges[e ^ 1].cap += tr;
                return tr;
            }
        }
    }

    return 0;
}

static int dinic_maxflow_from_bigraph(const BiGraph *g) {
    int n = g->n;
    int N = 2 * n + 2;
    int S = 2 * n;
    int T = 2 * n + 1;

    long long forward_edges = 1LL * n + g->m + n;
    long long directed_edges_ll = forward_edges * 2;

    die_if(directed_edges_ll > 2147480000LL, "too many flow edges");

    FlowGraph *f = create_flowgraph(N, (int)directed_edges_ll);

    f->S = S;
    f->T = T;

    for (int u = 0; u < n; ++u) {
        flow_add_edge(f, S, u, 1);
    }

    for (int u = 0; u < n; ++u) {
        for (int e = g->head[u]; e != -1; e = g->next[e]) {
            int v = g->to[e];
            flow_add_edge(f, u, n + v, 1);
        }
    }

    for (int v = 0; v < n; ++v) {
        flow_add_edge(f, n + v, T, 1);
    }

    int flow = 0;

    while (dinic_bfs(f)) {
        memcpy(f->cur, f->head, sizeof(int) * f->N);

        int pushed;
        while ((pushed = dinic_dfs(f, f->S, 1000000000)) > 0) {
            flow += pushed;
        }
    }

    free_flowgraph(f);

    return flow;
}

int main(int argc, char **argv) {
    int avg_degree = 20;
    uint64_t base_seed = 20260612ULL;

    if (argc >= 2) {
        avg_degree = atoi(argv[1]);
    }

    if (argc >= 3) {
        base_seed = (uint64_t)strtoull(argv[2], NULL, 10);
    }

    if (avg_degree <= 0) {
        avg_degree = 20;
    }

    int sizes[3] = {1000, 5000, 10000};

    printf("n_left,n_right,avg_degree,edges,hungarian_matching,hungarian_seconds,dinic_matching,dinic_seconds,check\n");

    for (int i = 0; i < 3; ++i) {
        int n = sizes[i];
        uint64_t seed = base_seed + (uint64_t)n * 1000003ULL + (uint64_t)avg_degree;

        BiGraph *g = create_bigraph(n, avg_degree, seed);

        double t1 = now_seconds();
        int m1 = hungarian_kuhn(g);
        double t2 = now_seconds();

        double t3 = now_seconds();
        int m2 = dinic_maxflow_from_bigraph(g);
        double t4 = now_seconds();

        printf("%d,%d,%d,%d,%d,%.6f,%d,%.6f,%s\n",
               n,
               n,
               avg_degree,
               g->m,
               m1,
               t2 - t1,
               m2,
               t4 - t3,
               m1 == m2 ? "OK" : "DIFF");

        fflush(stdout);
        free_bigraph(g);
    }

    return 0;
}