#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define maxn 305
#define maxm 305

int head[maxn],to[maxn],next[maxn];//µ¥Ïò±ß
int dp[maxn][maxm];

int idx=0;
int N,M;
void add_edge(int a,int b){
    to[idx]=b;
    next[idx]=head[a];
    head[a]=idx++;
}
int size[maxn];
int val[maxn];
int max(int a,int b){
    return a>b?a:b;
}
void dfs(int u){
    dp[u][1]=val[u];
    size[u]=1;
    
    for(int i=head[u];i!=-1;i=next[i]){
        int v=to[i];
        dfs(v);
        
        for(int j=size[u];j>=1;j--){
            for(int k=1;k<=size[v];k++){
                if(j+k<=M+1){
                   dp[u][j+k]=max(dp[u][j+k],dp[u][j]+dp[v][k]);
                }
            }
        }
        size[u]+=size[v];
    }
}
int main(){
    scanf("%d%d",&N,&M);
    
    memset(head,-1,sizeof(head));
    memset(dp, 0, sizeof(dp));
    
    for(int i=1;i<=N;i++){
        int k,s;
        scanf("%d %d",&k,&val[i]);
        add_edge(k,i);
    }
    val[0]=0;
    dfs(0);
    printf("%d",dp[0][M+1]);
    return 0;
}
