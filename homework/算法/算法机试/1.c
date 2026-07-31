#include <stdio.h>
#include <stdlib.h>
#define MAXN 100005
long long a[MAXN];

int n,m;
int main(){
    scanf("%d",&n);
    for(int i=1;i<=n;i++){
        scanf("%lld",&a[i]);
    }
    scanf("%d",&m);
    while(m--){
        int op,l,r,x;
        scanf("%d %d %d",&op,&l,&r);
        if(op==2){
            scanf("%d",&x);
            for(int i=l;i<=r;i++){
                a[i]^=x;
            }
        }
        else{
            long long ans=0;
            for(int i=l;i<=r;i++){
                ans+=a[i];
            }
            printf("%lld\n",ans);
        }
    }
    return 0;
}
