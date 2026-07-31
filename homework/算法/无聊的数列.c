#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define maxn 100005

typedef long long ll;

int n, m;
ll arr[maxn];
ll tree1[maxn * 4];
ll tree2[maxn * 4];

int lowbit(int x) {
    return x & -x;
}

int update(ll type[], int pos, ll k) // pos表示修改点的位置，k表示修改的值
{
    for (int i = pos; i <= n; i += lowbit(i)) {
        type[i] += k;
    }
    return 0;
}

ll query(ll type[], int pos) {
    ll ans = 0;
    for (int i = pos; i > 0; i -= lowbit(i)) {
        ans += type[i];
    }
    return ans;
}

int main() {
    scanf("%d%d", &n, &m);

    memset(tree1, 0, sizeof(tree1));
    memset(tree2, 0, sizeof(tree2));

    for (int i = 1; i <= n; i++) {
        scanf("%lld", &arr[i]);
    }

    while (m--) {
        int op;
        scanf("%d", &op);

        if (op == 1) {
            int l, r;
            ll K, D;
            scanf("%d%d%lld%lld", &l, &r, &K, &D);

            ll k = K - (ll)l * D;

            update(tree1, l, k);
            update(tree1, r + 1, -k);

            update(tree2, l, D);
            update(tree2, r + 1, -D);
        } else {
            int p;
            scanf("%d", &p);

            ll ans = arr[p] + (ll)p * query(tree2, p) + query(tree1, p);
            printf("%lld\n", ans);
        }
    }

    return 0;
}
