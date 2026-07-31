#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define maxn 200005
int ans=1e9;
int n;
int to[maxn];
int flag[maxn];
int num[maxn];
int idx=0;

void dfs(int x){
    flag[x]=1;
    int v=to[x];
    if(flag[v]==0){
        num[v]=num[x]+1;
        dfs(v);
    }
    else if(flag[v]==1){
        int len=num[x]-num[v]+1;
        if(len<ans)ans=len;
    }
    flag[x]=2;
}
int main(){
    scanf("%d",&n);
    memset(flag,0,sizeof(flag));
    memset(num,0,sizeof(num));
    for(int i=1;i<=n;i++){
        scanf("%d",&to[i]);
    }
    for(int i=1;i<=n;i++){
        if(flag[i]==0){
            num[i]=1;
            dfs(i);
        }
    }
    printf("%d",ans);
}
