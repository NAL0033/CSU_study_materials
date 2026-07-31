#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define maxm 200005
#define maxn 400005

int edge_u[2*maxm];
int edge_v[2*maxm];
int head[maxn];
int edgeto[2*maxm];
int next[2*maxm];
int idx=0;
int dead[maxn];
int atack[maxn];
int com[maxn];
int parent[maxn];
void add_edge(int a,int b){
	next[idx]=head[a];
	edgeto[idx]=b;
	head[a]=idx++;
}

int find(int a){
	if(a!=parent[a]){
		a=find(parent[a]);
	}
	return parent[a];
} 
void merge(int a,int b){
	int roota=find(a);
	int rootb=find(b);
	if(roota!=rootb){
		parent[rootb]=roota;
	}
}
int main(){
	int n,m;
	memset(head,-1,sizeof(head));
	scanf("%d %d",&n,&m);
	for(int i=0;i<n;i++){
		parent[i]=i;
	}
	for(int i=0;i<m;i++){
		int x,y;
		scanf("%d %d",&x,&y);
		edge_u[i]=x;
		edge_v[i]=y;
        add_edge(x,y);
        add_edge(y,x); 
    }
	int k;
	scanf("%d",&k);
	for(int i=0;i<k;i++){
		int planet;
		scanf("%d",&planet);
		atack[i]=planet;
		dead[planet]=1;
	}
	int cnt=0;
	for(int i=0;i<m;i++){
		int u=edge_u[i];
		int v=edge_v[i];
		if(!dead[u]&&!dead[v]){
			merge(u,v);
		}
	}
	for(int i=0;i<n;i++){
		if(!dead[i]&&i==find(i)){
			cnt++;
		}
	}
	com[k]=cnt;
	for(int i=k-1;i>=0;i--){
		int planet=atack[i];
		dead[planet]=0;
		cnt++;
		//printf("cnt:%d",cnt);
		for(int j=head[planet];j!=-1;j=next[j]){
			int nei=edgeto[j];
			if(!dead[nei]&&find(planet)!=find(nei)){
				merge(nei,planet);
				cnt--;
			}
		}
		com[i]=cnt;
	}
	for(int i=0;i<=k;i++){
		printf("%d\n",com[i]);
	}
	//printf("%d",cmp);
}
