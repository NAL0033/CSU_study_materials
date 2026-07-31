#include <stdio.h>
#include <stdlib.h>

#define maxn 100005
typedef long long ll;

int N;
ll L, R;
ll tree[4*maxn];

int lowbit(int x){
    return x & -x;
}

void add(int x, int v){
    while(x <= N){
        tree[x] += v;
        x += lowbit(x);
    }
}

ll sum(int x){
    ll res = 0;
    while(x > 0){
        res += tree[x];
        x -= lowbit(x);
    }
    return res;
}

// Calculate range sum from L to R (inclusive)
ll range_sum(ll l, ll r){
    return sum(r) - sum(l - 1);
}

int main(){
    scanf("%d%lld%lld", &N, &L, &R);
    for(int i = 1; i <= N; i++){
        int num;
        scanf("%d", &num);
        add(i, num);
    }

    ll result = range_sum(L, R);
    printf("%lld\n", result);
    return 0;
}