#include <stdio.h>
#include <stdlib.h>
#define maxn 50004
typedef long long ll;
typedef struct{
    long long w,l;
}Land;
Land land[maxn],new[maxn];
ll dp[maxn];
int cmp(const void*a,const void * b){
    Land *a1 =(Land*)a;
    Land *b1=(Land*)b;
    if(a1->w!=b1->w){
        return a1->w < b1->w?-1:1;
    }
    return a1->l<b1->l?-1:1;
}
ll min(ll a,ll b){
    return a>b?b:a;
}
int N;
int main(){
    scanf("%d",&N);
    for(int i=1;i<=N;i++){
        scanf("%lld%lld",&land[i].w,&land[i].l);
    }
    qsort(land+1,N,sizeof(Land),cmp);
    int m=0;
    for(int i=N;i>0;i--){
        if(land[i].l>new[m].l){
            new[++m]=land[i];
        }
    }
    dp[0]=0;
     // 反转，使 w 递增，l 递减
    for (int i = 1; i <= m / 2; i++) {
        Land t = new[i];
        new[i] = new[m - i + 1];
        new[m - i + 1] = t;
    }

    for (int i = 1; i <= m; i++) {
        dp[i] = new[i].w * new[1].l;

        for (int j = 1; j <= i; j++) {
            ll cost = dp[j - 1] + new[i].w * new[j].l;
            dp[i] = min(dp[i], cost);
        }
    }

    printf("%lld\n", dp[m]);
    return 0;
}//1 15 20 100  
//100 15 5 1      