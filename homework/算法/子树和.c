#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define  maxn 16005
int head[maxn];
int values[maxn];
int edge[2*maxn];
int next[2*maxn];
int idx=0;
int max_sum;
int dp[maxn];

void add_edge(int a,int b){
	edge[idx]=b;
	next[idx]=head[a];
	head[a]=idx++;
}
void dfs(int u,int parent){
	dp[u]=values[u];
	for(int i=head[u];i!=-1;i=next[i]){
		int v=edge[i];
		if(v!=parent){
			dfs(v,u);
			if(dp[v]>0){
				dp[u]+=dp[v];
			}
		}
	}
	if(dp[u]>max_sum){
		max_sum=dp[u];
	}
}
int main(){
	int n;
	scanf("%d",&n);
	for(int i=1;i<=n;i++){
		scanf("%d",&values[i]);
	}
	max_sum = -1e18;
	memset(head,-1,sizeof(head));
	for(int i=0;i<n-1;i++){
		int a,b;
		scanf("%d %d",&a,&b);
		add_edge(a,b);
		add_edge(b,a);
	}
	dfs(1,-1);
	printf("%d",max_sum);
}
