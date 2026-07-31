#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXN 2000006

int n, m;
int bit[MAXN];  // 树状数组
int ans[MAXN];

typedef struct {
    int val, idx;
} Element;

typedef struct {
    int l, r, x, id;
} Query;

Element elems[MAXN];
Query queries[MAXN];

int cmp_elem(const void *a, const void *b) {
    return ((Element *)a)->val - ((Element *)b)->val;
}

int cmp_query(const void *a, const void *b) {
    return ((Query *)a)->x - ((Query *)b)->x;
}

void update(int i) {
    for (; i <= n; i += i & (-i))
        bit[i]++;
}

int prefix(int i) {
    int s = 0;
    for (; i > 0; i -= i & (-i))
        s += bit[i];
    return s;
}

int main() {
    scanf("%d%d", &n, &m);

    for (int i = 1; i <= n; i++) {
        scanf("%d", &elems[i].val);
        elems[i].idx = i;
    }

    for (int i = 0; i < m; i++) {
        scanf("%d%d%d", &queries[i].l, &queries[i].r, &queries[i].x);
        queries[i].id = i;
    }

    qsort(elems + 1, n, sizeof(Element), cmp_elem);
    qsort(queries, m, sizeof(Query), cmp_query);

    int j = 1;  // 指向 elems 的指针
    for (int i = 0; i < m; i++) {
        // 把所有值 <= queries[i].x 的元素插入树状数组
        while (j <= n && elems[j].val <= queries[i].x) {
            update(elems[j].idx);
            j++;
        }
        ans[queries[i].id] = prefix(queries[i].r) - prefix(queries[i].l - 1);
    }

    for (int i = 0; i < m; i++) {
        printf("%d\n", ans[i]);
    }

    return 0;
}
